#!/bin/bash

export FREEIPA_PASSWORD=Pass1234
export FREEIPA_HOSTNAME=freeipa.example.com
export FREEIPA_DOMAIN=example.com

hostnamectl set-hostname --static ${FREEIPA_HOSTNAME}

firewall-cmd --permanent --add-service={ntp,http,https,ldap,ldaps,kerberos,kpasswd,dns}
firewall-cmd --reload
setenforce Permissive
sed -i -e s%SELINUX=.*%SELINUX=permissive%g /etc/sysconfig/selinux

dnf update -y \
&& dnf install -y selinux-policy \
&& dnf install -y freeipa-server freeipa-server-dns \
&& ipa-server-install \
-a ${FREEIPA_PASSWORD} \
--hostname=${FREEIPA_HOSTNAME} \
-n ${FREEIPA_DOMAIN} \
-p ${FREEIPA_PASSWORD} \
-r ${FREEIPA_DOMAIN} \
--setup-dns \
--no-forwarders \
-U

