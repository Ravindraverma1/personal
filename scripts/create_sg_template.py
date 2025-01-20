import boto3 ,json, sys
sys.path.append("config")
from config_values import tf_variables


boto3.setup_default_session(profile_name="{0}".format(sys.argv[3]))

client = boto3.client('ec2', region_name="{0}".format(sys.argv[1]))
s3 = boto3.resource('s3')

sg_dict={}
for sg in client.describe_security_groups()['SecurityGroups']:
 sg_dict[sg['GroupId']]=[]
 for ip in sg['IpPermissions']:
  sg_dict[sg['GroupId']].append(ip)

s3.Object(sys.argv[2], '{}_SecurityGroup.json'.format(sys.argv[3])).put(Body=json.dumps(sg_dict))