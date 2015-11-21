#!/bin/bash

#set -x

RUBY_VERSION=2.2.0

# Install Ruby Version Manager
function install_rvm {
    test -f /etc/profile.d/rvm.sh && source /etc/profile.d/rvm.sh && echo "RVM Loaded" || test -f ~/.rvm/rvm.sh && source ~/.rvm/rvm.sh && echo "RVM Loaded" || test -f ~/.rvm/scripts/rvm && source ~/.rvm/scripts/rvm && echo "RVM Loaded"
    if command_exists rvm ; then
        return 0
    fi

    echo "Installing Ruby Version Manager using online bash script"
    OS_NAME=`uname`
    if [[ ${OS_NAME} == "Linux"* ]]; then
        sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
        curl -sSL https://get.rvm.io | sudo bash -s stable
        sudo usermod -a -G rvm ${CURRENT_USER}
    elif [[ ${OS_NAME} == "Darwin"* ]]; then
        curl -sSL https://get.rvm.io | bash -s stable
    fi
}


function install_rvm_ruby {
    echo "Installing Ruby ${RUBY_VERSION} using Ruby Version Manager"

    sudo su ${CURRENT_USER} <<-EOF
        test -f /etc/profile.d/rvm.sh && source /etc/profile.d/rvm.sh && echo "RVM Loaded" || test -f ~/.rvm/rvm.sh && source ~/.rvm/rvm.sh && echo "RVM Loaded" || test -f ~/.rvm/scripts/rvm && source ~/.rvm/scripts/rvm && echo "RVM Loaded"
        rvm install ${RUBY_VERSION}
        rvm use ${RUBY_VERSION} --default
EOF
}


function prep_apt-get {
	sudo apt-get update -y
	sudo apt-get install -y git
}

function prep_yum {
	sudo yum groupinstall -y "Development tools"
	sudo yum install -y git
}

function prep_brew {
	brew install git
}

function prep {
	if [[ -n "$(type -t ${FUNCNAME[0]}_${PACKAGE_MANAGER})" ]]; then
		${FUNCNAME[0]}_${PACKAGE_MANAGER}
	else
		echo "This system is not supported for ${FUNCNAME[0]}."
		exit 1
	fi
}


function install_brew {
    echo "Installing brew"
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function command_exists {
    command -v $1 &> /dev/null
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

detect_package_manager
prep

install_rvm
install_rvm_ruby

