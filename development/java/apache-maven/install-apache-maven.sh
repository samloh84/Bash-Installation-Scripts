#!/bin/bash

export M2_ROOT=/opt/apache-maven
export M2_HOME=${M2_ROOT}/apache-maven-3.3.3
export M2_INSTALL_ZIP=apache-maven-3.3.3-bin.tar.gz
export M2_INSTALL_ZIP_URL=http://www.us.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
export M2_ENV_SCRIPT=/etc/profile.d/maven.sh

function execute_as_root {
	if [[ "$(whoami)" != "root" ]]; then
		su -c $@
	else
		$@
	fi
}

function install_maven {
    if [[ ! -f ${M2_INSTALL_ZIP} ]]; then
        wget ${M2_INSTALL_ZIP_URL}
    fi

	mkdir -p ${M2_ROOT} && \
	echo "Created Directory ${M2_ROOT}"

	tar -xzf ${M2_INSTALL_ZIP} --directory ${M2_ROOT} && \
	echo "Extracted ${M2_INSTALL_ZIP} to ${M2_ROOT}"

	cp apache-maven-env.sh /etc/profile.d/maven.sh
	sed -i -e "s%export M2_HOME=\${M2_HOME}%export M2_HOME=${M2_HOME}%g" /etc/profile.d/maven.sh

	echo "Installed Environment Variables Script ${M2_ENV_SCRIPT}"

	M2_VERSION=`${M2_HOME}/bin/mvn --version 2>&1 | gawk 'match($0, /Apache +Maven +(.*) +\(.*\)/, m) { print m[1] }'`
	echo "Installed Apache Maven ${M2_VERSION}"
}

export -f install_maven

execute_as_root install_maven
