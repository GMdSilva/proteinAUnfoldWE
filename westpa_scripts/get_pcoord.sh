#!/bin/bash
#
# get_pcoord.sh
#
# This script is run when calculating initial progress coordinates for new 
# initial states (istates).  This script is NOT run for calculating the progress
# coordinates of most trajectory segments; that is instead the job of runseg.sh.

# If we are debugging, output a lot of extra information.
if [ -n "$SEG_DEBUG" ] ; then
    set -x
    env | sort
fi

# Make sure we are in the correct directory
cd $WEST_SIM_ROOT

TEMP=$(mktemp)
CMD="     parm $WEST_SIM_ROOT/amber_config/proteinA.parm7 \n"
CMD="$CMD reference $WEST_SIM_ROOT/reference/proteinA.pdb [ref] \n"
CMD="$CMD trajin $WEST_STRUCT_DATA_REF \n"
CMD="$CMD rms core !@H=&(:12|:16|:17|:30|:31|:34|:42|:44|:45|:48|:51) ref [ref] out $TEMP\n"
CMD="$CMD go\n"

echo -e "$CMD" | cpptraj

cat $TEMP | tail -n 1 | awk '{print $2}' > $WEST_PCOORD_RETURN

# Remove the temporary file to clean up.
rm $TEMP
