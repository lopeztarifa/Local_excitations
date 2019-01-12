#######################################################################
# Python scripts that reads information from ADF TAPE21 file using    #
# plams.                                                              # 
#######################################################################
# Information is printed in the standart output, all at once:         #
#                                                                     #
# -) 1st line, contains:                                              #
#    NTOT (#of total SFOs),NEXCITATIONS (#of excitations),            # 
#    NATOMS (# of atoms),  NELECTRONS (#of total electrons).          #
#                                                                     #
# -) 2nd line, contains:                                              #
#    energies of the exciations.                                      # 
#                                                                     #
# -) 3rd line, contains:                                              #
#    KS_orbital_energies.                                             # 
#                                                                     #
# -) lines from 4th to NEXCIATIONS+3, contains:                       #
#    one-electron transition density matrix of each excitation.       #
#                                                                     #
# -) then three lines co 
# -) lines from 4th to NEXCIATIONS+3, contains:                       #
#                                                                     #
#######################################################################
#######################################################################
# PLT@VU(2017)                                                        #
#######################################################################
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
#######################################################################
#
# Printing of NTOT,NEXCITATIONS,NATOMS,NELECTRONS, #1 line:
#
print(NTOT,NEXCITATIONS,NATOMS,NELECTRONS)
#
# Printing of the energies of the exciations, #2 line:  
#
print (EEXCITATIONS)  
#
# Printing of the KS_orbital_energies, #3 line: 
#
print (KSENERGIES)
#
# Printing of one-electron transition density matrix (from #4 to NEXCIATIONS+3):
#
for i in range(1, NEXCITATIONS+1):
    s = "eigenvector {}".format(i)
    x = kf.read("Excitations SS A", s)
    print(x)
#
# Printing of tmd in the sfo basis, i.e. <SFO|Mu|SFO>: 
#
kf = plams.KFReader("TAPE15")
#
directions = ['x', 'y', 'z']
for k in directions:  
    s = "SFOdipmat_{}".format(k)
    x = kf.read("Matrices", s)
    print(x)
#
# coefficients of the MO in the AO or FO basis: last line 
#
kf = plams.KFReader("TAPE21")
y = kf.read("A","Eig-CoreSFO_A")
print(y)
#
