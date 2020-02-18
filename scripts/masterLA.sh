#!/bin/bash

USERNAME=demouser
PASSWORD=Welcome@123!

echo $(date) " - Starting Script"

# Install EPEL repository
echo $(date) " - Installing EPEL"

yum -y install epel-release
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

echo $(date) " - EPEL successfully installed"

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
NM_CONTROLLED=yes
PERSISTENT_DHCLIENT=yes
DHCP_HOSTNAME=masterVM-0
EOF

systemctl restart network

echo $(date) " - Changed interface setting to NM_CONTROLLED=yes "

echo $(date) " - Adding entries to host file"

echo "10.10.1.13 bastionVM-0 bastion.linkazs.com" >> /etc/hosts
echo "10.10.1.10 masterVM-0  master.linkazs.com   okd.master.example.xip.io" >> /etc/hosts
echo "10.10.1.11 infraVM-0   infra.linkazs.com    apps.okd.infra.example.xip.io" >> /etc/hosts
echo "10.10.1.12 appnodeVM-0 node.linkazs.com" >> /etc/hosts

echo $(date) " -Entries added to host file"

# Update system to latest packages and install dependencies
echo $(date) " - Update system to latest packages and install dependencies"

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct httpd-tools dnsmasq
yum -y update

echo $(date) " - System updates successfully installed"

echo $(date) " -Entries added to host file"

echo$(date) " - Adding entries to the dnsmasq.conf and starting dnsmasq"

echo "address=/master.linkazs.com/10.10.1.10" >> /etc/dnsmasq.conf
echo "address=/infra.linkazs.com/10.10.1.11" >> /etc/dnsmasq.conf
echo "address=/node.linkazs.com/10.10.1.12" >> /etc/dnsmasq.conf
echo "address=/okd.master.linkazs.com/10.10.1.10" >> /etc/dnsmasq.conf
echo "address=/apps.okd.infra.linkazs.com/10.10.1.11" >> /etc/dnsmasq.conf

echo "resolv-file=/etc/resolv.dnsmasq" >> /etc/dnsmasq.conf

cp /etc/resov.conf /etc/resolv.dnsmasq

systemctl enable dnsmasq.service
systemctl start dnsmasq.service

echo$(date) " - Entries to the dnsmasq.conf added and dnsmasq started"

echo $(date) " - Setting up htpasswd as OpenShift Auth Provider"

mkdir -p /etc/origin/master
htpasswd -cb /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}

echo $(date) " - Setup of htpasswd successfully"

# Only install Ansible and pyOpenSSL on Master-0 Node
# python-passlib needed for metrics

echo $(date) " - Installing Ansible, pyOpenSSL and python-passlib"
yum -y --enablerepo=epel install pyOpenSSL python-passlib
yum -y install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.2-1.el7.ans.noarch.rpm

# Install java to support metrics
echo $(date) " - Installing Java"

yum -y install java-1.8.0-openjdk-headless

echo $(date) " - Java installed successfully"

# Install Docker
echo $(date) " - Installing Docker"

yum -y install docker
sed -i -e "s#^OPTIONS='--selinux-enabled'#OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'#" /etc/sysconfig/docker

echo $(date) " - Docker installed successfully"

# Create thin pool logical volume for Docker
echo $(date) " - Creating thin pool logical volume for Docker and staring service"

DOCKERVG=$( parted -m /dev/sda print all 2>/dev/null | grep unknown | grep /dev/sd | cut -d':' -f1 )

echo "DEVS=${DOCKERVG}" >> /etc/sysconfig/docker-storage-setup
echo "VG=docker-vg" >> /etc/sysconfig/docker-storage-setup
docker-storage-setup
if [ $? -eq 0 ]
then
   echo "Docker thin pool logical volume created successfully"
else
   echo "Error creating logical volume for Docker"
   exit 5
fi

# Enable and start Docker services

systemctl enable docker
systemctl start docker

echo $(date) " - Script Complete"