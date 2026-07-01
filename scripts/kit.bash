#!/bin/bash

DIRHOME=$(pwd)

nedit \
${DIRHOME}/setenv_jaci_gnu.bash \
${DIRHOME}/0.run_all.bash \
${DIRHOME}/1.install_mpassit.bash \
${DIRHOME}/2.run_mpassit.bash \
${DIRHOME}/namelists/varlist_2d.OPER \
${DIRHOME}/namelists/varlist_3d.OPER \
${DIRHOME}/namelists/namelist.input.TEMPLATE \
${DIRHOME}/kit.bash &
