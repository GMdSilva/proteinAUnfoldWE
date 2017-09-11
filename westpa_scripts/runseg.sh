#!/bin/bash
#
# runseg.sh
#
# WESTPA runs this script for each trajectory segment. WESTPA supplies
# environment variables that are unique to each segment, such as:
#
#   WEST_CURRENT_SEG_DATA_REF: A path to where the current trajectory segment's
#       data will be stored. This will become "WEST_PARENT_DATA_REF" for any
#       child segments that spawn from this segment
#   WEST_PARENT_DATA_REF: A path to a file or directory containing data for the
#       parent segment.
#   WEST_CURRENT_SEG_INITPOINT_TYPE: Specifies whether this segment is starting
#       anew, or if this segment continues from where another segment left off.
#   WEST_RAND16: A random integer
#
# This script has the following three jobs:
#  1. Create a directory for the current trajectory segment, and set up the
#     directory for running pmemd.cuda 
#  2. Run the dynamics
#  3. Calculate the progress coordinates and return data to WESTPA

# If we are running in debug mode, then output a lot of extra information.
if [ -n "$SEG_DEBUG" ] ; then
    set -x
    env | sort
fi

source $WEST_SIM_ROOT/env.sh

AVAILABLE_GPUS=($(echo $SLURM_JOB_GPUS | sed -e 's/,/ /g'))
export CUDA_VISIBLE_DEVICES="${AVAILABLE_GPUS[${WM_PROCESS_INDEX}]}"
######################## Set up for running the dynamics #######################

# Set up the directory where data for this segment will be stored.
mkdir -pv ${WEST_SIM_ROOT}/${WEST_CURRENT_SEG_DATA_REF}

# Create a temporary directory in local scratch space, which will contain the
# output from the current segment.  Eventually, any data we desire will be 
# copied back to ${WEST_SIM_ROOT}/${WEST_CURRENT_SEG_DATA_REF}, but first
# writing to local scratch space tends to be kinder to the storage system
# and the cluster's network.
CURRENT_SEG_WORKDIR=${WORKDIR}/${WEST_CURRENT_SEG_DATA_REF}
mkdir -pv $CURRENT_SEG_WORKDIR
cd $CURRENT_SEG_WORKDIR

# Make a symbolic link to the topology file. This is not unique to each segment.
# To reduce usage of globally-accessible disks, the amber_config directory 
# should have been copied over to the node already, by the script `node.sh`.
ln -sv $WORKDIR/amber_config/proteinA.parm7 .

# Either continue an existing tractory, or start a new trajectory. Both cases are identical

# The weighted ensemble algorithm requires that dynamics are stochastic.
# We'll use the "sed" command to replace the string "RAND" with a randomly
# generated seed.
sed "s/RAND/$WEST_RAND16/g" \
  ${WORKDIR}/amber_config/prod.in > current.in

# This trajectory segment will start off where its parent segment left off.
# The "ln" command makes symbolic links to the parent segment's rst file.
#This is preferable to copying the files, since it doesn't
# require writing all the data again.
if [ "$WEST_CURRENT_SEG_INITPOINT_TYPE" = "SEG_INITPOINT_CONTINUES" ]; then
  ln -sv $WEST_SIM_ROOT/$WEST_PARENT_DATA_REF/seg.rst ./parent.rst
fi

if [ "$WEST_CURRENT_SEG_INITPOINT_TYPE" = "SEG_INITPOINT_NEWTRAJ" ]; then
  ln -sv $WEST_PARENT_DATA_REF ./parent.rst
fi

############################## Run the dynamics ################################
# Propagate the segment using pmemd.cuda 
${PMEMD} \
  -p proteinA.parm7\
  -i current.in \
  -c parent.rst \
  -o seg.out \
  -inf seg.nfo \
  -l seg.log \
   -x seg.nc \
   -r seg.rst

########################## Calculate and return data ###########################

# Calculate the progress coordinate
TEMP=$(mktemp)
CMD="     parm $WORKDIR/amber_config/proteinA.parm7 \n"
CMD="$CMD reference ${REFERENCE} \n"
CMD="$CMD trajin parent.rst \n"
CMD="$CMD trajin seg.nc \n"
CMD="$CMD rms core !@H=&(:12|:16|:17|:30|:31|:34|:42|:44|:45|:48|:51) ref ${REFERENCE} out $TEMP \n"
CMD="$CMD strip :WAT,Na+ \n"
CMD="$CMD trajout solute.nc \n"
CMD="$CMD go\n"

echo -e "$CMD" | cpptraj

cat $TEMP | tail -n+2 | awk '{print $2}' > $WEST_PCOORD_RETURN

# Output random seed.
echo $WEST_RAND16 > $WEST_RAND_RETURN

# Copy the desired files back to globally-accessible storage space. Everything
# else we be deleted.
rsync seg.rst ${WEST_SIM_ROOT}/${WEST_CURRENT_SEG_DATA_REF}/
rsync solute.nc ${WEST_SIM_ROOT}/${WEST_CURRENT_SEG_DATA_REF}/

# Clean up all the files that we don't need to save.
rm -f ${CURRENT_SEG_WORKDIR}/*
rmdir ${CURRENT_SEG_WORKDIR}

