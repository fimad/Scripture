#!/bin/bash
################################################################################
# Creates an adhoc wifi network with the specified name and password. The
# default is wep encryption (iPhones don't seem to support wpa adhoc
# networks which is what I mainly use this for).
################################################################################

#Ask the user what's up
if [ "$#" > "1" ]; then
  network="$1"
  password="$2"
  scheme="$3"
else
  echo "usage: $0 essid password [wpa*]"
  echo ""
  echo "*Default encryption is wep"
  exit
fi

################################################################################
# Settings
################################################################################

wifi_ip="192.168.2.1/24"
wifi_dev="wlan0"
net_dev="eth0"


################################################################################
# Methods for setting up wifi networks
################################################################################

function init_wep {
  sudo iwconfig "$wifi_dev" channel 8 essid "$network" mode ad-hoc
  sudo iwconfig "$wifi_dev" key s:"$password"
}

function init_wpa {
#make a wpa.conf file so we can get some actual security going
  wpa_conf=`sudo mktemp`

#make it so noone can read our secret conf file
  sudo chmod ag-rwx "$wpa_conf"
  sudo chmod u+rwx "$wpa_conf"

#write the config file
  sudo bash -c 'cat > "'"$wpa_conf"'" << EOF
ap_scan=2
network={
  ssid="'"$network"'"
  mode=1 #we want adhoc
  frequency=2447 #channel 8 is hardcoded
  proto=WPA
  key_mgmt=WPA-NONE
  pairwise=NONE
  group=TKIP
  psk="'"$password"'"
}
EOF'

#start network
  sudo wpa_supplicant -c"$wpa_conf" -i"$wifi_dev" -Dwext -B &

#it takes wpa_supplicant a moment to start up, so wait a sec before cleaning up
  sleep 1s
  sudo rm "$wpa_conf"
}


################################################################################
# Main
################################################################################

#tear down existing networks
sudo ip link set "$wifi_dev" down
sudo ip addr flush dev "$wifi_dev"

#probably not the most portable, but kill all prior wpa-wifi setups
sudo killall wpa_supplicant 2> /dev/null

#set up the network
if [ "$scheme" == "wpa" ]; then
  init_wpa
else
  init_wep
fi

#set the ip
sudo ip link set "$wifi_dev" up
sudo ip addr add "$wifi_ip" dev "$wifi_dev"

#share our internet with those less fortunate
sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o "$net_dev" -j MASQUERADE
sudo iptables -A FORWARD -i "$net_dev" -o "$wifi_dev" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i "$wifi_dev" -o "$net_dev" -j ACCEPT
