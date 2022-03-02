terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "eu-central-1"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "worker"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_ssh_key" {
  filename        = "id_rsa.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-*-amd64-server-*"]
  }


  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }


  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "worker" {
  name_prefix            = "worker"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3a.micro"
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]
  user_data              = filebase64("${path.module}/data.sh")
}

resource "aws_autoscaling_group" "asg_worker" {
  name               = "worker_asg"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  desired_capacity   = 4
  max_size           = 4
  min_size           = 1

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.worker.id
        version            = "$Latest"
      }
      override {
        instance_type = "t3a.micro"
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ssh" {
  name = "ssh_worker"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy" "lambda_asg" {
  name        = "lambda_asg"
  path        = "/"
  description = "IAM policy for ASG from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "autoscaling:StartInstanceRefresh",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_asg" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_asg.arn
}

data "archive_file" "lambda_zip_file_int" {
  type        = "zip"
  output_path = "lambda_refresh.zip"
  source {
    content  = file("lambda/lambda_function.py")
    filename = "lambda_function.py"
  }
}


resource "aws_lambda_function" "refresh_lambda" {
  filename      = data.archive_file.lambda_zip_file_int.output_path
  function_name = "lambda_refresher"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip_file_int.output_base64sha256

  runtime = "python3.8"

  environment {
    variables = {
      AutoScalingGroupName = aws_autoscaling_group.asg_worker.name
      MinHealthyPercentage = 50
    }
  }
}

resource "aws_cloudwatch_event_rule" "refresh_asg" {
  name                = "RefreshASG"
  description         = "Refresh ASG"
  schedule_expression = "rate(30 minutes)"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_refresher" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.refresh_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.refresh_asg.arn
}

resource "aws_cloudwatch_event_target" "triger_refresh" {
  arn  = aws_lambda_function.refresh_lambda.arn
  rule = aws_cloudwatch_event_rule.refresh_asg.id
}


