#!/bin/bash
## we are replacing rds-combined cert with the rds-ca-2019 as the first cert in the file was the only one used anyway .
sh -c 'umask 022; wget -O /etc/pki/ca-trust/source/anchors/rds-combined-ca-bundle.pem https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem; umask 027;'
update-ca-trust
##download the root certificate used for SSL encryption
sh -c 'umask 022; wget -O /etc/pki/ca-trust/source/anchors/rds-ca-2019-root.pem https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem; umask 022;'
# download AWS Redshift SSL cert bundle
sh -c 'umask 022; wget -O /etc/pki/ca-trust/source/anchors/redshift-ca-bundle.crt https://s3.amazonaws.com/redshift-downloads/redshift-ca-bundle.crt; umask 022;'