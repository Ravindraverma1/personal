#!/bin/bash
##
# Remove OLD Kernel package to prevent false possitive DOME9/Nessus check
##
echo -e "Remove Old Kernels\n"
package-cleanup -y --oldkernel --count=1
echo -e "Fix sshd_config perm"
chmod og-rwx /etc/ssh/sshd_config
chmod 0750 /var/log

#saving ip6tables rules
sudo service ip6tables save
sudo systemctl start ip6tables
sudo systemctl enable ip6tables

# CIS 5.4.2 post installation
echo "CIS 5.4.2 post installation"
for i in `awk -F: '($3 < 500) {print $1}' /etc/passwd|grep -v root `;do  usermod -L $i;done
for i in `awk -F: '($3 < 500) {print $1}' /etc/passwd | egrep -v "root|sync|shutdown|halt"`;do echo $i ;usermod -s /sbin/nologin $i &>/dev/null;done

# CIS 5.4.2 Ensure system accounts are non-login (moved to additional_cis.yaml)
#echo "CIS 5.4.2 Ensure system accounts are non-login"
#for user in `awk -F: '($3 < 1000) {print $1 }' /etc/passwd`; do
# if [ $user != "root" ]; then
#  usermod -L $user
#  if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
#   usermod -s /usr/sbin/nologin $user
#  fi
# fi
#done

#CIS 1.1.2 Ensure /tmp is configured (cannot make the wanted restrictions to tmp without changing playbooks design)
#systemctl unmask tmp.mount
#systemctl enable tmp.mount
#sed -i "s/Options=.*/Options=mode=1777,nodev,nosuid/g" /etc/systemd/system/local-fs.target.wants/tmp.mount
#mount -o remount,noexec,nosuid /tmp

echo "Update AIDE database"
aide --update &>/dev/null
sudo mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
echo -e "Remove all NON AMAZON repos"
ls /etc/yum.repos.d/* | grep -v amzn| xargs rm -f
echo -e "Disable CLoud-init ot make YUM update"
sudo sed -i "/^repo_upgrade/s/\:.*/\:\ none/1" /etc/cloud/cloud.cfg
echo -e "Clenaup images\n"
yum clean all
history -c
echo "Cleanup Completes"