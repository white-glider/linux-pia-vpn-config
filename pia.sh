#!/bin/bash
 
# Get username
echo -n "Enter your PIA VPN username: "
read PIAUSR
 
# Download servers info
wget -q -O - https://privateinternetaccess.com/vpninfo/servers?version=24 | head -1 > /tmp/servers-$$.json
 
# Parse servers info
cat /tmp/servers-$$.json | python -c '\
import json,sys;\
d = json.load(sys.stdin);\
print "\n".join([d[k]["name"]+":"+d[k]["dns"] for k in d.keys() if k != "info"])' > /tmp/servers-$$.txt
 
# Install PIA CA's certificate
wget -q -O /tmp/openvpn-$$.zip https://www.privateinternetaccess.com/openvpn/openvpn.zip
unzip -pa /tmp/openvpn-$$.zip ca.rsa.2048.crt > /etc/openvpn/ca.crt
 
# Write config files
rm -f /etc/NetworkManager/system-connections/PIA\ -\ *
while read server; do
  name="PIA - `echo $server | cut -d: -f1`"
  cat << EOF > "/etc/NetworkManager/system-connections/$name"
[connection]
id=$name
uuid=`uuidgen`
type=vpn
autoconnect=false
 
[vpn]
service-type=org.freedesktop.NetworkManager.openvpn
username=$PIAUSR
dev=tun
comp-lzo=yes
remote=`echo $server | cut -d: -f2`
port=1198
cipher=AES-128-CBC
reneg-seconds=0
connection-type=password
password-flags=1
ca=/etc/openvpn/ca.crt
remote-cert-tls=server
 
[ipv4]
method=auto
EOF
  chmod 600 "/etc/NetworkManager/system-connections/$name"
done < /tmp/servers-$$.txt
 
# Tidy up
rm /tmp/servers-$$.json /tmp/servers-$$.txt /tmp/openvpn-$$.zip
 
echo Done
