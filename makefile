# project-name
P=RFID-reader
# top-level-entity
TLE=RFID_reader
# device selected for programming
DEV=EP4CE115F29C7
# family of the device
F="Cyclone IV E"
# path to all binaries of quartus:
QUARTUS_BIN_PATH=/opt/altera.15.1/quartus/bin
# frequency for pll:
f=2400
all: compile program
compile:
	${QUARTUS_BIN_PATH}/quartus_sh --flow compile ${P}
project:
	${QUARTUS_BIN_PATH}/quartus_sh --tcl_eval project_new -f ${F} -overwrite -p ${DEV} ${P}
program:
	${QUARTUS_BIN_PATH}/quartus_pgm -c USB-Blaster ${P}.cdf
RTL:
	${QUARTUS_BIN_PATH}/qnui ${P}
symbol:
	${QUARTUS_BIN_PATH}/quartus_map ${P} --generate_symbol=${d}
analysis:
	${QUARTUS_BIN_PATH}/quartus_map ${P}
