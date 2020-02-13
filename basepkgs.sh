#!/bin/bash
# simple bash script to install base packages for OKD v3.9 on KVM
# This script comes without warranty. Run at your own risk.

sudo yum -y update
# Install the CentOS OpenShift Origin v3.9 repo & all base packages
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct httpd-tools dnsmasq
# create .ssh folder in /root. Update the path if you plan to use a non-root
# user with Ansible.
mkdir -p /root/.ssh
# create passwordless ssh key for root. Update path if you're running a
# non-root user.
ssh-keygen -t rsa \
    -f /root/.ssh/id_rsa -N ''
sudo yum -y update
# Install the Extra Packages for Enterprise Linux (EPEL) repository
sudo yum -y install epel-release
# disable EPEL repo to prevent package conflicts
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
# Install PyOpenSSL from EpEL repo
sudo yum -y --enablerepo=epel install pyOpenSSL python-passlib
# install ansible-2.4.3.0 from CentOS archives
sudo yum -y install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.2-1.el7.ans.noarch.rpm
# Install Java
yum -y install java-1.8.0-openjdk-headless
# Reboot system to apply any kernel updates
sudo reboot