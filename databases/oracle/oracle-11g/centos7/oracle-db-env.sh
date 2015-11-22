#!/bin/bash

if [[ "$(whoami)" == "${ORACLE_USER}" || "$(whoami)" == "root" ]]; then
	export TMP=/tmp
	export TMPDIR=${TMP}

	export ORACLE_HOSTNAME=${ORACLE_SERVER_HOSTNAME}
	export ORACLE_UNQNAME=${ORACLE_UNIQUE_NAME}
	export ORACLE_BASE=${ORACLE_BASE}
	export ORACLE_HOME=${ORACLE_HOME}
	export ORACLE_SID=${ORACLE_SID}
	export TNS_ADMIN=${ORACLE_HOME}/network/admin

	export PATH=${PATH}:${ORACLE_HOME}/bin

	export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/lib:/usr/lib
	export CLASSPATH=${ORACLE_HOME}/jlib:${ORACLE_HOME}/rdbms/jlib
fi
