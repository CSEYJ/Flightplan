ifndef DISPLAY
  $(error Despite SDx is used in batch mode, you have to set the DISPLAY environment variable.)
endif

SHELL=/bin/bash

.PHONY: All RSE Memcached RSEEncoder1Port RSEDecoder1Port Memcached1Port Compressor1Port Compressor2Ports \
	RSEEncoder2Ports RSEDecoder2Ports Memcached2Ports PacketDropper2Ports Decompressor1Port Decompressor2Ports

All: RSE Memcached Compressor

RSE: RSEEncoder1Port RSEDecoder1Port RSEEncoder2Ports RSEDecoder2Ports PacketDropper2Ports

Memcached: Memcached1Port Memcached2Ports

Compressor: Compressor1Port Compressor2Ports
 
Decompressor: Decompressor1Port Decompressor2Ports

RSEEncoder1Port:
	rm -fr RSEEncoder1Port
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD RSEEncoder1Port generic_1_port

RSEDecoder1Port:
	rm -fr RSEDecoder1Port
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD RSEDecoder1Port generic_1_port

Memcached1Port:
	rm -fr Memcached1Port
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD Memcached1Port generic_1_port

Compressor1Port:
	rm -fr Compressor1Port
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD Compressor1Port generic_1_port

Decompressor1Port:
	rm -fr Decompressor1Port
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD Decompressor1Port generic_1_port

RSEEncoder2Ports:
	rm -fr RSEEncoder2Ports
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD RSEEncoder2Ports generic_2_ports

RSEDecoder2Ports:
	rm -fr RSEDecoder2Ports
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD RSEDecoder2Ports generic_2_ports

Memcached2Ports:
	rm -fr Memcached2Ports
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD Memcached2Ports generic_2_ports

Compressor2Ports:
	rm -fr Compressor2Ports
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD Compressor2Ports generic_2_ports

Decompressor2Ports:
	rm -fr Decompressor2Ports
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD Decompressor2Ports generic_2_ports

PacketDropper2Ports:
	rm -fr PacketDropper2Ports
	source $$SDSOC_ROOT/settings64.sh && sdx -batch -source ./Build_project.tcl $$PWD PacketDropper2Ports packet_dropper_2_ports

clean:
	rm -fr RSEEncoder1Port RSEDecoder1Port Memcached1Port Compressor1Port RSEEncoder2Ports RSEDecoder2Ports \
	Memcached2Ports Compressor2Ports PacketDropper2Ports Decompresso1Port Decompressor2Ports

