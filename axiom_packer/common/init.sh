#!/bin/bash
# Upgrade OS
yum -y upgrade
# install ANSIBLE
yum -y install python-pip
sh -c 'umask 022; pip install ansible==2.7.0; umask 027'
sh -c 'yum install -y yum-plugin-fastestmirror'
# upgrade awscli version
sh -c 'pip install --upgrade awscli'

#CIS 2.1.2 Ensure X Window System is not installed (Scored)
echo "CIS 2.1.2 Ensure X Window System is not installed"
yum -y remove xorg-x11*
