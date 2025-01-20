import boto3
import sys

boto3.setup_default_session(profile_name="{0}".format(sys.argv[1]))

# We should ignore possible errors:
try:
    client = boto3.client('ec2', region_name="{0}".format(sys.argv[3]))
    response = client.terminate_instances(
        InstanceIds=["{0}".format(sys.argv[2])])
except Exception as e:
    print(e)
    pass
