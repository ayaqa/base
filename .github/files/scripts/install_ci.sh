#!/bin/bash

set -x
sudo apt-get update
sudo apt-get install curl
sudo apt-get install apt-transport-https
sudo apt-get install ca-certificates
sudo apt-get install software-properties-common
sudo apt-get install unzip
sudo apt-get install make
sudo apt-get install jq