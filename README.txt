Spaghetti code to read TAPE21 (and TAPE15) files from ADF LR-TDDFT calculation. It provides the CT number based on the analysis proposed by F. Plasser and H. Lischka JCTC, 9, 2777, (2012). 

Mainly, driver_td_analy.sh Bash file drives the two python files to read the TAPEs and the fortran CT_dipole_FO.f90 file that makes the CT calculation. 
 
It requires the installation of qmworks (eScience) and blas/lapack libraries. 



-) How it works:
##################################

Getting fragment contributions to tdm is a two-step process, but first all:

    source activate qmworks

Then:

1) ./driver_td_analy.sh (that sources 'functions.h' and calls 'read_TAPES.py')
   It will generate: D.dat, coeff_sfos.dat files needed to run density_matrix_AO.f90
   Additionally, it will also create a 'list.dat' file containing the listing for the 
   CT.inp required by CT_dipole_FO.f90

-) About the accuracy vs Theodore:
##################################
-) IF YOU WANT TO COMPARE RESULTS TO THEODORE, please make sure you compare two calculations coming from the SAME TAPE21!!! 

-) The acuracy can be up to the 3rd decimal, e.g. for job.dimer.inp in a supramolecular form:

                           CT                 Program
       ------------------------------------------------
       1st exciatation: 0.938584             Theodore
      	          0.93858084360775462  Mine
      
       2nd exciatation: 0.792798             Theodore 
      	          0.79282030238242851  Mine
      
       3rd exciatation: 0.062706             Theodore 
      	          0.062694666863205697 Mine 
      
       4th exciatation: 0.236759             Theodore 
                        0.23670717540757200  Mine
      
       5th exciatation: 0.998351             Theodore 
                        0.99835442743852254  Mine

-) If you use predefine fragments the accuracy is always fine wrt to SFOTRAN (theodore is not compatible with this fashion).
   If not check the ordering of ./CT_dipole_FO.inp
   e.g. for job.dimer_sfo.inp 
     
                   This program                                                           ADF 
   -------------------------------------------------------------------------------------------------------------------------------------
   *------------------------------------*                  |    Transition dipole moments mu (x,y,z) in a.u.
    Working on exitation           1                       |    (weak excitations are not printed)
   *------------------------------------*                  |    
   Eigenvenctor D.dat matrix has been broaden              |    no.  E/eV          f                       mu (x,y,z)
   here it is ok                                           |    ------------------------------------------------------------------
   *-------*                                               |      1  5.4149     0.58700E-02  0.50962E-01 -0.20309     -0.20134E-01
     Summation of AA terms:    0.0778                      | 
     Summation of AB terms:    0.9213                      |
     Summation of BA terms:    0.0000                      |   
     Summation of BB terms:    0.0008                      |    Total X transition dipole moment from all SFO-SFO
   CT number is:  0.92138924505931075                      |    contributions    0.50961E-01                                                
   with a normalization factor  0.99999999999999889        |                                                                                
   *-------*                                               |    FRAGMENT ----> FRAGMENT INFORMATION                                         
   Calculation of t.d.m. in terms of AO/FOs:               |                                                                                
   *-------*                                               |    F -> F     Cont. to TDM   Cum. Cont. TDM      Dev.      weight wav.fu.      
   T.d.m A --> A terms: -0.20379782855162196               |    1 -->    1   -0.20380       -0.20380        0.25476        0.49689E-01      
   T.d.m A --> B terms:   2.4221364306611308E-002          |    2 -->    1    0.14875       -0.55047E-01    0.10601        0.94957          
   T.d.m B --> A terms:  0.14875035699218342               |    2 -->    2    0.81787E-01    0.26740E-01    0.24221E-01    0.70961E-03      
   T.d.m B --> B terms:   8.1787332841782912E-002          |    1 -->    2    0.24221E-01    0.50961E-01    0.41633E-16    0.30508E-04      
   Total t.d.m. componentX=   5.0961225588955751E-002 a.u. |        
   *-------*                                               |        
   T.d.m A --> A terms: -0.26648682843792143               |        
   T.d.m A --> B terms:   2.2784226343808431E-002          |        
   T.d.m B --> A terms:  -2.1614578642815442E-002          |        
   T.d.m B --> B terms:   6.2229314932746894E-002          |        
   Total t.d.m. componentY= -0.20308786580418134      a.u. |        
   *-------*                                               |        
   T.d.m A --> A terms: -0.23849870997167744               |        
   T.d.m A --> B terms:   2.2532976028591931E-002          |        
   T.d.m B --> A terms:  0.13428759785671246               |        
   T.d.m B --> B terms:   6.1543545500008803E-002          |        
   Total t.d.m. componentZ=  -2.0134590586364333E-002 a.u. |        
   |Module t.d.m.|=  0.21035001661161359      a.u.         |        

-) Advantages vs THEODORE 
##################################
   1) CT calculation in predefined fragments. 
   2) Dipole framentation on TAPE21 without asking for the more advance SFOTRANS option
