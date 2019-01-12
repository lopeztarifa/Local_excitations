#T ms.KFReader("TAPE21")Python program that reads:
# eingenvectors, NTOT (#of total SFOs),NEXCITATIONS (#of excitations),  NATOMS (# of atoms),  
# NELECTRONS (#of total electrons) from a ADF TAPE21 file using Plams.  
#  
import numpy as np
import plams
plams.init()
kf = plams.KFReader("TAPE21")
#
NTOT = kf.read("SFOs","number")
NEXCITATIONS = kf.read("Excitations SS A","nr of excenergies")
NATOMS = kf.read("Geometry","nr of atoms")
#NFRAG = kf.read("Geometry","nr of fragments")
NELECTRONS = kf.read("General","electrons")
#F=kf.read("Excitations SS A","oscillator strengths")
EEXCITATIONS = kf.read("Excitations SS A","excenergies")
KSENERGIES=kf.read("A","eps_A")
print(NTOT,NEXCITATIONS,NATOMS,NELECTRONS)
print (EEXCITATIONS)
#print (F)
print (KSENERGIES)

for i in range(1, NEXCITATIONS+1):
    s = "eigenvector {}".format(i)
    x = kf.read("Excitations SS A", s)
    print(x)

y = kf.read("A","Eig-CoreSFO_A")
print(y)
# Pipe said:
#arr = np.empty((5,180))
#for i in range(1, NEXCITATIONS):
#    s = "eigenvector {}".format(i)
#    x = kf.read("Excitations SS A", s)
#    arr[i] = np.array(x).reshape(180)
#    print(x)
#np.savetxt('D.dat', arr)
#print NEXCITATIONS
