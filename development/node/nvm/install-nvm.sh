#!/bin/bash

export NODE_VERSION=v5.0.0

function command_exists {
	command -v $1 &> /dev/null
}

function install_brew {
	echo "Installing brew"
	sudo ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function detect_package_manager {
	OS_NAME=`uname`
	if [[ ${OS_NAME} == "Darwin"* ]]; then
		if ! command_exists brew ; then
			install_brew
		fi
		PACKAGE_MANAGER="brew"
	elif [[ ${OS_NAME} == "Linux"* ]]; then
		if command_exists yum; then
			PACKAGE_MANAGER="yum"
		elif command_exists apt-get; then
			PACKAGE_MANAGER="apt-get"
		fi
	fi
	echo "Package Manager is ${PACKAGE_MANAGER}"
}


function prep {
	if [[ -n "$(type -t ${FUNCNAME[0]}_${PACKAGE_MANAGER})" ]]; then
		${FUNCNAME[0]}_${PACKAGE_MANAGER}
	else
		echo "This system is not supported for ${FUNCNAME[0]}."
		exit 1
	fi
}

function prep_apt-get {
	sudo apt-get update -y && apt-get install -y build-essential git
}

function prep_yum {
	sudo yum groupinstall -y "Development tools" && yum install -y git
}

function prep_brew {
	sudo brew install git
}

function install_nvm_brew {
	echo "Installing Node Version Manager using ${PACKAGE_MANAGER}"
	brew install nvm
	mkdir ~/.nvm
	cp $(brew --prefix nvm)/nvm-exec ~/.nvm/

	cat <<-EOF >> ~/.bash_profile
		export NVM_DIR=~/.nvm
		source $(brew --prefix nvm)/nvm.sh
EOF
}

function install_nvm_curl {
	echo "Installing Node Version Manager from online bash script"
	sudo curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | bash
}

function install_nvm {
	[[ "${PACKAGE_MANAGER}" == "brew" ]] && source $(brew --prefix nvm)/nvm.sh && echo "NVM loaded" || [[ -f ~/.nvm/nvm.sh ]] && source ~/.nvm/nvm.sh && echo "NVM loaded"
	if command_exists nvm ; then
		return 0
	fi

	if [[ ${OS_NAME} == "Darwin"* ]]; then
		install_nvm_brew
	else
		install_nvm_curl
	fi
}

function install_nvm_node {
	echo "Installing Node ${NODE_VERSION} using Node Version Manager"

	export NVM_DIR=~/.nvm
	[[ "${PACKAGE_MANAGER}" == "brew" ]] && source $(brew --prefix nvm)/nvm.sh && echo "NVM loaded" || [[ -f ~/.nvm/nvm.sh ]] && source ~/.nvm/nvm.sh && echo "NVM loaded"

	nvm install ${NODE_VERSION}
	nvm alias default ${NODE_VERSION}
}

export -f execute_as_root
export -f command_exists
export -f install_brew
export -f detect_package_manager
export -f prep
export -f prep_apt-get
export -f prep_yum
export -f prep_brew
export -f install_nvm_brew
export -f install_nvm_curl
export -f install_nvm
export -f install_nvm_node

detect_package_manager
prep

install_nvm
install_nvm_node
