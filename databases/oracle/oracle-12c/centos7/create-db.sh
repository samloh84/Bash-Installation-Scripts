#!/bin/bash

export ORACLE_USER=oracle
export SYS_PASSWORD=Pass1234

export DB_HOSTNAME=oracledb
export DB_PORT=1521
export DB_SID=USER_DB
export SYS_PASSWORD=${SYS_PASSWORD}
export SYSTEM_PASSWORD=${SYS_PASSWORD}
export DB_USER=USER_DB
export DB_PASSWORD=USER_DB01

function setup_db {
	source /home/${ORACLE_USER}/.bash_profile

	echo "Creating Database ${DB_SID}"
	dbca -silent -createDatabase -templatename General_Purpose.dbc -gdbName ${DB_SID} -sid ${DB_SID} -sysPassword ${SYS_PASSWORD} -systemPassword ${SYSTEM_PASSWORD} -characterset AL32UTF8

	echo "Creating Database user ${DB_USER}"
	export ORACLE_SID=${DB_SID}
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

export -f setup_db
su ${ORACLE_USER} -c setup_db
