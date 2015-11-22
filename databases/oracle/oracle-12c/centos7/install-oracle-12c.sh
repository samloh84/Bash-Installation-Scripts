#!/bin/bash

export ORACLE_SERVER_HOSTNAME=oracledb
export ORACLE_SERVER_IP_ADDRESS=127.0.0.1
export ORACLE_USER=oracle
export ORACLE_USER_PASSWORD=Pass1234

export SYS_PASSWORD=${ORACLE_USER_PASSWORD}
export SYSTEM_PASSWORD=${ORACLE_USER_PASSWORD}
export SYSMAN_PASSWORD=${ORACLE_USER_PASSWORD}
export DB_SNMP_PASSWORD=${ORACLE_USER_PASSWORD}
export HOSTUSER_PASSWORD=${ORACLE_USER_PASSWORD}
export ASM_SNMP_PASSWORD=${ORACLE_USER_PASSWORD}
export PDB_ADMIN_PASSWORD=${ORACLE_USER_PASSWORD}

export ORACLE_INSTALL_GROUP=oinstall
export ORACLE_DBA_GROUP=dba
export ORACLE_OPER_GROUP=oper

export ORACLE_UNIQUE_NAME=oracle
export ORACLE_SID=oracle

export ORACLE_PDB_NAME=pdboracle

export ORACLE_ROOT=/u01
export ORACLE_APP_ROOT=/u01/app
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME_ROOT=/u01/app/oracle/product/12.1.0/
export ORACLE_HOME=/u01/app/oracle/product/12.1.0/db_1
export ORACLE_INVENTORY_LOCATION=/u01/app/oraInventory
export ORACLE_STARTER_DB_DATA_LOCATION=/u01/app/oracle/oradata
export ORACLE_STARTER_DB_MEMORY_LIMIT=512


function execute_as_user {
	USERNAME=${1}
	shift
	if [[ "$(whoami)" != "${USERNAME}" ]]; then
		su ${USERNAME} -c $@
	else
		$@
	fi
}

function execute_as_root {
	if [[ "$(whoami)" != "root" ]]; then
		su -c $@
	else
		$@
	fi
}


function preinstall {
	#sudo su <<-EOF

	if [[ -f /etc/hostname ]]; then
		echo "${ORACLE_SERVER_HOSTNAME}" > /etc/hostname
	fi

	sed -i -e "s%HOSTNAME=.*$%HOSTNAME=${ORACLE_SERVER_HOSTNAME}%g" /etc/sysconfig/network

	echo "${ORACLE_SERVER_IP_ADDRESS} ${ORACLE_SERVER_HOSTNAME}" >> /etc/hosts
	hostname ${ORACLE_SERVER_HOSTNAME}

	groupadd -g 501 ${ORACLE_INSTALL_GROUP}
	groupadd -g 502 ${ORACLE_DBA_GROUP}
	groupadd -g 503 ${ORACLE_OPER_GROUP}

	useradd -u 502 -g ${ORACLE_INSTALL_GROUP} -G ${ORACLE_DBA_GROUP},${ORACLE_OPER_GROUP},wheel ${ORACLE_USER}
	echo "${ORACLE_USER_PASSWORD}" | passwd ${ORACLE_USER} --stdin --force

	sed -i \
		-e 's%net.bridge.bridge-nf-call-ip6tables%#net.bridge.bridge-nf-call-ip6tables%' \
		-e 's%net.bridge.bridge-nf-call-iptables%#net.bridge.bridge-nf-call-iptables%' \
		-e 's%net.bridge.bridge-nf-call-arptables%#net.bridge.bridge-nf-call-arptables%' \
		/etc/sysctl.conf

	cat <<-SYSCTL_EOF >> /etc/sysctl.conf
		# Oracle Install
		kernel.shmmni = 4096
		kernel.shmmax = 4398046511104
		kernel.shmall = 1073741824
		kernel.sem = 250 32000 100 128
		fs.aio-max-nr = 1048576
		fs.file-max = 6815744
		net.ipv4.ip_local_port_range = 9000 65500
		net.core.rmem_default = 262144
		net.core.rmem_max = 4194304
		net.core.wmem_default = 262144
		net.core.wmem_max = 1048586
SYSCTL_EOF
	sysctl -p

	cat <<-LIMITS_EOF >> /etc/security/limits.conf
		# Oracle Install
		${ORACLE_USER}   soft   nproc	131072
		${ORACLE_USER}   hard   nproc	131072
		${ORACLE_USER}   soft   nofile   131072
		${ORACLE_USER}   hard   nofile   131072
		${ORACLE_USER}   soft   core	 unlimited
		${ORACLE_USER}   hard   core	 unlimited
		${ORACLE_USER}   soft   memlock  50000000
		${ORACLE_USER}   hard   memlock  50000000
LIMITS_EOF

	cat <<-I18N_EOF > /etc/locale.conf
		LANG="en_US.UTF-8"
		LC_CTYPE="en_US.UTF-8"
		LC_NUMERIC="en_US.UTF-8"
		LC_TIME="en_US.UTF-8"
		LC_COLLATE="en_US.UTF-8"
		LC_MONETARY="en_US.UTF-8"
		LC_MESSAGES="en_US.UTF-8"
		LC_PAPER="en_US.UTF-8"
		LC_NAME="en_US.UTF-8"
		LC_ADDRESS="en_US.UTF-8"
		LC_TELEPHONE="en_US.UTF-8"
		LC_MEASUREMENT="en_US.UTF-8"
		LC_IDENTIFICATION="en_US.UTF-8"
		LC_ALL=
I18N_EOF

	yum groupinstall -y "Desktop" "Development Tools"
	yum install -y binutils compat-libstdc++-33 compat-libstdc++-33.i686 gcc gcc-c++ glibc glibc.i686 glibc-devel glibc-devel.i686 ksh libgcc libgcc.i686 libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libaio libaio.i686 libaio-devel libaio-devel.i686 libXext libXext.i686 libXtst libXtst.i686 libX11 libX11.i686 libXau libXau.i686 libxcb libxcb.i686 libXi libXi.i686 make sysstat unixODBC unixODBC-devel zlib-devel

	mkdir -p ${ORACLE_HOME_ROOT}
	chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} ${ORACLE_ROOT}
	chmod -R 775 ${ORACLE_APP_ROOT}

	sed -i -e "s%SELINUX=.*$%SELINUX=disabled%g" /etc/sysconfig/selinux

	pidof systemd
	if [[ "$?" -eq "0" ]]; then
		systemctl disable firewalld &> /dev/null
		systemctl disable iptables &> /dev/null
	else
		chkconfig firewalld off &> /dev/null
		chkconfig iptables off &> /dev/null
	fi

	unzip -o -qq linuxamd64_12c_database_1of2.zip -d /home/${ORACLE_USER}
	unzip -o -qq linuxamd64_12c_database_2of2.zip -d /home/${ORACLE_USER}
	chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} /home/${ORACLE_USER}


	cp oracle-db-env.sh /etc/profile.d/oracle-db.sh
	sed -i \
		-e "s%\${ORACLE_USER}%${ORACLE_USER}%g" \
		-e "s%export ORACLE_HOSTNAME=\${ORACLE_SERVER_HOSTNAME}%export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}%g" \
		-e "s%export ORACLE_UNQNAME=\${ORACLE_UNIQUE_NAME}%export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}%g" \
		-e "s%export ORACLE_BASE=\${ORACLE_BASE}%export ORACLE_BASE=${ORACLE_BASE}%g" \
		-e "s%export ORACLE_HOME=\${ORACLE_HOME}%export ORACLE_HOME=${ORACLE_HOME}%g" \
		-e "s%export ORACLE_SID=\${ORACLE_SID}%export ORACLE_SID=${ORACLE_SID}%g" \
		/etc/profile.d/oracle-db.sh
	chmod +x /etc/profile.d/oracle-db.sh

	echo "Completed Pre-Install"
}

function install {

	source /etc/profile.d/oracle-db.sh

	cp db_install.rsp /home/${ORACLE_USER}/database/db_install.rsp
	sed -i \
		-e "s%\${DB_SNMP_PASSWORD}%${DB_SNMP_PASSWORD}%g" \
		-e "s%\${ORACLE_BASE}%${ORACLE_BASE}%g" \
		-e "s%\${ORACLE_DBA_GROUP}%${ORACLE_DBA_GROUP}%g" \
		-e "s%\${ORACLE_HOME}%${ORACLE_HOME}%g" \
		-e "s%\${ORACLE_INSTALL_GROUP}%${ORACLE_INSTALL_GROUP}%g" \
		-e "s%\${ORACLE_INVENTORY_LOCATION}%${ORACLE_INVENTORY_LOCATION}%g" \
		-e "s%\${ORACLE_OPER_GROUP}%${ORACLE_OPER_GROUP}%g" \
		-e "s%\${ORACLE_SERVER_HOSTNAME}%${ORACLE_SERVER_HOSTNAME}%g" \
		-e "s%\${ORACLE_SID}%${ORACLE_SID}%g" \
		-e "s%\${ORACLE_STARTER_DB_DATA_LOCATION}%${ORACLE_STARTER_DB_DATA_LOCATION}%g" \
		-e "s%\${ORACLE_STARTER_DB_MEMORY_LIMIT}%${ORACLE_STARTER_DB_MEMORY_LIMIT}%g" \
		-e "s%\${ORACLE_UNIQUE_NAME}%${ORACLE_UNIQUE_NAME}%g" \
		-e "s%\${ORACLE_USER_PASSWORD}%${ORACLE_USER_PASSWORD}%g" \
		-e "s%\${ORACLE_USER}%${ORACLE_USER}%g" \
		-e "s%\${SYS_PASSWORD}%${SYS_PASSWORD}%g" \
		-e "s%\${SYSMAN_PASSWORD}%${SYSMAN_PASSWORD}%g" \
		-e "s%\${SYSTEM_PASSWORD}%${SYSTEM_PASSWORD}%g" \
		/home/${ORACLE_USER}/database/db_install.rsp

	chmod 700 /home/${ORACLE_USER}/database/db_install.rsp

	echo "Running Oracle Database Installer"
	/home/${ORACLE_USER}/database/runInstaller -silent -waitforcompletion -responseFile /home/${ORACLE_USER}/database/db_install.rsp

	rm ${ORACLE_HOME}/rdbms/lib/config.o

	rm -rf ${ORACLE_HOME}/lib/stubs/*
	cp ${ORACLE_HOME}/rdbms/lib/env_rdbms.mk ${ORACLE_HOME}/rdbms/lib/env_rdbms.mk.orig

	sed -i \
		-e '176s%LINKTTLIBS=\$(LLIBCLNTSH) \$(ORACLETTLIBS) \$(LINKLDLIBS)%LINKTTLIBS=\$(LLIBCLNTSH) \$(ORACLETTLIBS) \$(LINKLDLIBS) -lons%' \
		-e '279s%LINK=\$(FORT_CMD) \$(PURECMDS) \$(ORALD) \$(LDFLAGS) \$(COMPSOBJS)%LINK=\$(FORT_CMD) \$(PURECMDS) \$(ORALD) \$(LDFLAGS) \$(COMPSOBJS) -Wl,--no-as-needed%' \
		-e '280s%LINK32=\$(FORT_CMD) \$(PURECMDS) \$(ORALD) \$(LDFLAGS32) \$(COMPSOBJS)%LINK32=\$(FORT_CMD) \$(PURECMDS) \$(ORALD) \$(LDFLAGS32) \$(COMPSOBJS) -Wl,--no-as-needed%' \
		-e '3042s%\$(LLIBTHREAD) \$(LLIBCLNTSH) \$(LINKLDLIBS)%\$(LLIBTHREAD) \$(LLIBCLNTSH) \$(LINKLDLIBS) -lnnz12%' \
		${ORACLE_HOME}/rdbms/lib%env_rdbms.mk
	${ORACLE_HOME}/bin/relink all

	echo "Completed Installation of Oracle Database"
}

function rootscripts {

	${ORACLE_INVENTORY_LOCATION}/orainstRoot.sh
	${ORACLE_HOME}/root.sh
	echo "Completed running Oracle Installation Root Scripts"

}

function postinstall {
	cp dbca.rsp /home/${ORACLE_USER}/database/dbca.rsp
	sed -i \
		-e "s%\${DB_SNMP_PASSWORD}%${DB_SNMP_PASSWORD}%g" \
		-e "s%\${ORACLE_SID}%${ORACLE_SID}%g" \
		-e "s%\${ORACLE_UNIQUE_NAME}%${ORACLE_UNIQUE_NAME}%g" \
		-e "s%\${SYS_PASSWORD}%${SYS_PASSWORD}%g" \
		-e "s%\${SYSMAN_PASSWORD}%${SYSMAN_PASSWORD}%g" \
		-e "s%\${SYSTEM_PASSWORD}%${SYSTEM_PASSWORD}%g" \
		/home/${ORACLE_USER}/database/dbca.rsp
	echo "Running Oracle Database Configuration Assistant"
	${ORACLE_HOME}/bin/dbca -silent -responsefile /home/${ORACLE_USER}/database/dbca.rsp


	export DISPLAY=:0.0
	cp netca.rsp /home/${ORACLE_USER}/database/netca.rsp
	echo "Running Oracle Net Configuration Assistant"
	${ORACLE_HOME}/bin/netca -silent -responsefile /home/${ORACLE_USER}/database/netca.rsp

	cp cfgrsp.properties /home/${ORACLE_USER}/database/cfgrsp.properties
	sed -i \
		-e "s%\${ASM_SNMP_PASSWORD}%${ASM_SNMP_PASSWORD}%g" \
		-e "s%\${DB_SNMP_PASSWORD}%${DB_SNMP_PASSWORD}%g" \
		-e "s%\${HOSTUSER_PASSWORD}%${HOSTUSER_PASSWORD}%g" \
		-e "s%\${SYS_PASSWORD}%${SYS_PASSWORD}%g" \
		-e "s%\${SYSMAN_PASSWORD}%${SYSMAN_PASSWORD}%g" \
		-e "s%\${SYSTEM_PASSWORD}%${SYSTEM_PASSWORD}%g" \
		/home/${ORACLE_USER}/database/cfgrsp.properties

	echo "Running Oracle Configuration Tool"
	${ORACLE_HOME}/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/home/${ORACLE_USER}/database/cfgrsp.properties

	echo "Completed configuration of Oracle Database"
}

function install_scripts {
	sed -i -e 's%${ORACLE_SID}:${ORACLE_HOME}:N%${ORACLE_SID}:${ORACLE_HOME}:Y%' /etc/oratab

	cp oracle-db-env.sh /etc/profile.d/oracle-db.sh
	sed -i \
		-e "s%\${ORACLE_USER}%${ORACLE_USER}%g" \
		-e "s%export ORACLE_HOSTNAME=\${ORACLE_SERVER_HOSTNAME}%export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}%g" \
		-e "s%export ORACLE_UNQNAME=\${ORACLE_UNIQUE_NAME}%export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}%g" \
		-e "s%export ORACLE_BASE=\${ORACLE_BASE}%export ORACLE_BASE=${ORACLE_BASE}%g" \
		-e "s%export ORACLE_HOME=\${ORACLE_HOME}%export ORACLE_HOME=${ORACLE_HOME}%g" \
		-e "s%export ORACLE_SID=\${ORACLE_SID}%export ORACLE_SID=${ORACLE_SID}%g" \
		/etc/profile.d/oracle-db.sh
	chmod +x /etc/profile.d/oracle-db.sh

	cp oracle-db-init.sh /etc/init.d/oracle-db
	sed -i \
		-e "s%export ORACLE_HOME=\${ORACLE_HOME}%export ORACLE_HOME=${ORACLE_HOME}%g" \
		-e "s%export ORACLE_USER=\${ORACLE_USER}%export ORACLE_USER=${ORACLE_USER}%g" \
		-e "s%export ORACLE_HOSTNAME=\${ORACLE_SERVER_HOSTNAME}%export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}%g" \
		-e "s%export ORACLE_UNQNAME=\${ORACLE_UNIQUE_NAME}%export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}%g" \
		-e "s%export ORACLE_SID=\${ORACLE_SID}%export ORACLE_SID=${ORACLE_SID}%g" \
		/etc/init.d/oracle-db
	chmod +x /etc/init.d/oracle-db
	chkconfig --add oracle-db
	chkconfig oracle-db on

	cp oracle-db-start.sh /home/${ORACLE_USER}/start-oracle-db.sh
	sed -i \
		-e "s%export ORACLE_HOME=\${ORACLE_HOME}%export ORACLE_HOME=${ORACLE_HOME}%g" \
		-e "s%export ORACLE_USER=\${ORACLE_USER}%export ORACLE_USER=${ORACLE_USER}%g" \
		-e "s%export ORACLE_HOSTNAME=\${ORACLE_SERVER_HOSTNAME}%export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}%g" \
		-e "s%export ORACLE_UNQNAME=\${ORACLE_UNIQUE_NAME}%export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}%g" \
		-e "s%export ORACLE_SID=\${ORACLE_SID}%export ORACLE_SID=${ORACLE_SID}%g" \
		/home/${ORACLE_USER}/start-oracle-db.sh
	chown ${ORACLE_USER} /home/${ORACLE_USER}/start-oracle-db.sh
	chmod +x /home/${ORACLE_USER}/start-oracle-db.sh

	cp oracle-db-stop.sh /home/${ORACLE_USER}/stop-oracle-db.sh
	sed -i \
		-e "s%export ORACLE_HOME=\${ORACLE_HOME}%export ORACLE_HOME=${ORACLE_HOME}%g" \
		-e "s%export ORACLE_USER=\${ORACLE_USER}%export ORACLE_USER=${ORACLE_USER}%g" \
		-e "s%export ORACLE_HOSTNAME=\${ORACLE_SERVER_HOSTNAME}%export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}%g" \
		-e "s%export ORACLE_UNQNAME=\${ORACLE_UNIQUE_NAME}%export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}%g" \
		-e "s%export ORACLE_SID=\${ORACLE_SID}%export ORACLE_SID=${ORACLE_SID}%g" \
		/home/${ORACLE_USER}/stop-oracle-db.sh
	chown ${ORACLE_USER} /home/${ORACLE_USER}/stop-oracle-db.sh
	chmod +x /home/${ORACLE_USER}/stop-oracle-db.sh

	echo "Completed installation of management scripts"
}

# Oracle makes it difficult to get their software. This is a very bad thing.
if [[ ! -f linuxamd64_12102_database_1of2.zip -o ! -f linuxamd64_12102_database_2of2.zip ]]; then
	println "Please download the Oracle 12c installation files from the following URL:"
	println "http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_1of2.zip"
	println "http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_2of2.zip"
fi

export -f preinstall
export -f install
export -f rootscripts
export -f postinstall
export -f install_scripts


execute_as_root preinstall
execute_as_user ${ORACLE_USER} install
execute_as_root rootscripts
execute_as_user ${ORACLE_USER} postinstall
execute_as_root install_scripts
echo "Oracle DB Installation Complete"

