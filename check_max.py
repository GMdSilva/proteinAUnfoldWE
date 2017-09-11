#!/usr/bin/env python
import h5py

class Check(object):
    def __init__(self):
        westh5 = h5py.File('west.h5','r')
        for key in westh5['iterations'].keys():
            i = key[5:]
            m = westh5['iterations'][key]['pcoord'][...].max()
            print("Iteration {:s}: {:.03f}".format(i, m))
        westh5.close()

if __name__ == "__main__":
    Check() 
