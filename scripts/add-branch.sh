#!/usr/bin/env bash
S=$1;
if [ -z "$S" ]
then
      echo "A Branch is not specified, Skipping addition of branch"
else
      echo "A Branch is specified, Adding Branch $S"
	  sudo rm -rf /temp
	  sudo mkdir -p /temp
          sudo git clone -b $S https://github.com/prominic/domino4wine-Vagrant-SikuliX.git /temp
          cp -r /temp/conf/* /vagrant
fi
