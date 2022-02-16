# Docker Image with MAIAN (Smartbugs fork)

# Pull base image
FROM smartbugs/base-image:2.0.0

# Install Python 3.6 and build tools
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
RUN \
  apt-get install -y build-essential software-properties-common libssl-dev wget git z3 psmisc lsof

# Upgrade pip
RUN pip install --upgrade pip

# Install GETH version 1.10.14 
RUN wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.14-11a3a350.tar.gz
RUN tar zxvf geth-linux-amd64-1.10.14-11a3a350.tar.gz
RUN cp geth-linux-amd64-1.10.14-11a3a350/geth /usr/local/bin
RUN chmod +x /usr/local/bin/geth

# Install MAIAN from GitHub
RUN git clone https://github.com/smartbugs/MAIAN

# Checkout specific version of MAIAN's repository and install requirements
RUN cd /MAIAN; git checkout 8bf16ac; pip3 install -r requirements-3.8.txt

# Script that extracts contract names 
ENV LC_ALL C.UTF-8  
RUN pip3 install solidity_parser
COPY scripts/printContractNames.py printContractNames.py

# Scripts that Smartbugs calls
COPY scripts/run_maian_solidity.sh run_maian_solidity.sh
COPY scripts/run_maian_bytecode.sh run_maian_bytecode.sh
RUN chmod +x printContractNames.py run_maian_solidity.sh run_maian_bytecode.sh 

# Allow insecure unlock
#RUN sed -si "s/'geth'/'geth','--allow-insecure-unlock'/g" /MAIAN/tool/blockchain.py
