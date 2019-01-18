#!/bin/bash

# Before a build script runs, cloudstomp AWS credentials are stored in `~/.aws` 

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get install -y screen python-pip gocryptfs
sudo apt-get clean
pip install awscli
