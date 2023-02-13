#!/bin/bash

echo Set up variables
username=344586
password=SomePassword
host=ny7.ms.telocall.com
port=5060
users=(101)
did=7188661234
server=ny7.ms.telocall.com
servername=MSTelocall
context=from-telocall
realm=telocall

echo Update package list
apt update   

echo Install dependencies
sudo apt-get update && sudo apt-get install -y build-essential libxml2-dev libsqlite3-dev libjansson-dev uuid-dev libedit-dev patch fail2ban iptables libmariadb-dev libjansson-dev gcc make libedit-dev libssl-dev libncurses5-dev libnewt-dev bzip2 libxml2-dev uuid-dev g++ libsqlite3-dev libcurl4-openssl-dev libspeex-dev libspeexdsp-dev libvorbis-dev libpq-dev libmysqlclient-dev libopus-dev libtiff-dev doxygen libiksemel-dev liblua5.2-dev libgsm1-dev
# apt install -y build-essential  libjansson-dev libedit-dev libssl-dev libncurses5-dev libnewt-dev libxml2-dev uuid-dev
#Check fail2ban and iptables if it workes correctly
apt update && apt upgrade
 

sudo apt-get install libjansson-dev

echo Download and extract Asterisk source code
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
tar xvfz asterisk-20-current.tar.gz
cd asterisk-20.1.0

echo Compile and install Asterisk
echo Starting ./Configure && ./configure
echo Making menu select
menuselect/menuselect --enable res_http_websocket --enable res_srtp --enable res_crypto --enable res_stun_monitor --enable chan_sip --enable res_http_websocket --enable format_opus --enable res_opus --enable app_opus --enable CORE-SOUNDS-EN-GSM
echo make && make
echo make install && make install
echo make basic PBX && make basic-pbx
#make progdocs
echo make config && make config

echo Create user and group for Asterisk
echo groupadd asterisk
groupadd asterisk
echo useradd -r -d /var/lib/asterisk -g asterisk asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk

echo Seting up Fail2Ban
echo Creating files asterisk.conf 
;touch /etc/fail2ban/filter.d/asterisk.conf
touch /etc/fail2ban/jail.d/asterisk.conf


echo /etc/fail2ban/filter.d/asterisk.conf
;cat > /etc/fail2ban/filter.d/asterisk.conf << EOF
;[Definition]
;failregex = SECURITY.* SecurityEvent="ChallengeResponseFailed"
;ignoreregex =
;EOF

echo /etc/fail2ban/jail.d/asterisk.conf
cat > /etc/fail2ban/jail.d/asterisk.conf  << EOF
[asterisk]
enabled = true
port = 5060,5061
protocol = udp,tcp
filter = asterisk
logpath = /var/log/asterisk/full
maxretry = 5
bantime = 600
banaction = iptables-multiport
EOF



echo Set up configuration files for PJSIP
cat > /etc/asterisk/pjsip.conf << EOF
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0

[$servername]
type = endpoint
transport = transport-udp
context = $context
disallow = all
allow = ulaw
; allow=g729
from_user = $username
auth = $servername
outbound_auth = $servername
aors = $servername
; NAT parameters:
rtp_symmetric = yes
rewrite_contact = yes
send_rpid = yes
;force_rport=yes
;use_avpf=yes 
;direct_media=no

[$servername]
type = registration
transport = transport-udp
outbound_auth = $servername
client_uri = sip:$username@$host:$port
server_uri = sip:$host:$port  

[$servername]
type=auth
auth_type=userpass
username=$username
password=$password

[$servername]
type=aor
contact=sip:$username@$host:$port 

[$servername]
type = identify
endpoint = $servername
match = $host:$port  

[$context]
type=endpoint
context=$context
transport=transport-udp
aors=$servername
auth=$servername
EOF


echo Create configuration files for SIP
cat > /etc/asterisk/sip.conf << EOF
[general]
context=$context
allowguest=no
allowoverlap=no
udpbindaddr=0.0.0.0
tcpenable=no
transport=udp
srvlookup=yes
subscribecontext=default
EOF



for user in "${users[@]}"
do
    cat >> /etc/asterisk/sip.conf << EOF
[$user]
type=friend
username=$user
secret=password
host=dynamic
context=$context
disallow=all
allow=ulaw
EOF
done

echo Add context for custom extensions
cat >> /etc/asterisk/extensions.conf << EOF
[general]
;static=yes
;writeprotect=no
;clearglobalvars=no

[global]
#include extensions.d/global/*.conf

[tenets]
#include extensions.d/tenants/*/*.conf

[failover]
#include extensions.d/failover/*.conf
EOF

echo Create directories for tenant extensions and voicemail
mkdir -p /etc/asterisk/extensions.d/tenants
mkdir -p /etc/asterisk/extensions.d/global
mkdir -p /etc/asterisk/extensions.d/failover
mkdir -p /etc/asterisk/extensions.d/tenants/$realm
mkdir -p /var/spool/asterisk/voicemail/default

echo Create configuration file for custom extensions
touch /etc/asterisk/extensions.d/failover/outbound.conf
touch /etc/asterisk/extensions.d/tenants/$realm/$realm.values
touch /etc/asterisk/extensions.d/tenants/$realm/extensions.conf
touch /etc/asterisk/extensions.d/tenants/$realm/features.conf
touch /etc/asterisk/extensions.d/tenants/$realm/incoming.conf
touch /etc/asterisk/extensions.d/tenants/$realm/users.conf
touch /etc/asterisk/extensions.d/tenants/$realm/ivr.conf
touch /etc/asterisk/extensions.d/tenants/$realm/outgoing.conf
touch /etc/asterisk/extensions.d/tenants/$realm/queues.conf
touch /etc/asterisk/extensions.d/tenants/$realm/voicemail.conf



touch /etc/asterisk/extensions.d/tenants/$realm/$realm.conf

echo Add custom extensions to the extensions file
for user in "${users[@]}"
do
    cat >> /etc/asterisk/extensions.d/tenants/$realm/users.conf << EOF
exten => $user,1,Dial(SIP/$user,20)
exten => $user,2,Voicemail($user@default,u)
exten => $user,3,Hangup()
EOF
done

 
sudo systemctl restart fail2ban
systemctl restart asterisk

echo Completed. 
