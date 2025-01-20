import boto3
import sys
import json
import time
import argparse
# TODO: better error checking.. :)


def route53_get_client(assume, role_arn, region):
    if assume is True:
        print("Assuming role {0} in region {1}...".format(role_arn, region))
        sts = boto3.client('sts', region_name=region)
        route53_role = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName="route53-role-assume",
            DurationSeconds=900
        )
        creds = route53_role['Credentials']
        client = boto3.client(
            'route53',
            region_name=region,
            aws_access_key_id=creds['AccessKeyId'],
            aws_secret_access_key=creds['SecretAccessKey'],
            aws_session_token=creds['SessionToken']
        )
    else:
        print("Not assuming a role")
        client = boto3.client('route53', region_name=region)

    return client


def create_cname(client, dns_zone_id, record, target):
    print("Adding CNAME record {0} to {1}".format(record, target))
    try:
        response = client.change_resource_record_sets(
            HostedZoneId=dns_zone_id,
            ChangeBatch={
                'Comment': 'ACM verification. Dont delete it - need for renewals.',
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record,
                            'Type': 'CNAME',
                            'TTL': 300,
                            'ResourceRecords': [{'Value': target}]
                        }
                    }
                ]
            }
        )
    except Exception as e:
        print(e)
        print("Failed to add CNAME record {0} to {1}".format(record, target))
        print("Env will not be fully functional. Run terraform destroy and try again")
        sys.exit(1)


def wait_until_all_verified(client, arn):
    result_table = {}

    def check():
        for _, status in list(result_table.items()):
            if status == "PENDING_VALIDATION":
                return False
        return True

    while True:
        print("waiting until certificate is validated by AWS....")

        response = client.describe_certificate(
            CertificateArn=arn
        )
        domains = response['Certificate']['DomainValidationOptions']

        for domain in domains:
            result_table[domain['DomainName']] = domain['ValidationStatus']

        if check() is True:
            break

        time.sleep(1)

    print(result_table)


def get_resource_records(client, arn):
    print("Obtaining list of CNAME records for validation")

    def check():
        try:
            for domain in response['Certificate']['DomainValidationOptions']:
                try:
                    _ = domain['ResourceRecord']
                except KeyError:
                    return False
        except KeyError:
            return False
        return True

    while True:
        print("No ResourceRecord in response yet..")
        time.sleep(5)
        response = client.describe_certificate(
            CertificateArn=cert_arn
        )
        print(response)

        if check():
            break

    return response


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Request ACM certificate for a domain.')
    parser.add_argument(
        '--domain', help='Domain for which cert has to be requested.', required=True)
    parser.add_argument(
        '--zoneid', help='ID of zone where CNAMEs for ACM verification should be created.', required=True)
    parser.add_argument('--profile', help="AWS profile that should be used.", required=True)
    parser.add_argument('--region', help="AWS region.", required=True)
    parser.add_argument(
        '--assume', help="Specify if a role has to be assumed for CNAME record creation.", action='store_true')
    parser.add_argument(
        '--role-arn', help="ARN of role to assume. Takes effect only if used with --assume flag.")

    args = vars(parser.parse_args())

    boto3.setup_default_session(profile_name=args['profile'])

    acm_client = boto3.client('acm', region_name=args['region'])
    route53_client = route53_get_client(
        assume=args['assume'], role_arn=args['role_arn'], region=args['region'])

    response = acm_client.request_certificate(
        DomainName=args['domain'],
        ValidationMethod='DNS',
        SubjectAlternativeNames=[
            "www.{0}".format(args['domain']),
        ]
    )

    cert_arn = response['CertificateArn']
    resource_records = get_resource_records(acm_client, cert_arn)
    for domain in resource_records['Certificate']['DomainValidationOptions']:
        record = domain['ResourceRecord']
        create_cname(route53_client, args['zoneid'], record['Name'], record['Value'])

    wait_until_all_verified(acm_client, cert_arn)
    time.sleep(25)  # some time for AWS to refresh state. Otherwise terraform fails sometimes.
    sys.exit(0)
