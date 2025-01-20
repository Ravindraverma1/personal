#!/bin/bash

df -h
aws s3 cp s3://${customer}-${environment}-${region}-installation-data/playbooks.tar.gz /tmp/ --region ${region}
aws s3 cp s3://${customer}-${environment}-${region}-installation-data/certs.tar.gz /tmp/ --region ${region}
tar xvzf /tmp/playbooks.tar.gz -C /tmp/
tar xvzf /tmp/certs.tar.gz -C /tmp/

if [ "${logz_enable}" = "false" ]; then
    echo "disable filebeat"
    sed -i 's/- filebeat/#- filebeat/' /tmp/playbooks/nginx.yml 
fi

/usr/bin/ansible-playbook -i 'localhost,' -c local /tmp/playbooks/nginx.yml --extra-vars="host_part=nginx customer=${customer} environ_ment=${environment} region=${region} enable_dd=${enable_dd} dd_proxy_host=${dd_proxy_host} dd_proxy_port=${dd_proxy_port} enable_migration_peering=${enable_migration_peering} logstash_host=${logstash_host} cv_version=${cv_version} customer_timezone=${customer_timezone} enable_rest=${enable_rest} cv_ui_retention_period=${cv_ui_retention_period} log_retention_period=${log_retention_period} logzio_proxy_host=${logzio_proxy_host} logs_logzio_token=${logs_logzio_token} logs_logzio_port=${logs_logzio_port}"

if [ ! -z "${customer_adfs_identifier}" -a "${customer_adfs_identifier}" != " " ]; then
    if [ "${switch_saml}" = "off" ]; then
        sed -i '/samlEnabled/ s/[^[:blank:]]\{1,\}$/false;/' /etc/nginx/nginx.conf
        service nginx restart
    elif [ "${switch_saml}" = "on" ]; then
        sed -i '/samlEnabled/ s/[^[:blank:]]\{1,\}$/true;/' /etc/nginx/nginx.conf
        service nginx restart
    fi
fi
