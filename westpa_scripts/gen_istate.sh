#!/bin/bash

if [ -n "$SEG_DEBUG" ] ; then
    set -x
    env | sort
fi

cd $WEST_SIM_ROOT

ISTATE_DIR=$(dirname "${WEST_ISTATE_DATA_REF}")
if [ ! -d "${ISTATE_DIR}" ]; then
  mkdir ${ISTATE_DIR}
fi
ln -s $WEST_BSTATE_DATA_REF $WEST_ISTATE_DATA_REF
