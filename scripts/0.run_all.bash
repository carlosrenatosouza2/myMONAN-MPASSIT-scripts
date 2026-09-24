#!/bin/bash 



# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv_jaci_gnu.bash

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/${myDIR}; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/${myDIR};   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------

# Input variables:-----------------------------------------------------
github_link="https://github.com/monanadmin/MONAN-Model.git"
github_link_MPASSIT="https://github.com/monanadmin/MONAN-MPASSIT.git"
monan_branch=2.0.0-rc
mpassit_branch="feature/monan-mpassit-107-QI"
EXP=GFS
RES=5898242       # Options: 
                  #           40962   = 120km
                  #           163842  =  60km
                  #           655362  =  30Km
                  #           1024002 =  24km
                  #           2621442 =  15Km
                  #           5898242 =  10Km
YYYYMMDDHHi=20262026092406
FCST=24
#----------------------------------------------------------------------

# STEP 1: Installing and compiling the MONAN-MPASSIT:
time ${SCRIPTS}/1.install_mpassit.bash ${github_link_MPASSIT} ${mpassit_branch}
exit

# STEP 2: Executing the pos-processing MONAN-MPASSIT. 
time ${SCRIPTS}/2.run_mpassit.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit
