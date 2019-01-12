# FUNCTIONS for helping out driver_td_analy.sh 
# PLT&LV@VU(2016) 
print_info () { if [ $1 == python ] ; then echo "#### Python-plams has finished"; fi
                if [ $1 == adf ] ; then echo "#### Looking for information in ADF output ..."; fi
                if [ $1 == cut ] ; then echo "#### Chop of $2 is done!  ..."; fi
                if [ $1 == list ] ; then echo "#### Aditional list.dat for CT.inp has been generated!"; fi
                if [ $1 == parallel_start ] ; then echo ""; 
			echo "	PARALLEL chop has been activated according to the SFOxPROC variable"; 
			echo "		parallel info (";fi
                if [ $1 == parallel_end ] ; then echo "				) ";fi
                if [ $1 == dipole ] ; then \
	                echo ""
        	        echo "There is a TAPE15 in the present folder, therefore"
                	echo "an analysis of the TDM will be done in the FO basis."
                	echo ""
		fi
}
chop () {
      if [ $1 == 1 ] && [ $2 == $NTOT ] ; then \
      increment=0
        for ((k=1;k<$(($2+1));k++))
          do cut -f $((1+$increment))-$(($increment+$2))  -d "," $3 | sed s/\,//g | xargs -n 1  >> chop.$k 
           increment=$(($2*$k))
        done 
       else \
      increment=$((($1-1)*$NTOT))
         for ((k=$1;k<$(($2+1));k++))
           do cut -f $((1+$increment))-$(($increment+$NTOT))  -d "," $3 | sed s/\,//g | xargs -n 1  >> chop.$k 
           increment=$(($NTOT*$k))
          done 
       fi 
}
chop_parallel () {
#
# function that divides 'chop $3' data according to SFOxPROC given in field $1
#
        entire=`echo "$NTOT/$1"|bc ` 			#; echo "ENTIRE $entire" #SFO will be divided in groups of (SFOxPROC)-MOs 
        rest=`echo "$NTOT-($entire*$1)"|bc -l ` 	#; echo "REST $rest" 
        nprocess=`echo "$entire/2"|bc ` 		#; echo "NPROCESS $nprocess"  # number of double processes
        nsingle=`echo "$entire-(2*$nprocess)"|bc ` 	#; echo "NSINGLE $nsingle"  # measures the if there is any half double cycle.
        COUNT=0 ; INIT=1
# Double processes in paralle;l
	for ((i=1;i<$(($nprocess+1));i++))
         do  \
          echo "		#loop pair $i"
          echo "		choping $(($INIT+($1*$COUNT)))  $((($COUNT+1)*$1))"
	  chop $(($INIT+($1*$COUNT))) $((($COUNT+1)*$1)) $2 &
	  COUNT=$(($COUNT+1))
          echo "		...and $(($INIT+($1*$COUNT)))  $((($COUNT+1)*$1))"
	  chop $(($INIT+($1*$COUNT))) $((($COUNT+1)*$1)) $2 &
	  COUNT=$(($COUNT+1))
          wait
         done
# no-divisible processes:
         if  [ $nsingle -ne 0 ]; then \
         echo "		chopping $(($COUNT*$1+1)) to $NTOT in one process"
          chop  $(($COUNT*$1+1)) $NTOT $2
         fi
}
