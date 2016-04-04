# project-name
P=RFID-reader
# top-level-entity
TLE=RFID_reader
# device selected for programming
DEV=EP4CE115F29C7
# family of the device
F="Cyclone IV E"
# frequency for pll:
f=2400
all: compile program
compile:
	${QUARTUS_BIN}/quartus_sh --flow compile ${P}
project:
	${QUARTUS_BIN}/quartus_sh --tcl_eval project_new -f ${F} -overwrite -p ${DEV} ${P}
program:
	${QUARTUS_BIN}/quartus_pgm -c USB-Blaster ${P}.cdf
RTL:
	${QUARTUS_BIN}/qnui ${P}
symbol:
	${QUARTUS_BIN}/quartus_map ${P} --generate_symbol=${d}
analysis:
	${QUARTUS_BIN}/quartus_map ${P}
