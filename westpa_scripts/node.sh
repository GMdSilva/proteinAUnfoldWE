#!/bin/bash
#
# node.sh
set -x

cd $SLURM_SUBMIT_DIR
source env.sh

# Each node will write to a separate log file.
SUFFIX=$(hostname | cut -d\. -f1)
LOG="$LOGDIR/west-$SUFFIX.log"

# This will be our local scratch space
export WORKDIR="${LOCAL}"

# This should already be empty.
if [ -n "$(ls -A ${WORKDIR})" ]; then
  rm -rf $WORKDIR/*
fi

# Since these files do not change and we need to access them many times, copy
# them over to local scratch space.
cp -r $WEST_SIM_ROOT/amber_config $WORKDIR/
cp -r $WEST_SIM_ROOT/reference $WORKDIR/
export REFERENCE=${WORKDIR}/reference/proteinA.pdb

# Run simulation
$WEST_ROOT/bin/w_run "$@" &> $LOG
