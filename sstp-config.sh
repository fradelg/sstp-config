#!/bin/bash
# $1 connection_name
# $2 username
# $3 password
# $4 server
# $5 path_to_cert

sudo cp $5 /usr/local/share/ca-certificates/$1.pem
sudo update-ca-certificates

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' sstp-client | grep "install ok installed")
echo "Checking for sstp-client: $PKG_OK"
if [ "" == "$PKG_OK" ]; then
  echo "Installing sstp-client."
  sudo add-apt-repository ppa:eivnaes/network-manager-sstp
  sudo apt-get update
  sudo apt-get --force-yes --yes install sstp-client
fi

echo "$2 $1 '$3' *" | sudo tee -a /etc/ppp/chap-secrets

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

echo "!/bin/bash
NET=\`echo \$4 | cut -d . -f 1,2,3\`
route add -net \$NET.0/24 dev \$1" | sudo tee /etc/ppp/ip-up.d/0route
