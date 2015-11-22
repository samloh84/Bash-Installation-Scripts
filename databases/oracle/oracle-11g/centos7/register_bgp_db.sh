#!/bin/bash -x

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export ORACLE_USER=oracle
export ORACLE_USER_PASSWORD=Pass1234

export SYS_PASSWORD=${ORACLE_USER_PASSWORD}
export SYSTEM_PASSWORD=${ORACLE_USER_PASSWORD}
export SYSMAN_PASSWORD=${ORACLE_USER_PASSWORD}
export DB_SNMP_PASSWORD=${ORACLE_USER_PASSWORD}

export DATABASES_TO_CREATE=APPLICATION

function execute_as_user {
	USERNAME=${1}
	shift
	if [[ "$(whoami)" != "${USERNAME}" ]]; then
		su ${USERNAME} -c $@
	else
		$@
	fi
}

function register {
	DB=${0}
	cp dbca.rsp /home/${ORACLE_USER}/database/${DB}_dbca.rsp
	ORACLE_SID=${DB}
	ORACLE_UNIQUE_NAME=${DB}
	env | grep ORACLE
	sed -i \
			-e "s%\${DB_SNMP_PASSWORD}%${DB_SNMP_PASSWORD}%g" \
			-e "s%\${ORACLE_SID}%${ORACLE_SID}%g" \
			-e "s%\${ORACLE_UNIQUE_NAME}%${ORACLE_UNIQUE_NAME}%g" \
			-e "s%\${SYS_PASSWORD}%${SYS_PASSWORD}%g" \
			-e "s%\${SYSMAN_PASSWORD}%${SYSMAN_PASSWORD}%g" \
			-e "s%\${SYSTEM_PASSWORD}%${SYSTEM_PASSWORD}%g" \
			/home/${ORACLE_USER}/database/${DB}_dbca.rsp

	echo "Running Oracle Database Configuration Assistant to create ${DB} Database"
	${ORACLE_HOME}/bin/dbca -silent -responsefile /home/${ORACLE_USER}/database/${DB}_dbca.rsp

	export DB_USER = "${DB}_user"
	echo "Creating ${DB} Database user ${DB_USER}"
	export ORACLE_SID=${DB}
	sqlplus /nolog <<-SQLPLUS_EOF
		connect sys/${SYS_PASSWORD} as sysdba
		CREATE USER ${DB_USER} IDENTIFIED BY ${DB_PASSWORD};
		GRANT CREATE TABLE TO ${DB_USER};
		GRANT CREATE SESSION TO ${DB_USER};
		GRANT CREATE VIEW TO ${DB_USER};
		GRANT CREATE SEQUENCE TO ${DB_USER};
		GRANT CONNECT TO ${DB_USER};
		GRANT SELECT ON sys.dba_pending_transactions TO ${DB_USER};
		GRANT SELECT ON sys.pending_trans$ TO ${DB_USER};
		GRANT SELECT ON sys.dba_2pc_pending TO ${DB_USER};
		GRANT EXECUTE ON sys.dbms_xa TO ${DB_USER};
		EXIT;
SQLPLUS_EOF

}


export -f execute_as_user
export -f register

for DB in ${DATABASES_TO_CREATE}; do
	execute_as_user ${ORACLE_USER} register ${DB}
done

