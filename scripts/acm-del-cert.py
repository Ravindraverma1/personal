import boto3
import sys
import argparse
import time

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Remove ACM certificates from AWS.')
    parser.add_argument('--profile', help="AWS profile that should be used.", required=True)
    parser.add_argument('--region', help="AWS region.", required=True)
    parser.add_argument('--domain', help="Domain name of the certificate.")

    args = vars(parser.parse_args())

    boto3.setup_default_session(profile_name=args['profile'])
    client = boto3.client('acm', region_name=args['region'])

    certs = client.list_certificates()['CertificateSummaryList']
    for cert in certs:
            # TODO: this sometimes fail with Resource In Use exception, we need a logic to wait and retry.
            # Can use what Terraform has done here as a guide: https://github.com/terraform-providers/terraform-provider-aws/pull/3868/commits/cf53d3a13d3063374a081a27019682bb467771a5
            # Temporarily, wait 30s before delete certs to make sure the resource is destroyed
        if cert['DomainName'] == args['domain']:
            try:
                client.delete_certificate(CertificateArn=cert['CertificateArn'])
            except Exception as err:
                retries_count = 5
                for i in range(retries_count):
                    try:
                        time.sleep(80)
                        print("executing the retry [{0}]".format(i))
                        client.delete_certificate(CertificateArn=cert['CertificateArn'])
                    except:
                        if i == 4:
                            print(err)
                            raise Exception('you may rerun the terminate-env pipeline')
                        elif i <= retries_count:
                            continue
                    break
    sys.exit(0)
