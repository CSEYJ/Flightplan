#!/bin/bash

if [[ $# > 2 ]]; then
    echo "Usage $0 <rate> [time]"
    exit 1
fi

if [[ $BMV2_REPO == "" ]]; then
    echo "Must set BMV2_REPO before running this test!"
    exit 1
fi

HERE=`dirname $0`
BLD=$HERE/../build

RATE=$1

if [[ $RATE == "" ]]; then
    RATE=0;
fi

# TIME- seconds to run the iperf
# TIME1- seconds to run the mininet topology
# TIME1 > TIME
if [[ $# > 1 ]]; then
    TIME=$2
    TIME1=`expr $2 + 5`
else
    TIME=5s
    TIME1=10s
fi


USER=`logname`
#INPUT_PCAP=`realpath $1`

BASENAME=tclust_MAC_fec_iperf_$RATE
TESTDIR=$HERE/test_output
OUTDIR=$TESTDIR/$BASENAME
PCAP_DUMPS=$OUTDIR/pcap_dump/
LOG_DUMPS=$OUTDIR/log_files
rm -rf $LOG_DUMPS
rm -f $OUTDIR/*.pcap
rm -f $OUTDIR/pcap_dump/*.pcap
mkdir -p $PCAP_DUMPS
mkdir -p $LOG_DUMPS

sudo mn -c 2> $LOG_DUMPS/mininet_clean.err

TOPO=$HERE/topologies/MAC_FEC_tclust_topology.yml

sudo -E python $HERE/start_flightplan_mininet.py \
        $TOPO \
        --pcap-dump $PCAP_DUMPS \
        --log $LOG_DUMPS \
        --verbose \
        --host-prog "iperf_s:iperf3 -s -p 4242" \
       --host-prog "iperf_c:iperf3 -c 10.0.0.11 -p 4242 -b $RATE -t $TIME -M 1000" \
        --time ${TIME1%s} 2> $LOG_DUMPS/flightplan_mininet_log.err

#       --replay iperf_c-tofino1:bmv2/pcaps/oneFlow_iperfH.pcap \
#       --host-prog "iperf_s:iperf3 -s -p 4242" \
#       --host-prog "iperf_c:iperf3 -c 10.0.0.11 -p 4242 -b $RATE -t $TIME -M 1000" \
#        --host-prog "mcd_s:iperf3 -s -p 4242" \
#        --host-prog "mcd_c:iperf3 -c 10.0.0.12 -p 4242 -b $RATE -t $TIME -M 1000" \
#        --host-prog "iperf_c:iperf3 -c 10.0.0.11 -p 4242 -b $RATE -k 5 -M 1000" \

if [[ $? != 0 ]]; then
    echo Error running flightplan_mininet.py
    echo Check logs in $LOG_DUMPS for more details:
    ls -1 $LOG_DUMPS/*
    exit -1;
fi

cat $LOG_DUMPS/iperf_c_prog_1.log
#cat $LOG_DUMPS/mcd_c_prog_3.log

echo "Bytes Transferred: IPERF HOSTS"
python2 $HERE/pcap_tools/pcap_path_size.py $TOPO $PCAP_DUMPS iperf_c fpga_enc tofino1 fpga_dec iperf_s
echo "IPERF HOSTS"
python2 $HERE/pcap_tools/pcap_path_size.py $TOPO $PCAP_DUMPS iperf_s iperf_c

#IN_PCAP= cp $PCAP_DUMPS/iperf_c_to_tofino1.pcap $LOG_DUMPS/test_files/input.pcap
#OUT_PCAP= cp $PCAP_DUMPS/tofino2_to_iperf_s.pcap $LOG_DUMPS/test_files/output.pcap
PCAP_TEST=$LOG_DUMPS/test_files/
rm -f $PCAP_TEST/*.pcap
rm -f $PCAP_TEST/*.txt
mkdir -p $PCAP_TEST

cp $PCAP_DUMPS/iperf_c_to_tofino1.pcap $PCAP_TEST/input.pcap
cp $PCAP_DUMPS/tofino2_to_iperf_s.pcap $PCAP_TEST/output.pcap

IN_PCAP=$PCAP_TEST/input.pcap
OUT_PCAP=$PCAP_TEST/output.pcap

OUT_TXT=$LOG_DUMPS/test_files/out.txt
IN_TXT=$LOG_DUMPS/test_files/inp.txt

IN_SRT=$LOG_DUMPS/test_files/sorted_in.txt
OUT_SRT=$LOG_DUMPS/test_files/sorted_out.txt

tcpdump -XXtenr $IN_PCAP > $IN_TXT
tcpdump -XXtenr $OUT_PCAP > $OUT_TXT

INLINES=$(cat $IN_TXT | wc -l)
OUTLINES=$(cat $OUT_TXT | wc -l)

sort $IN_TXT > $IN_SRT
sort $OUT_TXT > $OUT_SRT

sudo chown -R $USER:$USER $OUTDIR

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [[ $INLINES == $OUTLINES ]]; then
    echo "Input and output both contain $INLINES lines"
    echo "Running diff:"
    diff $IN_SRT $OUT_SRT | head -100
    echo "Diff complete (possibly truncated)"

    if [[ $INLINES == 0 ]]; then
        echo -e ${RED}TEST FAILED${NC}
        exit 1;
    fi

    if [[ `diff $IN_SRT $OUT_SRT | wc -l` != '0' ]]; then
        echo -e ${RED}TEST FAILED${NC}
        echo "Check $IN_TXT $OUT_TXT to compare"
        exit 1
    else
        echo -e ${GREEN}TEST SUCCEEDED${NC}
        exit 0
    fi
else
    echo -e "Difference between input and output:\n"
    diff $IN_SRT $OUT_SRT | head -100
    echo "(diff possibly truncated)"

    echo "Input and output contain different number of lines!"
    echo "($INLINES and $OUTLINES)"
    echo "Check $IN_TXT $OUT_TXT to compare"
    echo -e ${RED}TEST FAILED${NC}
    exit 1
fi


#echo "Bytes Transferred: MCD HOSTS"
#python2 $HERE/pcap_tools/pcap_path_size.py $TOPO $PCAP_DUMPS mcd_c fpga_hcomp tofino1 fpga_dcomp mcd_s
#echo "MCD HOSTS"
#python2 $HERE/pcap_tools/pcap_path_size.py $TOPO $PCAP_DUMPS mcd_s mcd_c

echo "DONE."
