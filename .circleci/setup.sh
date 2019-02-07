#!/bin/bash

singularity_version="${singularity_version:-3.0.2}"
GO_VERSION=1.11.5

sudo apt-get update && \
     sudo apt-get install -y wget git jq 

sudo sed -i -e 's/^Defaults\tsecure_path.*$//' /etc/sudoers


# sregistry ####################################################################

which sregistry &> /dev/null

if [ $? -eq 0 ]; then
    echo "sregistry is installed."
else
    echo "Python Version:"
    python --version
    pip install sregistry[all]
    sregistry_version=$(sregistry version)
    echo "sregistry Version: ${sregistry_version}"
fi


# singularity ##################################################################

which singularity &> /dev/null

if [ $? -eq 0 ]; then
    echo "Singularity is installed."
    export GOPATH=/go
    export PATH=$PATH:/usr/local/go/bin

else

    sudo apt-get install -y build-essential \
                            squashfs-tools \
                            libtool \
                            uuid-dev \
                            libssl-dev \
                            libgpgme11-dev \
                            libseccomp-dev \
                            pkg-config

    # Install GoLang 
    wget https://dl.google.com/go/go${GO_VERSION}.src.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.src.tar.gz 

    export PATH=$PATH:/usr/local/go/bin && \
        sudo mkdir -p /go && \
        sudo chmod -R 7777 /go

    export GOPATH=/go && \
        go get -u github.com/golang/dep/cmd/dep && \
        mkdir -p ${GOPATH}/src/github.com/sylabs && \
        cd ${GOPATH}/src/github.com/sylabs && \
        wget https://github.com/sylabs/singularity/releases/download/v${singularity_version}/singularity-${singularity_version}.tar.gz && \
        tar -xzvf singularity-${singularity_version}.tar.gz && \
        cd singularity && \
        ./mconfig -p /usr/local && \
        make -C builddir && \
        sudo make -C builddir install
fi
