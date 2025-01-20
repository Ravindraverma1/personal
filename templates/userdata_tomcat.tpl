Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
# mount volumes
mkdir -p /opt/axiom

set +e
vol_name=$(lsblk | grep nvm)
if [[ -z "$vol_name" ]];then
    echo "Volume name follow xvd format"
    mount /dev/sdh /opt/axiom
    #move tomcat server dir to the /tmp/
    mv /opt/axiom/tomcat /tmp/

    umount -l /opt/axiom
    mkfs -t ext4 /dev/sdf
    mkfs -t ext4 /dev/sdh
    resize2fs /dev/sdf
    resize2fs /dev/sdh
    mount /dev/sdh /opt/axiom
    fstab_entry=$(cat /etc/fstab | grep sdh)
    if [[ -z "$fstab_entry" ]];then
        echo "/dev/sdh /opt/axiom    ext4 defaults,nofail 0   2" >> /etc/fstab
    fi
    # have to create log dir after mounting /opt/axiom
    mkdir -p /opt/axiom/logs
    mount /dev/sdf /opt/axiom/logs
    fstab_entry=$(cat /etc/fstab | grep sdf)
    if [[ -z "$fstab_entry" ]];then
        echo "/dev/sdf /opt/axiom/logs    ext4 defaults,nofail 0   2" >> /etc/fstab
    fi
else
    echo "Volume name follow nvm format"
    export ebs1=$(/sbin/ebsnvme-id /dev/nvme1n1 -b)
    export vol1=$(/sbin/ebsnvme-id /dev/nvme1n1 -v | awk -F'Volume ID: ' '{ print $2 }')
    if [[ "$ebs1" = "sdf" ]]; then
        mount /dev/nvme2n1 /opt/axiom
        #move tomcat server dir to the /tmp/
        mv /opt/axiom/tomcat /tmp/

        umount -l /opt/axiom
        mkfs -t ext4 /dev/nvme2n1
        resize2fs /dev/nvme2n1
        mount /dev/nvme2n1 /opt/axiom
        fstab_entry=$(cat /etc/fstab | grep sdh)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme2n1 /opt/axiom    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
        mkdir -p /opt/axiom/logs
        mkfs -t ext4 /dev/nvme1n1
        resize2fs /dev/nvme1n1
        mount /dev/nvme1n1 /opt/axiom/logs
        fstab_entry=$(cat /etc/fstab | grep sdh)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme1n1 /opt/axiom/logs    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
    else
        mount /dev/nvme1n1 /opt/axiom
        #move tomcat server dir to the /tmp/
        mv /opt/axiom/tomcat /tmp/

        umount -l /opt/axiom
        mkfs -t ext4 /dev/nvme1n1
        resize2fs /dev/nvme1n1
        mount /dev/nvme1n1 /opt/axiom
        fstab_entry=$(cat /etc/fstab | grep sdh)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme1n1 /opt/axiom    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
        mkdir -p /opt/axiom/logs
        mkfs -t ext4 /dev/nvme2n1
        resize2fs /dev/nvme2n1
        mount /dev/nvme2n1 /opt/axiom/logs
        fstab_entry=$(cat /etc/fstab | grep sdh)
        if [[ -z "$fstab_entry" ]];then
            echo "/dev/nvme2n1 /opt/axiom/logs    ext4 defaults,nofail 0   2" >> /etc/fstab
        fi
    fi
fi
#move tomcat server dir to /opt/axiom/
mv /tmp/tomcat /opt/axiom/
set -e

service=tomcat

if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
then
  echo "$service is running!!! no need to copy playbooks"
  systemctl daemon-reload
else
    aws s3 cp s3://${customer}-${environment}-${region}-installation-data/playbooks.tar.gz /root/ --region ${region}
    aws s3 cp s3://${customer}-${environment}-${region}-installation-data/certs.tar.gz /root/ --region ${region}
    tar xvzf /root/playbooks.tar.gz -C /root/
    tar xvzf /root/certs.tar.gz -C /root/

    if [ "${logz_enable}" = "false" ]; then
        echo "disable filebeat"
        sed -i 's/- filebeat/#- filebeat/' /root/playbooks/tomcat.yml 
    fi
fi

/usr/bin/ansible-playbook -i 'localhost,' -c local /root/playbooks/tomcat.yml --extra-vars="cv_version=${cv_version} host_part=tomcat customer=${customer} environ_ment=${environment} EFS_IP=${mount_address} region=${region} enable_dd=${enable_dd} dd_proxy_host=${dd_proxy_host} dd_proxy_port=${dd_proxy_port} enable_migration_peering=${enable_migration_peering} logstash_host=${logstash_host} tomcat_xmx=${tomcat_xmx} db_engine=${db_engine} db_engine_version=${db_engine_version} db_port=${db_port} db_name=${db_name} db_ssl_port=${db_ssl_port} ssl_keystore_pwd=${ssl_keystore_pwd} db_ssl_enabled=${db_ssl_enabled}  customer_timezone=${customer_timezone} instance_id=$INSTANCE_ID aurora_enabled=${aurora_enabled} aurora_db_engine=${aurora_db_engine} db_parameter_group_family=${db_parameter_group_family} enable_oci_db=${enable_oci_db} is_sysdb_postgres_oci=${is_sysdb_postgres_oci} oci_mtu_size=${oci_mtu_size} cv_ui_retention_period=${cv_ui_retention_period} log_retention_period=${log_retention_period} logzio_proxy_host=${logzio_proxy_host} logs_logzio_token=${logs_logzio_token} logs_logzio_port=${logs_logzio_port}"

--//
