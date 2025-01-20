#!/bin/bash

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# mount volumes
mkdir -p /opt/axiom

vol_name=$(lsblk | grep nvm)
if [[ -z "$vol_name" ]];then
    echo "Volume name follow xvd format"
    mkfs -t ext4 /dev/sdf
    mkfs -t ext4 /dev/sdh
    resize2fs /dev/sdf
    resize2fs /dev/sdh
    mount /dev/sdh /opt/axiom
    fstab_entry=$(cat /etc/fstab | grep sdh)
    echo "/dev/sdh /opt/axiom    ext4 defaults,nofail 0   2" >> /etc/fstab
    # have to create log dir after mounting /opt/axiom
    mkdir -p /opt/axiom/logs
    mount /dev/sdf /opt/axiom/logs
    fstab_entry=$(cat /etc/fstab | grep sdf)
    if [[ -z "$fstab_entry" ]];then
        echo "/dev/sdf /opt/axiom/logs    ext4 defaults,nofail 0   2" >> /etc/fstab
    fi
else
    echo "Volume name follow nvm format"
    mkfs -t ext4 /dev/nvme1n1
    mkfs -t ext4 /dev/nvme2n1
    resize2fs /dev/nvme1n1
    resize2fs /dev/nvme2n1
    export ebs1=$(/sbin/ebsnvme-id /dev/nvme1n1 -b)
    export vol1=$(/sbin/ebsnvme-id /dev/nvme1n1 -v | awk -F'Volume ID: ' '{ print $2 }')

    if [[ "$ebs1" = "sdf" ]]; then
        mount /dev/nvme2n1 /opt/axiom
        fstab_entry=$(cat /etc/fstab | grep nvme2n1)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme2n1 /opt/axiom    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
        mkdir -p /opt/axiom/logs
        mount /dev/nvme1n1 /opt/axiom/logs
        fstab_entry=$(cat /etc/fstab | grep nvme1n1)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme1n1 /opt/axiom/logs    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
    else
        mount /dev/nvme1n1 /opt/axiom
        fstab_entry=$(cat /etc/fstab | grep nvme1n1)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme1n1 /opt/axiom    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
        mkdir -p /opt/axiom/logs
        mount /dev/nvme2n1 /opt/axiom/logs
        fstab_entry=$(cat /etc/fstab | grep nvme2n1)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme2n1 /opt/axiom/logs    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
    fi
fi
mkdir -p /opt/axiom/logs/server
chown -R axiom: /opt/axiom/logs/server
# Sync back logs from live folders
sudo -H -i -u axiom aws s3 sync s3://axiom-${customer}-${environment}-${region}-archival/cv-live /opt/axiom/logs/server --region ${region} &
sudo -H -i -u axiom aws s3 sync s3://axiom-${customer}-${environment}-${region}-archival/cv-wf-live /opt/axiom/logs/server --region ${region} &


cat << 'EOT' > /usr/bin/saml-enable.sh
#!/bin/bash

aws s3 cp s3://${customer}-${environment}-${region}-installation-data/federationmetadata.xml /tmp/server_v_${cv_version}/server-install/tmp/metadata.xml --region ${region}
keystoreFile=$(aws s3 ls s3://${customer}-${environment}-${region}-installation-data/keystore.pkcs12 --region ${region})

if [ -z "$keystoreFile" ];then
    echo "no existing file, generate new file"
    openssl genrsa -out axiom.key 2048
    openssl req -x509 -new -key axiom.key -days 9999 -out axiom.crt -subj "/CN=Axiom"
    openssl x509 -in axiom.crt -text -noout
    cat  axiom.key axiom.crt > keystore.pem
    openssl pkcs12 -export -in keystore.pem -out keystore.pkcs12 -name Axiom -noiter -nomaciter -passout pass:axiom123
    aws s3 cp keystore.pkcs12 s3://${customer}-${environment}-${region}-installation-data/ --region ${region}
    cp keystore.pkcs12 /tmp/server_v_${cv_version}/server-install/tmp/keystore.pkcs12
else
    echo "keystore exists, downloading existing keystore file"
    aws s3 cp s3://${customer}-${environment}-${region}-installation-data/keystore.pkcs12 /tmp/server_v_${cv_version}/server-install/tmp/keystore.pkcs12 --region ${region}
fi

for i in /tmp/playbooks/roles/cv/templates/cv_properties*.j2
    do
    sed -i 's/saml.enabled=false/saml.enabled=true/' $i
    sed -i "s/userDirectory.type=local/userDirectory.type=both/" $i
    echo -e "\nsaml.identifier=${customer_adfs_identifier}" >> $i
    echo "saml.directory=${customer_directory_name}" >> $i
    echo "saml.idp.metadata.file=/tmp/metadata.xml" >> $i
    echo "saml.keystore.file=/tmp/keystore.pkcs12" >> $i
    echo "saml.store.alias=Axiom" >> $i
    echo "saml.store.type=PKCS12" >> $i
    echo "saml.keystore.password=axiom123" >> $i
    echo "saml.storealias.password=axiom123" >> $i
done
EOT

df -h
aws configure list
aws s3 cp s3://${customer}-${environment}-${region}-installation-data/playbooks.tar.gz /tmp/ --region ${region}
aws s3 cp s3://${customer}-${environment}-${region}-installation-data/certs.tar.gz /tmp/ --region ${region}
tar xvzf /tmp/playbooks.tar.gz -C /tmp/
tar xvzf /tmp/certs.tar.gz -C /tmp/

if [ ! -z "${customer_adfs_identifier}" -a "${customer_adfs_identifier}" != " " ]; then chmod 500 /usr/bin/saml-enable.sh; fi
if [ ! -z "${customer_adfs_identifier}" -a "${customer_adfs_identifier}" != " " ]; then /usr/bin/saml-enable.sh; fi

if [ "${logz_enable}" = "false" ]; then
    echo "disable filebeat"
    sed -i 's/- filebeat/#- filebeat/' /tmp/playbooks/cv.yml
fi

/usr/bin/ansible-playbook -i 'localhost,' -c local /tmp/playbooks/cv.yml --extra-vars="host_part=cv customer=${customer} db_host=${db_host} axcloud_domain=${axcloud_domain} db_name=${db_name} db_username=${db_username} db_engine=${db_engine} db_engine_version=${db_engine_version} db_port=${db_port} cv_version=${cv_version} cv_system_schema=${cv_system_schema} cv_user_schema=${cv_user_schema} cv_db_engine=${cv_db_engine}  environ_ment=${environment} dd_id=${dd_id} dd_proxy_host=${dd_proxy_host} dd_proxy_port=${dd_proxy_port} EFS_IP=${mount_address} region=${region} enable_dd=${enable_dd} enable_migration_peering=${enable_migration_peering} disable_os_command=${disable_os_command} service_type=${service_type} saas_env=${saas_env} saas_customer=${saas_customer} logstash_host=${logstash_host} cv_xmx=${cv_xmx} db_local_admin_pwd=${db_local_admin_pwd} db_user_pwd=${db_user_pwd} db_meta_ro_user_pwd=${db_meta_ro_user_pwd} db_ro_user_pwd=${db_ro_user_pwd} db_ssl_port=${db_ssl_port} ssl_keystore_pwd=${ssl_keystore_pwd} db_ssl_enabled=${db_ssl_enabled} r_package_install_list=${r_package_install_list} cv_log_level=${cv_log_level} enable_outbound_transfer=${enable_outbound_transfer} customer_timezone=${customer_timezone} start_cv=${start_cv} recreate_cv_schema=${recreate_cv_schema} enable_data_lineage=${enable_data_lineage} reset_meta_usrs_paswd=${reset_meta_usrs_paswd} instance_id=$INSTANCE_ID blacklisted_cv_tag=${blacklisted_cv_tag} override_classes=${override_classes} override_services=${override_services} whitelist_classes=${whitelist_classes} whitelist_services=${whitelist_services} aurora_enabled=${aurora_enabled} aurora_db_engine=${aurora_db_engine} db_parameter_group_family=${db_parameter_group_family} cv_wlog_retention_period=${cv_wlog_retention_period} enable_worm_compliance=${enable_worm_compliance} enable_oci_db=${enable_oci_db} is_sysdb_postgres_oci=${is_sysdb_postgres_oci} oci_mtu_size=${oci_mtu_size} enable_snowflake=${enable_snowflake} customer_adfs_identifier=${customer_adfs_identifier} customer_directory_name=${customer_directory_name} cv_ui_retention_period=${cv_ui_retention_period} log_retention_period=${log_retention_period} logzio_proxy_host=${logzio_proxy_host} logs_logzio_token=${logs_logzio_token} logs_logzio_port=${logs_logzio_port} enable_spark=${enable_spark}"

# run the playbook normally if no customer_adfs_identifier
if [ -z "${customer_adfs_identifier}" -o "${customer_adfs_identifier}" = " " ]; then
    echo "no SAML"
else
    if [ "${switch_saml}" = "off" ]; then
        echo "saml is off"
        sed -i 's/property name="enabled" value="true"/property name="enabled" value="false"/' /opt/axiom/axiomServer/installDir/server-config/objects/sso/SSOConfiguration.xml
        ps aux | grep axiomServer | grep -v grep | awk '{print "kill -9 " $2}' | sh
        /etc/init.d/cv start
    fi
    if [ "${switch_saml}" = "on" ]; then
        echo "saml is on"
        # generate saml metadata and upload to s3
        sudo -H -i -u axiom /opt/axiom/axiomServer/installDir/server-bin/bin/generate_saml_metadata.sh
        aws s3 cp /opt/axiom/axiomServer/installDir/server-config/SAMLServiceProviderMetadata.xml s3://${customer}-${environment}-${region}-installation-data/ --region ${region}
        aws s3 cp /opt/axiom/axiomServer/installDir/server-config/objects/sso/SSOConfiguration.xml s3://${customer}-${environment}-${region}-installation-data/ --region ${region}
    fi
fi
echo "checking whether cv is running"
cv_process="$(ps aux | grep axiomServer | grep  ServerStarter)"
while true
do
    if [[ -z "$cv_process" ]];then
        echo "start cv again"
        chown -R axiom: /opt/axiom/logs/server
        chmod -R 777 /opt/axiom/logs/server
        /etc/init.d/cv start
    else
        echo "cv is running now"
        break;
    fi
    sleep 60s
    cv_process="$(ps aux | grep axiomServer | grep  ServerStarter)"
done

# start logstash at the end
systemctl restart logstash

