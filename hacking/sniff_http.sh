#!/bin/bash
#catches http conversations

PREFIX="pref"
INT="mon0"
DELAY="5m"

pull_http ()
{
  tcpdump -r $1 -w $1.http 'tcp and port 80' > /dev/null 2> /dev/null
  echo "" > $1
}

while [ 1 ]; do

  echo "Listening..."

  airodump-ng -w $PREFIX --output-format pcap $INT 2> /dev/null &
  airid=$!
  sleep $DELAY
  kill $airid
  
#get the name of the cap file
  echo "Prunning..."
  cap=`ls | egrep '\.cap$' | tail -1`
  pull_http $cap &

done
