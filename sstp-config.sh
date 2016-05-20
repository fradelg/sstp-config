#!/bin/bash
# $1 connection_name
# $2 username
# $3 password
# $4 server
# $5 path_to_cert

echo "Updating certification authorities ..."
sudo cp $5 /usr/local/share/ca-certificates/$1.pem
sudo update-ca-certificates

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' sstp-client | grep "install ok installed")
echo "Checking for sstp-client ... $PKG_OK"
if [ "" == "$PKG_OK" ]; then
  echo "Installing sstp-client using PPA ..."
  sudo apt-get --yes install software-properties-common
  sudo add-apt-repository ppa:eivnaes/network-manager-sstp
  sudo apt-get update
  sudo apt-get --yes install sstp-client
fi

echo "Adding user credential to chap-secrets ..."
echo "$2 $1 '$3' *" | sudo tee -a /etc/ppp/chap-secrets

echo "Adding new connection config to PPP peers ..."
echo "remotename      $1
linkname        $1
ipparam         $1
pty             "sstpc --save-server-route --ipparam $1 --nolaunchpppd $4"
name            $2
plugin          sstp-pppd-plugin.so
sstp-sock       /var/run/sstpc/sstpc-$1
usepeerdns
refuse-eap
noauth
defaultroute
debug
file /etc/ppp/options.pptp" | sudo tee /etc/ppp/peers/$1

echo "Updating ip-up scripts to add route when connecting ..."
echo "!/bin/bash
NET=\`echo \$4 | cut -d . -f 1,2,3\`
route add -net \$NET.0/24 dev \$1" | sudo tee /etc/ppp/ip-up.d/0route
