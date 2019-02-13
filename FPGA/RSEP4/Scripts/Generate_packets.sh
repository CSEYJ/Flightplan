#!/bin/bash -e

PACKET_COUNT=1000
PAYLOAD_LENGTH='1024'

GENERATOR=../../../Utilities/PacketGenerator/PacketGenerator.py

$GENERATOR -t Packet.user -n $PACKET_COUNT -l $PAYLOAD_LENGTH

for i in $(seq $PACKET_COUNT)
do
  echo "0"
done > Tuple.user

