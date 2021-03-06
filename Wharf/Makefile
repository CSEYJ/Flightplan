.PHONY: All EncoderNew run clean

P4C:=p4c-bm2-ss
P4TEST:=p4test

BMV2_REPO_M:=$(BMV2_REPO)#FILL IN BEHAVIORAL-MODEL REPO LOCATION
RUNTIME_CLI_DIR=$(BMV2_REPO_M)/tools

BLD=build/
BLD_BMV2=$(BLD)/bmv2/

ifeq ($(BMV2_REPO_M),)
ifneq ($(filter run%,$(MAKECMDGOALS)),)
$(error Must set BMV2_REPO to run mininet with makefile)
endif
endif

BOOSTERS?=FEC COMPRESSION MEMCACHED

ifneq ($(MAKECMDGOALS),configure_runtime)
BOOSTERS:=$(shell ../cpuBoosters/bmv2/enabled_boosters.sh ${BOOSTERS})
endif

BOOSTER_DEFINES:=$(foreach B, ${BOOSTERS}, -D$B_BOOSTER)

DEPS=Makefile Sources/FEC.p4 Sources/Forwarding.p4 Sources/LLDP.p4 Sources/Parsing.p4 Sources/Compression.p4

TARGET=TARGET_BMV2

USER=$(shell logname)

EXTERNS=fec_encode fec_decode memcached header_compress header_decompress \
		fec_encode_fp fec_decode_fp memcached_fp header_compress_fp header_decompress_fp

All: bmv2 Sample

Sample: $(BLD_BMV2)/Sample.json

ExternObj: $(BLD_BMV2)/ExternObj.json

test:
	${P4TEST} -DTARGET_BMV2 -I../FPGA/RSEVivadoHLS/ -I../FPGA/RSEConfig  -I../FPGA/MemcachedP4 

bmv2: $(BLD_BMV2) $(BLD_BMV2)/Encoder.json $(BLD_BMV2)/Decoder.json $(BLD_BMV2)/Dropper.json \
	  $(BLD_BMV2)/Forwarder.json $(BLD_BMV2)/Complete.json $(BLD_BMV2)/Compressor.json \
	$(BLD_BMV2)/FirstHalf.json $(BLD_BMV2)/SecondHalf.json $(BLD_BMV2)/FirstHalfWithoutCompression.json $(BLD_BMV2)/Compress.json \
	$(BLD_BMV2)/ALV.json \
	$(BLD_BMV2)/ALV_FW.json \
	$(BLD_BMV2)/CheckedFragment.json $(BLD_BMV2)/CompleteHeadered.json $(BLD_BMV2)/ForwarderHeadered.json \
	$(BLD_BMV2)/ALV_part1.json $(BLD_BMV2)/ALV_part2.json \
	$(BLD_BMV2)/ALV_S2part1.json $(BLD_BMV2)/ALV_S2part2.json \
	$(BLD_BMV2)/ALV_Complete.json \
	$(BLD_BMV2)/ALV_Complete_split1.json $(BLD_BMV2)/ALV_Complete_split2.json \
	$(BLD_BMV2)/ALV_Complete_2_split1.json $(BLD_BMV2)/ALV_Complete_2_split2.json $(BLD_BMV2)/ALV_Complete_2_split3.json $(BLD_BMV2)/ALV_Complete_2_split4.json $(BLD_BMV2)/ALV_Complete_2_split5.json $(BLD_BMV2)/ALV_Complete_2_split6.json \
	$(BLD_BMV2)/ALV_FW_split1.json $(BLD_BMV2)/ALV_FW_split2.json \
	$(BLD_BMV2)/ALV_FEC_split1.json $(BLD_BMV2)/ALV_FEC_split2.json \
	$(BLD_BMV2)/ALV_Complete_split1_hl2.json $(BLD_BMV2)/ALV_Complete_split2_hl2.json \
	$(BLD_BMV2)/ALV_Complete_split1_hl3.json $(BLD_BMV2)/ALV_Complete_split2_hl3.json \
	$(BLD_BMV2)/ALV_Complete_hl3_unsplit.json \
	$(BLD_BMV2)/ALV_Complete_split1_hl3new.json $(BLD_BMV2)/ALV_Complete_split2_hl3new.json \
	$(BLD_BMV2)/ALV_Complete_split1_hl3new_2.json $(BLD_BMV2)/ALV_Complete_split2_hl3new_2.json \
	$(BLD_BMV2)/ALV_qos.json $(BLD_BMV2)/ALV_bt.json \
	$(BLD_BMV2)/ALV_qos_split1_hl3new.json $(BLD_BMV2)/ALV_qos_split2_hl3new.json \
	$(BLD_BMV2)/ALV_bt_1_split1.json $(BLD_BMV2)/ALV_bt_1_split2.json
#	$(BLD_BMV2)/ALV_Complete_split1_hl3_2.json $(BLD_BMV2)/ALV_Complete_split2_hl3_2.json \
#	$(BLD_BMV2)/ALV_Complete_split1_hl.json $(BLD_BMV2)/ALV_Complete_split2_hl.json

tclust: Tclust_tofino Tclust_noop \
	Tclust_encoder Tclust_decoder Tclust_compressor Tclust_decompressor Tclust_mcd

%: $(BLD_BMV2)/%.json;

$(BLD_BMV2)/CheckedFragment.json: $(BLD_BMV2) Sources/FlightplanParser.p4 Sources/FlightplanHeader.p4 Sources/FlightplanDeparser.p4

complete: $(BLD_BMV2)/Complete.json

$(BLD_BMV2):
	@mkdir -p $@

configure_runtime: bmv2
	cd ../cpuBoosters/bmv2 && make configure BOOSTERS="${BOOSTERS}" && make BOOSTERS="${BOOSTERS}"

$(BLD_BMV2)/%.json: Sources/%.p4 $(DEPS) $(BMV2_REPO_M)/targets/booster_switch/Makefile $(BLD_BMV2)
	p4c-bm2-ss --emit-externs -I../FPGA/RSEConfig -I../FPGA/MemcachedP4 -I../FPGA/RSEVivadoHLS/ -I Sources $< -o $@_orig --target bmv2 --arch v1model -D$(TARGET) -DMID_FORWARDING_DECISION ${BOOSTER_DEFINES}
	python2 split_extern_event.py $@_orig $@ ${EXTERNS}


clean:
	rm -fr $(BLD)

.PRECIOUS: $(BLD_BMV2)/%.json
