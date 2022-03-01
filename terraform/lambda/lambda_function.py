import boto3
import os
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

print('Loading function')

client = boto3.client('autoscaling')

region = os.environ['AWS_REGION']
MinHealthyPercentage = os.environ['MinHealthyPercentage']
AutoScalingGroupName = os.environ['AutoScalingGroupName']

def lambda_handler(event, context):
    logger.info("Start refresh")
    try:
        response = client.start_instance_refresh(
            AutoScalingGroupName=AutoScalingGroupName,
            Strategy='Rolling',
            Preferences={
                'MinHealthyPercentage': int(MinHealthyPercentage)
            }
        )
        logger.info("Refresh done")
        logger.info(response)
        return response
    except Exception as e:
        print(e)
        raise e
