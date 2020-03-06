#!/bin/bash
# Nik Sultana, UPenn, July 2019

source config.sh

CMD=GETPOWER

for IDX in ${RANGE}
do
  IP=`arp -n | grep -i ${MACs[$IDX]} | awk '{ print $1 }'`
  if [ "$IP" == "" ]
  then
    echo "${NAME[$IDX]} (${MACs[$IDX]}): could not find IP address"
    continue
  fi
  echo -en "${NAME[$IDX]} (${IP}): \t"
  RESULT=$(timeout 3 sh wemo_control.sh ${IP} ${PORT[$IDX]} ${CMD})
  if [ "$RESULT" == "" ]
  then
    echo "timeout"
  else
    echo "scale=3; ${RESULT} / 1000" | bc -l
  fi
done