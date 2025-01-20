#!/bin/bash
set +e
FILES="/etc/modprobe.d/blacklist.conf /etc/modprobe.d/ccatg-media.conf /etc/modprobe.d/ccatg-wireless.conf /etc/modprobe.d/CIS.conf"
for i in $FILES;do if [ -f ${i} ];then rm -f $i; fi ;done

echo "Add Blacklist Modules"
cat > /etc/modprobe.d/blacklist.conf << EOFBLACK
#
# Listing a module here prevents the hotplug scripts from loading it.
# Usually that'd be so that some other driver will bind it instead,
# no matter which driver happens to get probed first.  Sometimes user
# mode tools can also control driver binding.
#
# Syntax: see modprobe.conf(5).
#

# watchdog drivers
blacklist i8xx_tco

# framebuffer drivers
blacklist aty128fb
blacklist atyfb
blacklist radeonfb
blacklist i810fb
blacklist cirrusfb
blacklist intelfb
blacklist kyrofb
blacklist i2c-matroxfb
blacklist hgafb
blacklist nvidiafb
blacklist rivafb
blacklist savagefb
blacklist sstfb
blacklist neofb
blacklist tridentfb
blacklist tdfxfb
blacklist virgefb
blacklist vga16fb
blacklist viafb

# ISDN - see bugs 154799, 159068
blacklist hisax
blacklist hisax_fcpcipnp

# sound drivers
blacklist snd-pcsp

# I/O dynamic configuration support for s390x (bz #563228)
blacklist chsc_sch
EOFBLACK

cat > /etc/modprobe.d/ccatg-media.conf << EOFMEDIA
blacklist cdrom
blacklist floppy
blacklist sr_mod
blacklist usb-storage
EOFMEDIA

# CIS 1.1.1 1-8 Ensure mounting of differants FS
echo "CIS 1.1.1 1-8 Ensure mounting of differants FS"
cat > /etc/modprobe.d/CIS.conf << EOFCIS
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
install fat /bin/true
install vfat /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install dccp /bin/true
install tipc /bin/true
options ipv6 disable=1
EOFCIS

#CIS 1.1.2 Ensure /tmp is configured (cannot make the wanted restrictions to tmp without changing playbooks design)
#echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
#systemctl unmask tmp.mount
#systemctl enable tmp.mount
#sed -i "s/Options=.*/Options=mode=1777,strictatime,noexec,nodev,nosuid/g" /etc/systemd/system/local-fs.target.wants/tmp.mount

#CIS 1.1.15 Fix tmpfs with noexec nodev and nosuid option into fstab.
echo "CIS 1.1.15-18 Fix tmpfs with noexec nodev and nosuid option into fstab."
sed -i "/tmpfs/s/defaults.*/defaults,nodev,nosuid,noexec        0 0/1" /etc/fstab

#CIS 1.1.17 Ensure noexec option set on /dev/shm partition
echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab
mount -o remount,noexec /dev/shm

#CIS 1.1.15 Fix tmpfs with noexec nodev and nosuid option into fstab.
echo "CIS 1.1.15-18 Fix tmpfs with noexec nodev and nosuid option into fstab."
sed -i "/tmpfs/s/defaults.*/defaults,nodev,nosuid,noexec        0 0/1" /etc/fstab

# CIS  1.2.2 fix gpgcheck into all repo.
echo "CIS 1.2.2 fix gpgcheck into all repo."
sed -i "/gpgcheck=0/s/gpgcheck=0/gpgcheck=1/g" /etc/yum.conf /etc/yum.repos.d/*

#CIS 1.3.1 AIde installation and configuration 
echo "CIS 1.3.1 Aide installation and configuration"
yum -y install aide
rm -f  /var/lib/aide/aide.db.*
echo "Initilize AIDE Database"
aide --init &>/dev/null
echo "AIDE DataBase initialization finished"
mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
#Exclude shared efs partition from Aide scans
echo "#Exclude shared EFS" >> /etc/aide.conf
echo "!/opt/axiom/shared"  >> /etc/aide.conf

#CIS 1.3.2 Ensure filesystem integrity is regularly checked
echo "CIS 1.3.2 Ensure filesystem integrity is regularly checked"
echo "0 5 * * 6 /usr/sbin/aide --check" | crontab -

# CIS 1.4
sed -i '/^SINGLE/s/SINGLE.*/SINGLE=\/sbin\/sulogin/1' /etc/sysconfig/init
echo "PROMPT=no" >>  /etc/sysconfig/init

# CIS 1.4.1 Ensure permissions on bootloader config are configured
#chown root:root /boot/grub/menu.lst
#chmod og-rwx /boot/grub/menu.lst
chown root:root /boot/grub2/grub.cfg
chmod og-rwx /boot/grub2/grub.cfg

# CIS 1.5.1 Ensure core dumps are restricted (part in 3.1)
echo "CIS 1.5.1 Ensure core dumps are restricted "
sed -i "/\#\ End\ of\ file/d" /etc/security/limits.conf
echo -e "* hard core 0\n* soft sigpending 151551\n* hard sigpending 151551\n* soft nofile  65536\n* hard nofile  65536\n* soft nproc  16384\n* hard nproc  16384\n* soft core unlimited\n\n# End of file" >> /etc/security/limits.conf
sysctl -w fs.suid_dumpable=0

#1.5.2 Ensure address space layout randomization (ASLR) is enabled (part in 3.1)
sysctl -w kernel.randomize_va_space=2

# CIS 1.7.1
echo "CIS 1.7.1 Banner "
rm -f /etc/issue /etc/issue.net
echo -e "\n Authorized uses only. All activity may be monitored and reported.\n" > /etc/issue
chmod 644 /etc/issue
cp -p /etc/issue /etc/issue.net

# CIS 1.7.1.4 motd permision and config 
echo "CIS 1.7.1.4 motd permision and config"
rm -f /etc/motd
cat > /etc/motd << EOFMOTD
--------------------------------------------------------------------------
     ___      ___   ___  __    ______   .___  ___.      _______. __      
    /   \     \  \ /  / |  |  /  __  \  |   \/   |     /       ||  |     
   /  ^  \     \  V  /  |  | |  |  |  | |  \  /  |    |   (----'|  |     
  /  /_\  \     >   <   |  | |  |  |  | |  |\/|  |     \   \    |  |     
 /  _____  \   /  .  \  |  | |  '--'  | |  |  |  | .----)   |   |  '----.
/__/     \__\ /__/ \__\ |__|  \______/  |__|  |__| |_______/    |_______|

--------------------------------------------------------------------------
                      NOTICE TO USERS
--------------------------------------------------------------------------
This computer system is the private property of AxiomSL, whether individual, corporate or government. It is for authorized users only. Users (authorized & unauthorized) have no explicit/implicit expectation of privacy. Any or all uses of this system and all files on this system may be intercepted, monitored, recorded, copied, audited, inspected, and disclosed to your employer, to authorized site, government, and/or law enforcement personnel, as well as authorized officials of government agencies, both domestic and foreign.

By using this system, the user expressly consents to such interception, monitoring, recording, copying, auditing, inspection, and disclosure at the discretion of such officials. Unauthorized or improper use of this system may result in civil and criminal penalties and administrative or disciplinary action, as appropriate. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the conditions stated in this warning.
EOFMOTD
chmod 644 /etc/motd

# CIS 3.1 Network Configuration
echo "CIS 3.1 Network Configuration"
cat > /etc/sysctl.conf << 'EOF'
net.ipv4.ip_forward=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
net.ipv4.route.flush=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_challenge_ack_limit = 999999999
net.ipv4.tcp_syncookies=1
net.ipv6.conf.all.forwarding=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
fs.file-max = 1636802
fs.file-nr = 1312       0       1636802
fs.inode-nr = 78368     276
fs.suid_dumpable = 0
kernel.randomize_va_space = 2
EOF

sed -i "/^decode/s/decode/\#decode/1" /etc/aliases

# CIS 3.1.1 Ensure IP forwarding is disabled (part in 3.1)
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv6.conf.all.forwarding=0
sysctl -w net.ipv4.route.flush=1
sysctl -w net.ipv6.route.flush=1

# CIS 3.2.1 Ensure source routed packets are not accepted (part in 3.1)
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0
sysctl -w net.ipv6.conf.all.accept_source_route=0
sysctl -w net.ipv6.conf.default.accept_source_route=0
sysctl -w net.ipv4.route.flush=1
sysctl -w net.ipv6.route.flush=1

# CIS 3.4.2 - 3.4.3 Ensure /etc/hosts.allow and /etc/hosts.deny is configured
echo "CIS 3.4.2 - 3.4.3 Ensure /etc/hosts.allow and /etc/hosts.deny is configured"
echo -e "sshd: ALL" >>  /etc/hosts.allow
echo -e "sshd: ALL: allow\nALL: ALL" >>  /etc/hosts.deny
chmod 0644 /etc/hosts.deny
chmod 0644 /etc/hosts.allow

# CIS 3.6.1 Disable iptabes
systemctl stop firewalld || true
systemctl mask firewalld
yum install iptables-services -y
echo "CIS 3.6.1 Disable iptabes"
cat > /etc/iptables.rules << EOF 
# Generated by iptables-save
# Port TCP 22 SSH 
# Port UDP 68 DHCP 
# Port UDP 323 Chrony 
# Port TCP 9999, 8089 and 8100 CV server
# Port TCP 2049 EFS Backup
# Port TCP 443 and 4443 Nginx 
# Port TCP 8099 and 8081 Tomcat Server
# Port TCP 5044 logstash
# Port TCP 1522 OCI DB
# 
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -s 127.0.0.0/8 -j DROP
-A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
-A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
-A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
-A INPUT -p udp -m udp --dport 68 -m state --state NEW -j ACCEPT
-A INPUT -p udp -m udp --dport 111 -m state --state NEW -j ACCEPT
-A INPUT -p udp -m udp --dport 323 -m state --state NEW -j ACCEPT
-A INPUT -p udp -m udp --dport 669 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 9999 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8089 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8100 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 2049 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 4443 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8099 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8081 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 5044 -m state --state NEW -j ACCEPT
-A INPUT -p tcp -m tcp --dport 1522 -m state --state NEW -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
-A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
-A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
COMMIT
# Complete
EOF
iptables -F
iptables-restore < /etc/iptables.rules

# CIS 3.5.1.1 Ensure IP default deny firewall policy
echo "CIS 3.5.1.1 Ensure IP default deny firewall policy"
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# CIS 3.5.2.1 Ensure IPv6 default deny firewall policy
echo "CIS 3.5.2.1 Ensure IPv6 default deny firewall policy"
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP

# CIS 3.5.2.2 Ensure IPv6 loopback traffic is configured
echo "CIS 3.5.2.2 Ensure IPv6 loopback traffic is configured"
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT
ip6tables -A INPUT -s ::1 -j DROP

service ip6tables save
systemctl start ip6tables
systemctl enable ip6tables

service iptables save
systemctl start iptables
systemctl enable iptables

for i in /usr/etc /usr/local/etc /var/log /sbin /usr/sbin /usr/local/bin;do chmod 711 $i ; chown root:root $i;done 

for i in shutdown halt games gopher ftp;do userdel $i &>/dev/null;done 
for i in netconsole rdisc ip6tables;do chkconfig $i off;done 

#fix file permission 
dd="/bin/dmesg /bin/mount /bin/rpm /usr/bin/write /usr/bin/ipcrm /usr/bin/ipcs /sbin/arp /sbin/ifconfig /bin/tracepath /bin/tracepath6 /bin/traceroute /bin/traceroute6 /usr/sbin/repquota /usr/bin/wget /usr/bin/who /usr/bin/w /usr/bin/wall"

for i in $dd;do chmod 0550 $i;done
for i in /etc/bashrc /etc/csh.cshrc /etc/csh.login;do chown root:root $i ; chmod 0444 $i;done 
for i in /etc/profile /etc/environment;do chown root:root $i ; chmod 0444 $i;done 

# CIS 4.2.1.3 Ensure rsyslog default file permissions configured 
echo "CIS 4.2.1.3 Ensure rsyslog default file permissions configured"
echo -e "\$FileCreateMode 0640" >> /etc/rsyslog.conf

# CIS 4.2.1.4 Ensure rsyslog is configured to send logs to a remote log host
echo "CIS 4.2.1.4 Ensure rsyslog is configured to send logs to a remote log host"
for i in /etc/rsyslog.conf /etc/rsyslog.d/* ; do echo "*.*  @@192.168.0.1" >> $i;done

# CIS 5.1 Configure cron
echo "CIS 5.1 Configure cron"
chkconfig crond on
chown root:root /etc/crontab ; chmod og-rwx /etc/crontab
for i in cron.d cron.daily cron.hourly cron.monthly crontab cron.weekly;do chmod og-rwx /etc/$i;done 
sed -i "/pam_access.so/i auth       sufficient pam_rootok.so" /etc/pam.d/crond

# CIS 5.1.7-8
echo "CIS 5.1.7-8 cron & at file permission"
rm -f /etc/cron.deny &>/dev/null
rm -f /etc/at.deny &>/dev/null
touch /etc/cron.allow
touch /etc/at.allow
chmod og-rwx /etc/cron.allow
chmod og-rwx /etc/at.allow
chown root:root /etc/cron.allow
chown root:root /etc/at.allow

# CIS 5.2 Configure SSH service (including CIS 5.2.15)
echo "Configure SSH service CIS 5.2"
sed -i "/^X11Forwarding/s/.*X11Forwarding.*/X11Forwarding\ no/1" /etc/ssh/sshd_config 
sed -i "/MaxAuthTries/s/.*MaxAuthTries.*/MaxAuthTries\ 4/1" /etc/ssh/sshd_config 
sed -i "/IgnoreRhosts/s/.*IgnoreRhosts.*/IgnoreRhosts\ yes/1" /etc/ssh/sshd_config 
sed -i "/LogLevel/s/.*LogLevel.*/LogLevel\ INFO/1" /etc/ssh/sshd_config 
sed -i "/^#HostbasedAuthentication/s/.*HostbasedAuthentication.*/HostbasedAuthentication\ no/1" /etc/ssh/sshd_config 
sed -i "/AllowUsers/d" /etc/ssh/sshd_config
sed -i "/^PermitRootLogin/s/.*PermitRootLogin.*/PermitRootLogin\ no/1" /etc/ssh/sshd_config
sed -i "/^#PermitRootLogin/s/.*PermitRootLogin.*/PermitRootLogin\ no/1" /etc/ssh/sshd_config
sed -i "/PermitEmptyPasswords/s/.*PermitEmptyPasswords.*/PermitEmptyPasswords\ no/1" /etc/ssh/sshd_config 
sed -i "/PermitUserEnvironment/s/.*PermitUserEnvironment.*/PermitUserEnvironment\ no/1" /etc/ssh/sshd_config 
sed -i "/ClientAliveInterval/s/.*ClientAliveInterval.*/ClientAliveInterval\ 300/1" /etc/ssh/sshd_config 
sed -i "/ClientAliveCountMax/s/.*ClientAliveCountMax.*/ClientAliveCountMax\ 0/1" /etc/ssh/sshd_config 
sed -i "/LoginGraceTime/s/.*LoginGraceTime.*/LoginGraceTime\ 1m/1" /etc/ssh/sshd_config 
sed -i "/UseDNS/s/.*UseDNS.*/UseDNS\ no/1" /etc/ssh/sshd_config
sed -i "/PasswordAuthentication/s/.*PasswordAuthentication.*/PasswordAuthentication\ no/1" /etc/ssh/sshd_config
echo -e "\nCiphers aes128-ctr,aes192-ctr,aes256-ctr\nMACs hmac-sha2-512,hmac-sha2-256\nBanner /etc/issue.net\nProtocol 2\nAllowGroups wheel" >> /etc/ssh/sshd_config
echo -e "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256" >> /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

# CIS 5.3 Configure PAM (password policy etc...)
echo "CIS 5.3 Configure PAM (password policy etc...)"
sed -i "/password    sufficient    pam_unix.so/s/$/\ remember=5/1" /etc/pam.d/system-auth
sed -i "/password    sufficient    pam_unix.so/s/$/\ remember=5/1" /etc/pam.d/password-auth
echo "#Defaults    requiretty" >> /etc/sudoers

# CIS 5.3.1
echo -e "minlen = 14\ndcredit = -1\nlcredit = -1\nocredit = -1 \nucredit = -1" >> /etc/security/pwquality.conf

# CIS 5.3.2 (moved to additional_cis.yaml)
#sed -i "s/pam_faildelay.so.*$/pam_faillock.so preauth audit silent deny=5 unlock_time=900\nauth\t    [success=1 default=bad] pam_unix.so/1" /etc/pam.d/password-auth
#sed -i "s/pam_faildelay.so.*$/pam_faillock.so preauth audit silent deny=5 unlock_time=900\nauth\t    [success=1 default=bad] pam_unix.so/1" /etc/pam.d/system-auth
#sed -i "/auth        sufficient    pam_unix.so/s/$/\nauth\t    [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900\nauth\t    sufficient    pam_faillock.so authsucc audit deny=5 unlock_time=900 /1" /etc/pam.d/password-auth
#sed -i "/auth        sufficient    pam_unix.so/s/$/\nauth\t    [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900\nauth\t    sufficient    pam_faillock.so authsucc audit deny=5 unlock_time=900 /1" /etc/pam.d/system-auth
#sed -i "/auth        sufficient    pam_unix.so/d"  /etc/pam.d/password-auth
#sed -i "/auth        sufficient    pam_unix.so/d"  /etc/pam.d/system-auth

# CIS  5.4 Password Policy Definition
echo "CIS 5.4 Password Policy Definition"
sed -i "/^PASS_MAX_DAYS/s/PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/1" /etc/login.defs
sed -i "/^PASS_MIN_DAYS/s/PASS_MIN_DAYS.*/PASS_MIN_DAYS\t7/1" /etc/login.defs
sed -i "/^PASS_MIN_LEN/s/PASS_MIN_LEN.*/PASS_MIN_LEN\t8/1" /etc/login.defs
sed -i "/^UMASK/s/UMASK.*/UMASK\t027/1" /etc/login.defs
useradd -D -f 30

# CIS 5.4.2 Ensure system accounts are non-login
echo "CIS 5.4.2 Ensure system accounts are non-login"
sed -i "/^UID_MIN/s/ 500/1000/1;/^GID_MIN/s/ 500/1000/1" /etc/login.defs

#CIS 5.4.4 Umask fix
echo "CIS 5.4.4 Umask fix"
sed -i '/umask/s/umask.*/umask 077/g' /etc/profile
sed -i '/  umask/s/umask.*/umask 077/g' /etc/bashrc
echo "TMOUT=600" >> /etc/profile
echo "TMOUT=600" >> /etc/bashrc

# CIS 5.5 Ensure access to the su command is restricted
echo "CIS 5.5 Ensure access to the su command is restricted"
echo -e "auth \trequired \tpam_wheel.so \tuse_uid" >> /etc/pam.d/su

# CIS 6.1 file permission
echo "CIS 6.1 file permission"
for i in /etc/gshadow  /etc/shadow- /etc/gshadow- ; do chown root:root $i;chmod 000 $i;done 
for i in /etc/csh.login /etc/environment;do chmod 444 $i; chown root:root $i;done
for i in /etc/group /etc/passwd;do chmod 644 $i; chown root:root $i;done

#CIS 6.2.8 Ensure users home directories permissions are 750 or more restrictive
echo "CIS 6.2.8 Ensure users home directories permissions"
for i in `ls /home/`;do chmod 750 /home/$i;done
chmod -R 750 /var/lib/nfs

#Additional hardening
#Adding command line logging with auditd rules:
echo "-a exit,always -F arch=b64 -S execve" >> /etc/audit/rules.d/audit.rules
echo "-a exit,always -F arch=b32 -S execve" >> /etc/audit/rules.d/audit.rules

exit 0

