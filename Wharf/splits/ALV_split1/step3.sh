#!/usr/bin/env bash
#Test setup for Flightplan
#Nik Sultana, UPenn, March 2020
set -e

source /home/nsultana/2/P4Boosters/Wharf/splits/ALV_split1/envars.sh

${FPControl} ${TOPOLOGY} ${FPCD} check_state --switch p0e0 --next_segment 2 --value 0
${FPControl} ${TOPOLOGY} ${FPCD} check_state --switch FPoffload --next_segment 3 --value 1
${FPControl} ${TOPOLOGY} ${FPCD} check_state --switch FPoffload2 --next_segment 3 --value 1
