#!/usr/bin/env bash
# Example script to run networks generated by generate_alv_network.py
# Nik Sultana, UPenn, February 2020
#
# NOTE might need to run this script with "sudo"
#
# FIXME various hardcoded paths

export BMV2_REPO=/home/iped/dcomp/behavioral-model/

HERE=`pwd`

if [ -z "${TOPOLOGY}" ]
then
  #TOPOLOGY=splits/ALV_split1/alv_k=4.yml
  TOPOLOGY=bmv2/topologies/alv_k=4.yml
fi
echo "Using TOPOLOGY=${TOPOLOGY}"

MODES=(interactive selftest demo1 autotest1)

if [ -z "${MODE}" ]
then
  MODE="interactive"
  echo "Setting default MODE. Possible choices: ${MODES[*]}"
fi
if [[ ! " ${MODES[@]} " =~ " ${MODE} " ]]
then
  echo "Unrecognised MODE: $MODE"
  exit 1
fi
echo "Using MODE=${MODE}"

TESTDIR=$HERE/test_output
BASENAME=$(basename $TOPOLOGY .yml)
OUTDIR=$TESTDIR/$BASENAME
PCAP_DUMPS=$OUTDIR/pcap_dump/
LOG_DUMPS=$OUTDIR/log_files/

rm -rf $PCAP_DUMPS $LOG_DUMPS $OUTDIR
mkdir -p $PCAP_DUMPS
mkdir -p $LOG_DUMPS

sudo mn -c 2> $LOG_DUMPS/mininet_clean.err

function interactive {
  sudo -E python bmv2/start_flightplan_mininet.py ${TOPOLOGY} \
          --pcap-dump $PCAP_DUMPS \
          --log $LOG_DUMPS \
          --verbose \
          --showExitStatus \
          --cli
  #        2> $LOG_DUMPS/flightplan_mininet_log.err
}

function demo1 {
  sudo -E python bmv2/start_flightplan_mininet.py ${TOPOLOGY} \
          --pcap-dump $PCAP_DUMPS \
          --log $LOG_DUMPS \
          --verbose \
          --showExitStatus \
     --fg-host-prog "p0h0: ping -c 1 192.0.0.2" \
     --fg-host-prog "p0h0: ping -c 1 192.0.1.2" \
     --fg-host-prog ": /home/nsultana/2/P4Boosters/Wharf/splits/ALV_split1/start.sh" \
     --fg-host-prog "p0h0: ping -c 1 192.0.0.2" \
     --fg-host-prog "p0h0: ping -c 1 192.0.1.2" \
          2> $LOG_DUMPS/flightplan_mininet_log.err
}

# FIXME store in directory containing other files relevant to the test
function autotest1 {
  sudo -E python bmv2/start_flightplan_mininet.py ${TOPOLOGY} \
          --pcap-dump $PCAP_DUMPS \
          --log $LOG_DUMPS \
          --verbose \
          --showExitStatus \
     --fg-host-prog ": /home/nsultana/2/P4Boosters/Wharf/splits/ALV_split1/start.sh" \
     --fg-host-prog "p0h0: ping -c 13 192.0.1.2" \
     --fg-host-prog ": /home/nsultana/2/P4Boosters/Wharf/splits/ALV_split1/step1.sh" \
     --fg-host-prog "p0h0: ping -c 4 192.0.1.2" \
     --fg-host-prog ": /home/nsultana/2/P4Boosters/Wharf/splits/ALV_split1/step2.sh" \
     --fg-host-prog "p0h0: ping -c 4 192.0.1.2" \
     --fg-host-prog ": /home/nsultana/2/P4Boosters/Wharf/splits/ALV_split1/step3.sh" \
          2> $LOG_DUMPS/flightplan_mininet_log.err
}

function selftest {
  sudo -E python bmv2/start_flightplan_mininet.py ${TOPOLOGY} \
          --pcap-dump $PCAP_DUMPS \
          --log $LOG_DUMPS \
          --verbose \
          --showExitStatus \
     --fg-host-prog "p0h0: ping -c 1 192.0.0.2" \
     --fg-host-prog "p0h0: ping -c 1 192.0.0.3" \
     --fg-host-prog "p0h0: ping -c 1 192.0.1.2" \
     --fg-host-prog "p0h0: ping -c 1 192.0.1.3" \
     --fg-host-prog "p0h0: ping -c 1 192.1.0.2" \
     --fg-host-prog "p0h0: ping -c 1 192.1.0.3" \
     --fg-host-prog "p0h0: ping -c 1 192.1.1.2" \
     --fg-host-prog "p0h0: ping -c 1 192.1.1.3" \
     --fg-host-prog "p0h0: ping -c 1 192.2.0.2" \
     --fg-host-prog "p0h0: ping -c 1 192.2.0.3" \
     --fg-host-prog "p0h0: ping -c 1 192.2.1.2" \
     --fg-host-prog "p0h0: ping -c 1 192.2.1.3" \
     --fg-host-prog "p0h0: ping -c 1 192.3.0.2" \
     --fg-host-prog "p0h0: ping -c 1 192.3.0.3" \
     --fg-host-prog "p0h0: ping -c 1 192.3.1.2" \
     --fg-host-prog "p0h0: ping -c 1 192.3.1.3" \
     --fg-host-prog "p0h1: ping -c 1 192.0.0.2" \
     --fg-host-prog "p0h1: ping -c 1 192.0.0.3" \
     --fg-host-prog "p0h1: ping -c 1 192.0.1.2" \
     --fg-host-prog "p0h1: ping -c 1 192.0.1.3" \
     --fg-host-prog "p0h1: ping -c 1 192.1.0.2" \
     --fg-host-prog "p0h1: ping -c 1 192.1.0.3" \
     --fg-host-prog "p0h1: ping -c 1 192.1.1.2" \
     --fg-host-prog "p0h1: ping -c 1 192.1.1.3" \
     --fg-host-prog "p0h1: ping -c 1 192.2.0.2" \
     --fg-host-prog "p0h1: ping -c 1 192.2.0.3" \
     --fg-host-prog "p0h1: ping -c 1 192.2.1.2" \
     --fg-host-prog "p0h1: ping -c 1 192.2.1.3" \
     --fg-host-prog "p0h1: ping -c 1 192.3.0.2" \
     --fg-host-prog "p0h1: ping -c 1 192.3.0.3" \
     --fg-host-prog "p0h1: ping -c 1 192.3.1.2" \
     --fg-host-prog "p0h1: ping -c 1 192.3.1.3" \
     --fg-host-prog "p0h2: ping -c 1 192.0.0.2" \
     --fg-host-prog "p0h2: ping -c 1 192.0.0.3" \
     --fg-host-prog "p0h2: ping -c 1 192.0.1.2" \
     --fg-host-prog "p0h2: ping -c 1 192.0.1.3" \
     --fg-host-prog "p0h2: ping -c 1 192.1.0.2" \
     --fg-host-prog "p0h2: ping -c 1 192.1.0.3" \
     --fg-host-prog "p0h2: ping -c 1 192.1.1.2" \
     --fg-host-prog "p0h2: ping -c 1 192.1.1.3" \
     --fg-host-prog "p0h2: ping -c 1 192.2.0.2" \
     --fg-host-prog "p0h2: ping -c 1 192.2.0.3" \
     --fg-host-prog "p0h2: ping -c 1 192.2.1.2" \
     --fg-host-prog "p0h2: ping -c 1 192.2.1.3" \
     --fg-host-prog "p0h2: ping -c 1 192.3.0.2" \
     --fg-host-prog "p0h2: ping -c 1 192.3.0.3" \
     --fg-host-prog "p0h2: ping -c 1 192.3.1.2" \
     --fg-host-prog "p0h2: ping -c 1 192.3.1.3" \
     --fg-host-prog "p0h3: ping -c 1 192.0.0.2" \
     --fg-host-prog "p0h3: ping -c 1 192.0.0.3" \
     --fg-host-prog "p0h3: ping -c 1 192.0.1.2" \
     --fg-host-prog "p0h3: ping -c 1 192.0.1.3" \
     --fg-host-prog "p0h3: ping -c 1 192.1.0.2" \
     --fg-host-prog "p0h3: ping -c 1 192.1.0.3" \
     --fg-host-prog "p0h3: ping -c 1 192.1.1.2" \
     --fg-host-prog "p0h3: ping -c 1 192.1.1.3" \
     --fg-host-prog "p0h3: ping -c 1 192.2.0.2" \
     --fg-host-prog "p0h3: ping -c 1 192.2.0.3" \
     --fg-host-prog "p0h3: ping -c 1 192.2.1.2" \
     --fg-host-prog "p0h3: ping -c 1 192.2.1.3" \
     --fg-host-prog "p0h3: ping -c 1 192.3.0.2" \
     --fg-host-prog "p0h3: ping -c 1 192.3.0.3" \
     --fg-host-prog "p0h3: ping -c 1 192.3.1.2" \
     --fg-host-prog "p0h3: ping -c 1 192.3.1.3" \
     --fg-host-prog "p1h0: ping -c 1 192.0.0.2" \
     --fg-host-prog "p1h0: ping -c 1 192.0.0.3" \
     --fg-host-prog "p1h0: ping -c 1 192.0.1.2" \
     --fg-host-prog "p1h0: ping -c 1 192.0.1.3" \
     --fg-host-prog "p1h0: ping -c 1 192.1.0.2" \
     --fg-host-prog "p1h0: ping -c 1 192.1.0.3" \
     --fg-host-prog "p1h0: ping -c 1 192.1.1.2" \
     --fg-host-prog "p1h0: ping -c 1 192.1.1.3" \
     --fg-host-prog "p1h0: ping -c 1 192.2.0.2" \
     --fg-host-prog "p1h0: ping -c 1 192.2.0.3" \
     --fg-host-prog "p1h0: ping -c 1 192.2.1.2" \
     --fg-host-prog "p1h0: ping -c 1 192.2.1.3" \
     --fg-host-prog "p1h0: ping -c 1 192.3.0.2" \
     --fg-host-prog "p1h0: ping -c 1 192.3.0.3" \
     --fg-host-prog "p1h0: ping -c 1 192.3.1.2" \
     --fg-host-prog "p1h0: ping -c 1 192.3.1.3" \
     --fg-host-prog "p1h1: ping -c 1 192.0.0.2" \
     --fg-host-prog "p1h1: ping -c 1 192.0.0.3" \
     --fg-host-prog "p1h1: ping -c 1 192.0.1.2" \
     --fg-host-prog "p1h1: ping -c 1 192.0.1.3" \
     --fg-host-prog "p1h1: ping -c 1 192.1.0.2" \
     --fg-host-prog "p1h1: ping -c 1 192.1.0.3" \
     --fg-host-prog "p1h1: ping -c 1 192.1.1.2" \
     --fg-host-prog "p1h1: ping -c 1 192.1.1.3" \
     --fg-host-prog "p1h1: ping -c 1 192.2.0.2" \
     --fg-host-prog "p1h1: ping -c 1 192.2.0.3" \
     --fg-host-prog "p1h1: ping -c 1 192.2.1.2" \
     --fg-host-prog "p1h1: ping -c 1 192.2.1.3" \
     --fg-host-prog "p1h1: ping -c 1 192.3.0.2" \
     --fg-host-prog "p1h1: ping -c 1 192.3.0.3" \
     --fg-host-prog "p1h1: ping -c 1 192.3.1.2" \
     --fg-host-prog "p1h1: ping -c 1 192.3.1.3" \
     --fg-host-prog "p1h2: ping -c 1 192.0.0.2" \
     --fg-host-prog "p1h2: ping -c 1 192.0.0.3" \
     --fg-host-prog "p1h2: ping -c 1 192.0.1.2" \
     --fg-host-prog "p1h2: ping -c 1 192.0.1.3" \
     --fg-host-prog "p1h2: ping -c 1 192.1.0.2" \
     --fg-host-prog "p1h2: ping -c 1 192.1.0.3" \
     --fg-host-prog "p1h2: ping -c 1 192.1.1.2" \
     --fg-host-prog "p1h2: ping -c 1 192.1.1.3" \
     --fg-host-prog "p1h2: ping -c 1 192.2.0.2" \
     --fg-host-prog "p1h2: ping -c 1 192.2.0.3" \
     --fg-host-prog "p1h2: ping -c 1 192.2.1.2" \
     --fg-host-prog "p1h2: ping -c 1 192.2.1.3" \
     --fg-host-prog "p1h2: ping -c 1 192.3.0.2" \
     --fg-host-prog "p1h2: ping -c 1 192.3.0.3" \
     --fg-host-prog "p1h2: ping -c 1 192.3.1.2" \
     --fg-host-prog "p1h2: ping -c 1 192.3.1.3" \
     --fg-host-prog "p1h3: ping -c 1 192.0.0.2" \
     --fg-host-prog "p1h3: ping -c 1 192.0.0.3" \
     --fg-host-prog "p1h3: ping -c 1 192.0.1.2" \
     --fg-host-prog "p1h3: ping -c 1 192.0.1.3" \
     --fg-host-prog "p1h3: ping -c 1 192.1.0.2" \
     --fg-host-prog "p1h3: ping -c 1 192.1.0.3" \
     --fg-host-prog "p1h3: ping -c 1 192.1.1.2" \
     --fg-host-prog "p1h3: ping -c 1 192.1.1.3" \
     --fg-host-prog "p1h3: ping -c 1 192.2.0.2" \
     --fg-host-prog "p1h3: ping -c 1 192.2.0.3" \
     --fg-host-prog "p1h3: ping -c 1 192.2.1.2" \
     --fg-host-prog "p1h3: ping -c 1 192.2.1.3" \
     --fg-host-prog "p1h3: ping -c 1 192.3.0.2" \
     --fg-host-prog "p1h3: ping -c 1 192.3.0.3" \
     --fg-host-prog "p1h3: ping -c 1 192.3.1.2" \
     --fg-host-prog "p1h3: ping -c 1 192.3.1.3" \
     --fg-host-prog "p2h0: ping -c 1 192.0.0.2" \
     --fg-host-prog "p2h0: ping -c 1 192.0.0.3" \
     --fg-host-prog "p2h0: ping -c 1 192.0.1.2" \
     --fg-host-prog "p2h0: ping -c 1 192.0.1.3" \
     --fg-host-prog "p2h0: ping -c 1 192.1.0.2" \
     --fg-host-prog "p2h0: ping -c 1 192.1.0.3" \
     --fg-host-prog "p2h0: ping -c 1 192.1.1.2" \
     --fg-host-prog "p2h0: ping -c 1 192.1.1.3" \
     --fg-host-prog "p2h0: ping -c 1 192.2.0.2" \
     --fg-host-prog "p2h0: ping -c 1 192.2.0.3" \
     --fg-host-prog "p2h0: ping -c 1 192.2.1.2" \
     --fg-host-prog "p2h0: ping -c 1 192.2.1.3" \
     --fg-host-prog "p2h0: ping -c 1 192.3.0.2" \
     --fg-host-prog "p2h0: ping -c 1 192.3.0.3" \
     --fg-host-prog "p2h0: ping -c 1 192.3.1.2" \
     --fg-host-prog "p2h0: ping -c 1 192.3.1.3" \
     --fg-host-prog "p2h1: ping -c 1 192.0.0.2" \
     --fg-host-prog "p2h1: ping -c 1 192.0.0.3" \
     --fg-host-prog "p2h1: ping -c 1 192.0.1.2" \
     --fg-host-prog "p2h1: ping -c 1 192.0.1.3" \
     --fg-host-prog "p2h1: ping -c 1 192.1.0.2" \
     --fg-host-prog "p2h1: ping -c 1 192.1.0.3" \
     --fg-host-prog "p2h1: ping -c 1 192.1.1.2" \
     --fg-host-prog "p2h1: ping -c 1 192.1.1.3" \
     --fg-host-prog "p2h1: ping -c 1 192.2.0.2" \
     --fg-host-prog "p2h1: ping -c 1 192.2.0.3" \
     --fg-host-prog "p2h1: ping -c 1 192.2.1.2" \
     --fg-host-prog "p2h1: ping -c 1 192.2.1.3" \
     --fg-host-prog "p2h1: ping -c 1 192.3.0.2" \
     --fg-host-prog "p2h1: ping -c 1 192.3.0.3" \
     --fg-host-prog "p2h1: ping -c 1 192.3.1.2" \
     --fg-host-prog "p2h1: ping -c 1 192.3.1.3" \
     --fg-host-prog "p2h2: ping -c 1 192.0.0.2" \
     --fg-host-prog "p2h2: ping -c 1 192.0.0.3" \
     --fg-host-prog "p2h2: ping -c 1 192.0.1.2" \
     --fg-host-prog "p2h2: ping -c 1 192.0.1.3" \
     --fg-host-prog "p2h2: ping -c 1 192.1.0.2" \
     --fg-host-prog "p2h2: ping -c 1 192.1.0.3" \
     --fg-host-prog "p2h2: ping -c 1 192.1.1.2" \
     --fg-host-prog "p2h2: ping -c 1 192.1.1.3" \
     --fg-host-prog "p2h2: ping -c 1 192.2.0.2" \
     --fg-host-prog "p2h2: ping -c 1 192.2.0.3" \
     --fg-host-prog "p2h2: ping -c 1 192.2.1.2" \
     --fg-host-prog "p2h2: ping -c 1 192.2.1.3" \
     --fg-host-prog "p2h2: ping -c 1 192.3.0.2" \
     --fg-host-prog "p2h2: ping -c 1 192.3.0.3" \
     --fg-host-prog "p2h2: ping -c 1 192.3.1.2" \
     --fg-host-prog "p2h2: ping -c 1 192.3.1.3" \
     --fg-host-prog "p2h3: ping -c 1 192.0.0.2" \
     --fg-host-prog "p2h3: ping -c 1 192.0.0.3" \
     --fg-host-prog "p2h3: ping -c 1 192.0.1.2" \
     --fg-host-prog "p2h3: ping -c 1 192.0.1.3" \
     --fg-host-prog "p2h3: ping -c 1 192.1.0.2" \
     --fg-host-prog "p2h3: ping -c 1 192.1.0.3" \
     --fg-host-prog "p2h3: ping -c 1 192.1.1.2" \
     --fg-host-prog "p2h3: ping -c 1 192.1.1.3" \
     --fg-host-prog "p2h3: ping -c 1 192.2.0.2" \
     --fg-host-prog "p2h3: ping -c 1 192.2.0.3" \
     --fg-host-prog "p2h3: ping -c 1 192.2.1.2" \
     --fg-host-prog "p2h3: ping -c 1 192.2.1.3" \
     --fg-host-prog "p2h3: ping -c 1 192.3.0.2" \
     --fg-host-prog "p2h3: ping -c 1 192.3.0.3" \
     --fg-host-prog "p2h3: ping -c 1 192.3.1.2" \
     --fg-host-prog "p2h3: ping -c 1 192.3.1.3" \
     --fg-host-prog "p3h0: ping -c 1 192.0.0.2" \
     --fg-host-prog "p3h0: ping -c 1 192.0.0.3" \
     --fg-host-prog "p3h0: ping -c 1 192.0.1.2" \
     --fg-host-prog "p3h0: ping -c 1 192.0.1.3" \
     --fg-host-prog "p3h0: ping -c 1 192.1.0.2" \
     --fg-host-prog "p3h0: ping -c 1 192.1.0.3" \
     --fg-host-prog "p3h0: ping -c 1 192.1.1.2" \
     --fg-host-prog "p3h0: ping -c 1 192.1.1.3" \
     --fg-host-prog "p3h0: ping -c 1 192.2.0.2" \
     --fg-host-prog "p3h0: ping -c 1 192.2.0.3" \
     --fg-host-prog "p3h0: ping -c 1 192.2.1.2" \
     --fg-host-prog "p3h0: ping -c 1 192.2.1.3" \
     --fg-host-prog "p3h0: ping -c 1 192.3.0.2" \
     --fg-host-prog "p3h0: ping -c 1 192.3.0.3" \
     --fg-host-prog "p3h0: ping -c 1 192.3.1.2" \
     --fg-host-prog "p3h0: ping -c 1 192.3.1.3" \
     --fg-host-prog "p3h1: ping -c 1 192.0.0.2" \
     --fg-host-prog "p3h1: ping -c 1 192.0.0.3" \
     --fg-host-prog "p3h1: ping -c 1 192.0.1.2" \
     --fg-host-prog "p3h1: ping -c 1 192.0.1.3" \
     --fg-host-prog "p3h1: ping -c 1 192.1.0.2" \
     --fg-host-prog "p3h1: ping -c 1 192.1.0.3" \
     --fg-host-prog "p3h1: ping -c 1 192.1.1.2" \
     --fg-host-prog "p3h1: ping -c 1 192.1.1.3" \
     --fg-host-prog "p3h1: ping -c 1 192.2.0.2" \
     --fg-host-prog "p3h1: ping -c 1 192.2.0.3" \
     --fg-host-prog "p3h1: ping -c 1 192.2.1.2" \
     --fg-host-prog "p3h1: ping -c 1 192.2.1.3" \
     --fg-host-prog "p3h1: ping -c 1 192.3.0.2" \
     --fg-host-prog "p3h1: ping -c 1 192.3.0.3" \
     --fg-host-prog "p3h1: ping -c 1 192.3.1.2" \
     --fg-host-prog "p3h1: ping -c 1 192.3.1.3" \
     --fg-host-prog "p3h2: ping -c 1 192.0.0.2" \
     --fg-host-prog "p3h2: ping -c 1 192.0.0.3" \
     --fg-host-prog "p3h2: ping -c 1 192.0.1.2" \
     --fg-host-prog "p3h2: ping -c 1 192.0.1.3" \
     --fg-host-prog "p3h2: ping -c 1 192.1.0.2" \
     --fg-host-prog "p3h2: ping -c 1 192.1.0.3" \
     --fg-host-prog "p3h2: ping -c 1 192.1.1.2" \
     --fg-host-prog "p3h2: ping -c 1 192.1.1.3" \
     --fg-host-prog "p3h2: ping -c 1 192.2.0.2" \
     --fg-host-prog "p3h2: ping -c 1 192.2.0.3" \
     --fg-host-prog "p3h2: ping -c 1 192.2.1.2" \
     --fg-host-prog "p3h2: ping -c 1 192.2.1.3" \
     --fg-host-prog "p3h2: ping -c 1 192.3.0.2" \
     --fg-host-prog "p3h2: ping -c 1 192.3.0.3" \
     --fg-host-prog "p3h2: ping -c 1 192.3.1.2" \
     --fg-host-prog "p3h2: ping -c 1 192.3.1.3" \
     --fg-host-prog "p3h3: ping -c 1 192.0.0.2" \
     --fg-host-prog "p3h3: ping -c 1 192.0.0.3" \
     --fg-host-prog "p3h3: ping -c 1 192.0.1.2" \
     --fg-host-prog "p3h3: ping -c 1 192.0.1.3" \
     --fg-host-prog "p3h3: ping -c 1 192.1.0.2" \
     --fg-host-prog "p3h3: ping -c 1 192.1.0.3" \
     --fg-host-prog "p3h3: ping -c 1 192.1.1.2" \
     --fg-host-prog "p3h3: ping -c 1 192.1.1.3" \
     --fg-host-prog "p3h3: ping -c 1 192.2.0.2" \
     --fg-host-prog "p3h3: ping -c 1 192.2.0.3" \
     --fg-host-prog "p3h3: ping -c 1 192.2.1.2" \
     --fg-host-prog "p3h3: ping -c 1 192.2.1.3" \
     --fg-host-prog "p3h3: ping -c 1 192.3.0.2" \
     --fg-host-prog "p3h3: ping -c 1 192.3.0.3" \
     --fg-host-prog "p3h3: ping -c 1 192.3.1.2" \
     --fg-host-prog "p3h3: ping -c 1 192.3.1.3" \
          2> $LOG_DUMPS/flightplan_mininet_log.err
}

eval $MODE

exit 0
