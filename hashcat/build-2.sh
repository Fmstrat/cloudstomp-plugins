#!/bin/bash

HASHCAT=5.1.0
NVIDIA=410.79

sleep 5
wget https://crackstation.net/files/crackstation.txt.gz
wget http://us.download.nvidia.com/tesla/${NVIDIA}/NVIDIA-Linux-x86_64-${NVIDIA}.run
sudo /bin/bash NVIDIA-Linux-x86_64-${NVIDIA}.run -q -a -n -s
sudo nvidia-smi
rm NVIDIA-Linux-x86_64-${NVIDIA}.run
wget https://hashcat.net/files/hashcat-${HASHCAT}.7z
7za x hashcat-${HASHCAT}.7z
rm hashcat-${HASHCAT}.7z
ln -s hashcat-${HASHCAT} hashcat
