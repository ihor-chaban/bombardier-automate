# bombardier-automate
Automation script for Docker image [alpine/bombardier](https://hub.docker.com/r/alpine/bombardier) for massive DDoS.

#### Features
- Cross-platform
- DDoS multiple targets simultaneously
- Centralized targets management with Google Drive
- Easy deployment to AWS with Terraform
- Automatic instances rotation for refreshing IP pool

#### Requirements
For standalone
- Python installed (`pip`)
- Docker installed

For AWS
- `aws-cli`
- `terraform`

## How to run the script standalone
If you just want to run the script locally on your laptop/PC you should install Python (v2 and v3 both are supported) with `pip` and Docker.
Depending on your OS the exact instructions may differ, so please use Google.
Once that is done, download and extract ZIP archive or clone this repository  
```$ git clone https://github.com/ihor-chaban/bombardier-automate.git```

Install necessary Python libs  
```$ pip install -r bombardier-automate/bombardier-automate/requirements.txt```

Now you just run the script, as usual, depending on your OS (from CLI or GUI)  
```
$ ./bombardier-automate.py
or
$ python bombardier-automate.py
```

Now the script will retrieve the list of targets and start creating Docker containers. You're good to go, just leave it and watch!

## How to deploy the solution to AWS
Cloud deployment is a preferable option, as it is MUCH more effective compared to a single device with a VPN.
If you are familiar with cloud services, this will be pretty easy and can be done in 5 minutes.
Install `aws-cli` and `terraform`. Go to `your AWS account - Security credentials - Access keys and Create New Access Key`.
Configure your `aws-cli` with these newly-created credentials. Test the access using command  
```$ aws sts get-caller-identity```

Once that is done, download and extract ZIP archive or clone this repository  
```$ git clone https://github.com/ihor-chaban/bombardier-automate.git```

Go to `terraform` folder and run  
```$ terraform init```

Then run  
```$ terraform apply```

And type `yes` when prompted for confirmation.
Watch the deployment process, everything will be set up automatically.
When the deployment is finished you may log in to some instance with newly-generated SSH key `id-rsa.pem` to inspect the result.
You’re good to go, just leave it and watch!

## Config
All the configuration is already set with optimal values, so you can just run the solution as-is. However, if you want to configure some parameters more granularly, below I will provide a short description for each.
#### The script configuration is located in `bombardier-automate/config.py`
**TARGETS** - Google Drive URL to retrieve DDoS targets from (default: `https://drive.google.com/file/d/1rmAAKd0zgNeQdd3u45xtlMQ3Bj_ad9FJ/view?usp=sharing`)  
**THREADS** - Number of threads to run in parallel. This will not affect the DDoS directly, it is just about the speed of checking targets liveness and creating Docker containers (default: `5`)  
**TIMEOUT** - How long to wait for the response from a target in seconds (default: `10`)  
**CONNECTIONS** - The number of concurrent connections per target (default: `100`)  
**DURATION** - How long the Docker container will attack the target in seconds. If the target is still alive, the container will be re-created again (default: `3600`)  
**PREFIX** - The prefix for Docker containers naming related to this script (default: `ddos_`)

#### Terraform configuration is located in `terraform/variables.tf`
**instance_type** - The type of EC2 instance to use (default: `t3a.micro`)  
**instance_count** - The number of instances to run simultaneously (default: `5`)  
**instance_lifetime** - How often the instances should be rotated (default: `30 minutes`)

## How to switch to your own targets list
The default URL hardcoded in this solution contains more than 300 targets and is being updated regularly by me, so it is ready for use as-is. However, if you want to use your own list to focus on the specific targets,  below I will provide a short instruction.
- Create any `.txt` file with the list of targets one per line:  
```
https://www.sberbank.ru/
...
https://government.ru/
```

- Upload it to your Google Drive and make it publicly **readable**.
- Copy the link `https://drive.google.com/file/d/1rmAAKd0zgNeQdd3u45xtlMQ3Bj_ad9FJ/view?usp=sharing` and paste it in `bombardier-automate/config.py` in **TARGETS** variable.

**IMPORTANT!!!**  
In order to modify the file in place on your Google Drive, use **Open With - Text Editor** app, the default Google Documents will not modify the .txt file, but will rather make a copy of it!

## Termination
#### Standalone
To stop the DDoS and remove everything related just stop the script then remove all related Docker containers. On \*NIX systems this can be done with the following command  
```$ for container in $(docker ps -a --format "{{.Names}}" | grep "^ddos_"); do docker rm -f "$container"; done```

#### AWS
Go to `terraform` folder and run  
```$ terraform destroy```
Type `yes` when prompted for confirmation.
All the resources created by this solution will be permanently destroyed. You may deploy them again just like for the first time.


## Targets
The actual targets and coordination info can be found here https://t.me/itarmyofukraine2022
