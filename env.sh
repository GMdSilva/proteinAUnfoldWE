#!/bin/sh
#
# env.sh
#
# This script defines environment variables that are used by other shell
# scripts, both when setting up the simulation and when running the simulation.
#

################################## AMBER #######################################
module purge
# GTX1080
module load intel/2017.1.132 mkl/2017.1.132 cuda/8.0.44 amber/16

# Use custom pmemd compilation with SpeedBoostSM
PMEMD="/gscratch3/lchong/ajd98/apps/amber/bin/pmemd.cuda -O"

############################## Python and WESTPA ###############################
# Next inform WESTPA what python it should use. 
export WEST_ROOT=/gscratch3/lchong/ajd98/apps/westpa/
export WEST_PYTHON=/gscratch3/lchong/ajd98/apps/anaconda2-4.4.0/bin/python

export LOGDIR=${WEST_SIM_ROOT}/job_logs/

# Explicitly name our simulation root directory.  Similar to the statement 
# above, we check if the variable is not set.  If the variable is not set,
# the we set it 
if [ -z "$WEST_SIM_ROOT" ]; then
  export WEST_SIM_ROOT="/gscratch3/lchong/ajd98/proteinA/unfoldingWE"
fi

# Set the simulation name.  Whereas "WEST_SIM_ROOT" gives us the entire 
# absolute path to the simulation directory, running the "basename" command
# will give us only the last part of that path (the directory name).
export SIM_NAME=$(basename $WEST_SIM_ROOT)

export SERVER_INFO=${WEST_SIM_ROOT}/server_info.json
