#!/usr/bin/env bash
#SBATCH --job-name=proteinAunfold
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --output=slurm.out
#SBATCH --error=slurm.err
#SBATCH --time=48:00:00
#SBATCH --qos=normal
#SBATCH --cluster=gpu
#SBATCH --gres=gpu:4
#SBATCH --partition=gtx1080
#
#
# Submission script for AMBER GPU simulations on h2p.crc.pitt.edu
#
# --gres=gpu:n: determines the number of GPUs available for the job.
#
################################### SETTINGS ###################################
set -e
set -x
################################# ENVIRONMENT ##################################
source env.sh

# Make sure the server file is new!
if [ -e $SERVER_INFO ] ; then
  rm $SERVER_INFO 
fi


# Start the zmq server.
$WEST_ROOT/bin/w_run \
    --debug \
    --work-manager=zmq \
    --n-workers=0 \
    --zmq-mode=master \
    --zmq-write-host-info=$SERVER_INFO \
    --zmq-comm-mode=tcp \
    --zmq-master-heartbeat 100 \
    --zmq-worker-heartbeat 100 \
    --zmq-timeout-factor 5 \
    &> ${WEST_SIM_ROOT}/job_logs/west.log-$SLURM_JOBID &

# Wait on ZMQ server info file up to one minute
for ((n=0; n<60; n++)); do
  if [ -e $SERVER_INFO ] ; then
    echo "Server info file detected: $SERVER_INFO"
    cat $SERVER_INFO
    break
  fi
  sleep 1
done

# Exit if ZMQ server info file doesn't appear in one minute
if ! [ -e $SERVER_INFO ] ; then
  echo 'Server failed to start'
  exit 1
fi

# Run node.sh on each of the nodes.
#
# The --debug flag is not necessary, and it will make your log files very
# large.  However, it is useful for starting new simulations, when you are
# more likely to encounter errors.
#
# The ZMQ master and workers communicate with each other at an interval called
# the "heartbeat".  If you experience errors that state "no contact from worker ...",
# You may need to increase these values.
srun --ntasks=$SLURM_NNODES --ntasks-per-node=1 --mpi=pmi2 $WEST_SIM_ROOT/westpa_scripts/node.sh \
    --debug \
    --work-manager=zmq \
    --n-workers=4 \
    --zmq-mode=node \
    --zmq-read-host-info=$SERVER_INFO \
    --zmq-comm-mode=tcp \
    --zmq-master-heartbeat 100 \
    --zmq-worker-heartbeat 100 \
    --zmq-timeout-factor 5 &

wait  
