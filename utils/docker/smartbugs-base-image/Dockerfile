# Smartbugs Base Docker Image

# Pull base image
FROM ubuntu:20.04

# Update packages, install wget and Python
RUN apt update
#RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends tzdata
RUN apt install -y wget python3-pip

# Update pip
RUN pip install --upgrade pip

# Install solc-select
# TODO: create our own fork of solc-select?
RUN pip3 install solc-select

# Install all versions available through solc-select
RUN for VERSION in $(solc-select install | grep -e "^[0-9]"); do solc-select install $VERSION; done

# Set default version to latest version on 2021/12/17
RUN solc-select use 0.8.10
