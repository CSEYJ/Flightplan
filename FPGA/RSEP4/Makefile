.PHONY: All Simulation clean

All: Encoder/XilinxSwitch/XilinxSwitch_vivado

Simulation: Encoder

Encoder/XilinxSwitch/XilinxSwitch_vivado: Encoder
	cd $(realpath Encoder/XilinxSwitch); \
	bash -c 'source $$SDSOC_ROOT/settings64.sh && vivado -mode batch -source XilinxSwitch_vivado_packager.tcl'

Encoder: Encoder.sdnet Scripts/Generate_packets.sh Scripts/Patch_backpressure.pl \
         Sources/fec_encode_0_t.hpp Sources/rse.cpp Sources/rse.h Sources/fec_encode_0_t.v
	@rm -fr Encoder
	bash -c 'source $$SDNET_ROOT/settings64.sh && sdnet Encoder.sdnet -busType axi -busWidth 64 -UE -clk_line -lineClock 156.25 -workDir Encoder'
	@ln -s ../../Scripts/Generate_packets.sh Encoder/XilinxSwitch/Generate_packets.sh
	@ln -s ../../../Sources/fec_encode_0_t.hpp Encoder/XilinxSwitch/fec_encode_0_t.TB/fec_encode_0_t.hpp
	@ln -s ../../../Sources/update_fec_state_0_t.hpp Encoder/XilinxSwitch/update_fec_state_0_t.TB/update_fec_state_0_t.hpp
	@ln -s ../../../Sources/rse.cpp Encoder/XilinxSwitch/fec_encode_0_t.TB/rse.cpp
	@ln -s ../../../Sources/rse.h Encoder/XilinxSwitch/fec_encode_0_t.TB/rse.h
	@ln -s ../../../Sources/fec_encode_0_t.v Encoder/XilinxSwitch/fec_encode_0_t.HDL/fec_encode_0_t.v
	@ln -s ../../../Sources/update_fec_state_0_t.v Encoder/XilinxSwitch/update_fec_state_0_t.HDL/update_fec_state_0_t.v
	@cp ../RSEVivadoHLS/Batch/RSEVivadoHLS/solution1/syn/vhdl/*.vhd Encoder/XilinxSwitch/fec_encode_0_t.HDL
	patch -p0 < Patches/Encoder.patch
# Convert configuration file to Verilog.
	@sed -e 's/^#/`/' -e 's://.*$$::' ../RSEConfig/Configuration.h > Encoder/XilinxSwitch/fec_encode_0_t.HDL/Configuration.v
# Fix backpressure.
	@FILE=$$(mktemp) && ./Scripts/Patch_backpressure.pl -i Encoder/XilinxSwitch/XilinxSwitch.v -d 3 -p fec_encode -t fec_encode_0_t -m fec_encode_0 > $${FILE} && mv $${FILE} Encoder/XilinxSwitch/XilinxSwitch.v

Encoder.sdnet: Sources/Encoder.p4
	bash -c 'source $$SDNET_ROOT/settings64.sh && p4c-sdnet -I ../RSEVivadoHLS Sources/Encoder.p4 -o Encoder.sdnet'
	patch Encoder.sdnet Patches/Encoder.sdnet.patch

clean:
	rm -fr Encoder.sdnet Encoder

Update_patches:
	bash -c 'source $$SDNET_ROOT/settings64.sh && p4c-sdnet -I ../RSEVivadoHLS Sources/Encoder.p4 -o Encoder.sdnet.original'
	bash -c 'source $$SDNET_ROOT/settings64.sh && sdnet Encoder.sdnet -busType axi -busWidth 64 -UE -clk_line -lineClock 156.25 -workDir Encoder.original'
	Scripts/Create_patches.bash

