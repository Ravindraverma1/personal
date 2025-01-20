#!/bin/bash

aws s3 cp s3://${customer}-${environment}-${region}-installation-data/playbooks.tar.gz /tmp/ --region ${region}
tar xvzf /tmp/playbooks.tar.gz -C /tmp/

/usr/bin/ansible-playbook -i 'localhost,' -c local /tmp/playbooks/bastion.yml --extra-vars="host_part=${hostname} customer=${customer} environ_ment=${environment} region=${region} enable_migration_peering=${enable_migration_peering}"
