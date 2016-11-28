#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd $DIR;
echo "unpack"
sudo tar xfv dtc.tar.gz;
echo "install dep"
sudo apt install -y flex bison make;
cd dtc;
echo "compile"
sudo make;
sudo make install PREFIX=/usr;
cd ..
sudo rm dtc -r;
echo "install done"
