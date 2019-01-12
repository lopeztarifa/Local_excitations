#!/bin/bash
#######################################################################
# Stupid bash driver to generate D.dat and coeff_sfos.dat files needed#
# to run density_matrix_AO.f90.                                       #
# Additionally it also creates:                                       #
# -) exc_energies.dat, file including the oscillator strengths.       #
# -) KS_energies.dat, KS energies of the optimized MO.                #
# -) list.dat that will help you to build-up the CT.inp               #
#######################################################################
# What is needed?                                                     #
# --------------                                                      #
# TAPE21 and job.out, the scripts will make the rest                  #
# (if there is a TAPE15 present, it will be read to get <SFO|Mu|SFO>  # 
#  values).                                                           # 
# --------------                                                      #
# To further use density_matrix_AO.f90 you need also a CT.inp         # 
#######################################################################
# PLT&LV@VU(2016)                                                     #
# modified on 02/2017                                                 #
#######################################################################
#
SFOxPROC=50 # limit to start parallizing the construction of coef_sfo.dat
OUTPUTFILE=job.dimer.out
#
# Check files:
#
   source functions.h &>/dev/null
       if [ $? != 0 ]; then echo 'functions.h is missed!'; exit; fi
. ./functions.h
#
   ls $OUTPUTFILE &>/dev/null
       if [ $? != 0 ]; then echo "$OUTPUTFILE is missed!"; exit; fi
#
rm -rf coeff_sfos.dat list.dat
#
#######################################################################
##### D.dat generation by calling plams                               # 
#######################################################################
#
export PYTHONPATH=$PYTHONPATH:/Users/pablo/Programs/adf-SVN/scripting/plams/src/scm/
#
# Eingen vector are taken directly from TAPE21
#
   ls TAPE15 &>/dev/null
	if [ $? != 0 ]; then \
		python read_TAPE21.py  > temp
		DIPO=NO
	else 
		print_info dipole
		python read_TAPES.py  > temp
		DIPO=YES
	fi
# Bulk python data in temp is analysed 
	cat temp | sed -e s/"\["//g -e  s/"\]"//g -e /PLAMS/d > temp2 
		NLINES=$(wc -l temp2| sed s/temp2//g) ; NLINES1=$(($NLINES-1))
		NTOT=$(head -1 temp2|awk '{print $1}')
		NEXCITATIONS=$(head -1 temp2|awk '{print $2}'); NEXCITATIONS2=$(($NEXCITATIONS+2))
		NATOMS=$(head -1 temp2|awk '{print $3}')
		NELECTRONS=$(head -1 temp2|awk '{print $4}')
                NOCC=`echo "$NELECTRONS/2"|bc ` 
                NVIRT=$(($NTOT-$NOCC))
        echo "NTOT=$NTOT, NOCC=$NOCC, NVIRT=$NVIRT, NATOMS=$NATOMS, NEXCIATIONS=$NEXCITATIONS"
	print_info python 
	cat temp2 | tail -$NLINES1  > temp # we get rid off first line that has been already stored 
# Writting oscillators strengths to exc_energies.dat: 
        head -1 temp > excit_energies.dat 
# Writting MO energies to KS_energies.dat 
        head -2 temp | tail -1 > KS_energies.dat
# Writting eigenvectors to D.dat
	print_info adf 
        cat temp | head -$NEXCITATIONS2 | tail -$NEXCITATIONS > D.dat 
# IF DIPOLE CALCULATION WE SAVE THE <SFO|MU|SFO> 
	if [ $DIPO = YES ] ; then \
          tail -4 temp | head -1 > tempX.dat 
          tail -3 temp | head -1 > tempY.dat 
          tail -2 temp | head -1 > tempZ.dat 
#
	  DIRECTION=(
                "X"
	        "Y" 
	        "Z"
                 )
#
	  for l in {0..2} ; do \
          	if [ $NTOT -ge $SFOxPROC ] ;  then \
			print_info parallel_start
        		chop_parallel $SFOxPROC temp${DIRECTION[$l]}.dat
			print_info parallel_end
        	else chop 1 $NTOT temp${DIRECTION[$l]}.dat # the chop is on a sigle shot
        	fi  
#
		ulimit -Sn 4000 # The soft limit
        	a=$(ls chop.*  | sort -t . -k 2 -g); paste $a >  mu${DIRECTION[$l]}.dat 
		print_info cut dipole_${DIRECTION[$l]} ; rm -f chop*  
	  done
	fi
# END DIPOLE
# Now, coeff_sfos.dat from raw data of temp2
        cat temp | tail -1 > temp2 
#
        if [ $NTOT -ge $SFOxPROC ] ;  then \
		print_info parallel_start
        	chop_parallel $SFOxPROC temp2 
		print_info parallel_end
         else chop 1 $NTOT temp2 # the chop is on a sigle shot
        fi  
#
	ulimit -Sn 4000 # The soft limit
        a=$(ls chop.*  | sort -t . -k 2 -g); paste $a >  coeff_sfos.dat 
	print_info cut coefficients
#
#######################################################################
##### additional info is given in list.dat to generate the CT.inp     
#     needed to run density_matrix_AO.f90  
#######################################################################
#
# Now we give for free the ordering asked for CT.inp: 
#
	grep -$((($NTOT*2)+2)) indx $OUTPUTFILE |tail -f -$((($NTOT*2)+2)) \
            | sed -e /"----"/d -e /^$/d -e /"("/d | awk '{print $10}'> temp
	grep -$((($NATOMS)+1)) "Atoms in this Fragment" $OUTPUTFILE |tail  -$(($NATOMS)) \
        |awk '{print $3}' > temp1
#
	a=($(grep -$((($NTOT*2)+2)) indx $OUTPUTFILE |tail -f -$((($NTOT*2)+2)) \
             | sed -e /"----"/d -e /^$/d -e /"("/d | awk '{print $10}'))   #it will store the atom label for each MO
	adforder=($(grep -$((($NATOMS)+1)) "Atoms in this Fragment" $OUTPUTFILE |tail  -$(($NATOMS)) \
        |awk '{print $3}'))
#
        atom=1 ; orbitals=1 # for a given atom I will count how many orbitals it has 
        rm -rf temp2
        for ((i=0;i<$(($NTOT));i++)); do \
         if [ $i != 0 ] ; then 
          if [ ${a[$i]} == ${a[$((i-1))]} ] ; then \
           orbitals=$(($orbitals+1)); 
           else echo $atom $orbitals >> temp2 
           atom=$(($atom+1)); orbitals=1 # I change atom and reset orbitals
          fi  
         fi  
        done
#
        echo $atom $orbitals >> temp2  # the very last one of the list is printed
        orbitals=($(cat temp2 | awk '{print $2}'))
        rm -rf list.dat
        for ((i=0;i<$NATOMS;i++)); do  
           echo ${adforder[$i]} ${orbitals[$i]} >> list.dat
        done
#
        print_info list 
#             
rm -rf plams.* temp* chop*
