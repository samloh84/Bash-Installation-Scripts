#!/bin/bash
# chkconfig: 345 99 10
# description: Oracle Database auto start-stop script.

export TMP=/tmp
export TMPDIR=${TMP}

export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_USER=${ORACLE_USER}
export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}
export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}
export ORACLE_SID=${ORACLE_SID}

export PATH=${PATH}:${ORACLE_HOME}/bin

function start_oracle_database {
	ORAENV_ASK=NO
	. oraenv
	ORAENV_ASK=YES

	# Start Listener
	lsnrctl start

	# Start Database
	sqlplus / as sysdba <<-SQLPLUS_COMMANDS
		STARTUP;
		EXIT;
	SQLPLUS_COMMANDS
}

function stop_oracle_database {
	ORAENV_ASK=NO
	. oraenv
	ORAENV_ASK=YES

	# Start Database
	sqlplus / as sysdba <<-SQLPLUS_COMMANDS
		SHUTDOWN IMMEDIATE;
		EXIT;
	SQLPLUS_COMMANDS

	# Stop Listener
	lsnrctl stop
}

function execute_as_user {
	USERNAME=${1}
	shift
	if [[ "$(whoami)" != "${USERNAME}" ]]; then
		su ${USERNAME} -c $@
	fi
}

function main {
	#set -x
	case "${1}" in
		'start')
			su ${ORACLE_USER} -c start_oracle_database &> /home/${ORACLE_USER}/oracle-database.log &
			touch /var/lock/subsys/dbora
		;;
		'stop')
			su ${ORACLE_USER} -c stop_oracle_database &> /home/${ORACLE_USER}/oracle-database.log &
			rm -f /var/lock/subsys/dbora
		;;
		*)
			echo "$0 (start|stop)"
		;;

	esac
	#set +x
}

export -f start_oracle_database
export -f stop_oracle_database
export -f main

execute_as_user ${ORACLE_USER} main ${1}
