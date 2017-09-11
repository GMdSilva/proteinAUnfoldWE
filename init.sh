#!/bin/bash
#
# init.sh
#
# Initialize the WESTPA simulation, creating initial states (istates) and the
# main WESTPA data file, west.h5. 
#
# If you run this script after starting the simulation, the data you generated
# will be erased!
#

source env.sh

# Make sure that WESTPA is not already running.  Running two instances of 
# WESTPA on a single node/machine can cause problems.
# This code will kill any WESTPA process that is currently running.
pkill -9 -f w_run

# Make sure that seg_logs (log files for each westpa segment), traj_segs (data
# from each trajectory segment), and istates (initial states for starting new
# trajectories) directories exist and are empty. 
rm -rf traj_segs seg_logs istates west.h5 
mkdir   seg_logs traj_segs istates job_logs

BSTATE_ARGS="--bstate-file bstates/bstates.txt"

# The "$@" lets us take any arguments that were passed to init.sh at the
# command line and pass them along to w_init.
$WEST_ROOT/bin/w_init \
  $BSTATE_ARGS\
  --segs-per-state 5 \
  --work-manager=threads "$@"
