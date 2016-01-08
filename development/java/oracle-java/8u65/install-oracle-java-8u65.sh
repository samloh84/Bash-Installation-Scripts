#!/bin/bash

export JAVA_ROOT=/opt/java
export JAVA_INSTALL_ZIP=jdk-8u65-linux-x64.tar.gz
export JAVA_INSTALL_ZIP_URL=http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz
export JAVA_SECURITY_INSTALL_ZIP=jce_policy-8.zip
export JAVA_SECURITY_INSTALL_ZIP_URL=http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
export JAVA_HOME=${JAVA_ROOT}/jdk1.8.0_65
export JRE_HOME=${JAVA_HOME}/jre
export TEMP_JCE_DIR=/tmp/jce_policy
export JAVA_ENV_SCRIPT=/etc/profile.d/java.sh

function execute_as_root {
	if [[ "$(whoami)" != "root" ]]; then
		su -c $@
	else
		$@
	fi
}

function install_java {
    if [[ ! -f ${JAVA_INSTALL_ZIP} ]]; then
        wget --progress=bar:force --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
        ${JAVA_INSTALL_ZIP_URL}
    fi

    if [[ ! -f ${JAVA_SECURITY_INSTALL_ZIP} ]]; then
        wget --progress=bar:force --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
        ${JAVA_SECURITY_INSTALL_ZIP_URL}
    fi

	mkdir -p ${JAVA_ROOT} && \
	echo "Created Directory ${JAVA_ROOT}"

	tar -xzf ${JAVA_INSTALL_ZIP} --directory ${JAVA_ROOT} && \
	echo "Extracted ${JAVA_INSTALL_ZIP} to ${JAVA_ROOT}"

	unzip -o -qq ${JAVA_SECURITY_INSTALL_ZIP} -d ${TEMP_JCE_DIR} && \
	echo "Extracted ${JAVA_SECURITY_INSTALL_ZIP} to ${TEMP_JCE_DIR}"

	mv "$(find ${TEMP_JCE_DIR} -name local_policy.jar)" ${JRE_HOME}/lib/local_policy.jar && \
	mv "$(find ${TEMP_JCE_DIR} -name US_export_policy.jar)" ${JRE_HOME}/lib/US_export_policy.jar && \
	rm -rf ${TEMP_JCE_DIR} && \
	echo "Installed Java Unlimited Cryptography Extension Policies"


	cp java-env.sh ${JAVA_ENV_SCRIPT}
	sed -i -e "s%export JAVA_HOME=\${JAVA_HOME}%export JAVA_HOME=${JAVA_HOME}%g" ${JAVA_ENV_SCRIPT}

	echo "Installed Environment Variables Script ${JAVA_ENV_SCRIPT}"

	JAVA_VERSION=`${JAVA_HOME}/bin/java -version 2>&1 | gawk 'match($0, /java version "(.*)"/, m) { print m[1] }'`
	echo "Installed Java ${JAVA_VERSION}"

}

export -f install_java

execute_as_root install_java
