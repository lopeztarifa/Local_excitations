!---------------------------------------------------------------------!
      PROGRAM DENSITY_MATRIX_AO 
      IMPLICIT NONE
!---------------------------------------------------------------------!
! Stupid program that calculates the charge-transfer character of an  !
! electronic excitation by analysing the one-electron transition      !
! density  matrix in terms of local orbitals.                         !
!---------------------------------------------------------------------!
! Based on: F. Plasser and H. Lischka JCTC, 9, 2777, (2012).          !
! --------                                                            !
!---------------------------------------------------------------------!
!                                                                     !
! CT = SUM_aEA SUM_bEB (DS)ab*(SD)ab                                  ! 
!                                                                     !
!   ... and MUST be expanded! (from OxV to TxT)                       !
!---------------------------------------------------------------------!
! Based on: F. Plasser and H. Lischka JCTC, 9, 2777, (2012).          !
! --------                                                            !
!---------------------------------------------------------------------!
! PLT&LV@VU(2016)                                                     !
!---------------------------------------------------------------------!
      CHARACTER(6):: CALTYPE, DIPOTYPE, XCTYPE
      INTEGER NOCC, NVIRT, NEXCITATIONS, NTOT, NHALF
      INTEGER NATOMS, NFRAG, NAPF 
      REAL*8, allocatable:: CMOAO(:,:)
!      REAL*8, allocatable:: CMOFO(:,:),CFOAO(:,:)
      INTEGER, allocatable:: FRAG(:,:),NOPA(:,:)
      REAL*8, allocatable:: EIGEN(:,:),D(:,:)
      REAL*8, allocatable:: KS_E(:,:), E_EXCI(:,:), KS_Diff(:,:)
      REAL*8, allocatable:: MUX(:,:), MU_SFOX(:,:), MU_MO(:,:)
      REAL*8, allocatable:: MUY(:,:), MU_SFOY(:,:)
      REAL*8, allocatable:: MUZ(:,:), MU_SFOZ(:,:)
      REAL*8, allocatable:: CT(:,:), CINV(:,:), CINVT(:,:)
      REAL*8, allocatable:: WORKSHORT(:,:), WORKLARGE(:,:), S_AO(:,:)
!      REAL*8, allocatable:: D_AO(:,:)
      REAL*8, allocatable:: PROD(:,:), INV(:,:),OMG(:,:)
      REAL*8:: THRES, OMEGA, NORM, CONSTANT
      REAL*8:: DIPO, DIPOX, DIPOY, DIPOZ
      REAL*8:: TWO  
      INTEGER I, J, K, L
      PARAMETER (TWO=2.0D0)
! Pablo test
      REAL*8, allocatable:: TEST(:,:), TEST2(:,:)
!      REAL*8, allocatable:: TESTF(:,:,:)
      REAL*8, allocatable:: M1(:,:),M2(:,:)
! End Pablo test
!----------------------------------------------------------------------!
! ******** READING INPUTFILE ******************************************!
      OPEN(UNIT=10,FILE='CT_dipole_FO.inp')
      READ(10,*) CALTYPE, DIPOTYPE
      READ(10,*) XCTYPE 
      READ(10,*) NOCC, NVIRT, NEXCITATIONS 
      WRITE(*,*) CALTYPE, DIPOTYPE, XCTYPE
! 
! reading for information meant to reorder the DS_SD matrix
      READ(10,*) NATOMS
      READ(10,*) NFRAG
      NAPF= NATOMS/NFRAG ! Number of Atoms Per Fragment
      ALLOCATE(FRAG(NFRAG,NAPF),NOPA(NATOMS,2))
      DO I=1,NFRAG
       READ(10,*) (FRAG(I,J),J=1,NAPF) ! Composition of each fragment.
      ENDDO
      DO I=1,NATOMS
       READ(10,*) (NOPA(I,J),J=1,2) ! Number of Orbital Per Atom. It will keep the original ordering from the ADF calculation.  
      ENDDO
      WRITE(*,*) "The number of occupied MOs is:", NOCC
      WRITE(*,*) "The number of virtual MOs is:", NVIRT
      WRITE(*,*) "The number of excitations is:", NEXCITATIONS 
! 
      NTOT=NOCC+NVIRT
      NHALF=NTOT/2
! ******** ARRAY ALLOCATION  ******************************************!
      ALLOCATE(CMOAO(NTOT,NTOT))
!      ALLOCATE(CMOFO(NTOT,NTOT),CFOAO(NTOT,NTOT))
      ALLOCATE(EIGEN(NEXCITATIONS,NOCC*NVIRT),D(NTOT,NTOT))
      ALLOCATE(KS_E(1,NTOT),E_EXCI(1,NEXCITATIONS),KS_Diff(NTOT,NTOT)) 
      ALLOCATE(MUX(NTOT,NTOT),MU_SFOX(NTOT,NTOT),MU_MO(NTOT,NTOT))
      ALLOCATE(MUY(NTOT,NTOT),MU_SFOY(NTOT,NTOT))
      ALLOCATE(MUZ(NTOT,NTOT),MU_SFOZ(NTOT,NTOT))
      ALLOCATE(WORKSHORT(NOCC,NVIRT),WORKLARGE(NTOT,NTOT))
      ALLOCATE(CT(NTOT,NTOT),PROD(NTOT,NTOT))
      ALLOCATE(CINV(NTOT,NTOT),CINVT(NTOT,NTOT))
      ALLOCATE(OMG(NTOT,NTOT))
      ALLOCATE(TEST(NTOT,NTOT), TEST2(NTOT,NTOT))
!      ALLOCATE(D_AO(NTOT,NTOT))
!      ALLOCATE(S_AO(NTOT,NTOT))
!      ALLOCATE(OMG(NTOT,NTOT))
!!!
!! Pablo test
!     allocate(TEST(NTOT,NTOT), TEST2(NTOT,NTOT))
!! End Pablo test
!! ******** FILE OPENING ***********************************************!
      OPEN(UNIT=1,FILE='coeff_sfos.dat')
      OPEN(UNIT=2,FILE='D.dat')        ! one-electron transition density matrix read from ADF-svn
!
      IF(CALTYPE=='CT') THEN
       OPEN(UNIT=20,FILE='OMG1.dat')
       OPEN(UNIT=30,FILE='OMG2.dat')
       OPEN(UNIT=40,FILE='OMG3.dat')
       OPEN(UNIT=50,FILE='OMG4.dat')
       OPEN(UNIT=60,FILE='OMG5.dat')
      ENDIF
!
!      OPEN(UNIT=13,FILE='INV.dat')
!      OPEN(UNIT=14,FILE='D_AO.dat')
!      OPEN(UNIT=15,FILE='S_AO.dat')
!      OPEN(UNIT=16,FILE='DS.dat')
!      OPEN(UNIT=17,FILE='SD.dat')
!      OPEN(UNIT=666,FILE='test1.dat')
!      OPEN(UNIT=667,FILE='test2.dat')
!
! ******* READING INFORMATION FROM OPEN FILES  ************************!
! Reading coefficients MO->AO from coeff_sfos.dat generated by get_D.py script.  
! Plasser puts C as MOLDEN format, but the computation is used as in ADF.  
      DO I=1,NTOT 
       READ(1,*) (CMOAO(I,J),J=1,NTOT)
      ENDDO
! If the ADF calculation is constructed by previous fragment calculations: 
! Read CMOFO(NTOT,NTOT): coefficients MO->FO
!       DO I=1,NTOT 
!        READ(1,*) (CMOFO(I,J),J=1,NTOT)
!       ENDDO
! Reading density matrix from D.dat from get_D.py output: 
      DO I=1,NEXCITATIONS
        READ(2,*) (EIGEN(I,J),J=1,NOCC*NVIRT)
      ENDDO
! Reading density matrix from D.dat from adf-svn. 
      IF(DIPOTYPE=='DIPO') THEN 
       OPEN(UNIT=21,FILE='KS_energies.dat') ! MO energies 
       OPEN(UNIT=22,FILE='excit_energies.dat')! Excitation energies 
       OPEN(UNIT=23,FILE='muX.dat')         ! SFOs transition dipole moment 
       OPEN(UNIT=24,FILE='muY.dat')         ! SFOs transition dipole moment 
       OPEN(UNIT=25,FILE='muZ.dat')         ! SFOs transition dipole moment 
! Reading of KS_energies.dat and exc_energies.dat coming from get_D.py 
        READ(21,*) (KS_E(1,I),I=1,NTOT)
        READ(22,*) (E_EXCI(1,I),I=1,NEXCITATIONS)
! Reading of SFO/SFO transition dipole moments from muX.dat, muY.dat &  muZ.dat 
       DO I=1,NTOT
        READ(23,*) (MU_SFOX(I,J),J=1,NTOT)
        READ(24,*) (MU_SFOY(I,J),J=1,NTOT)
        READ(25,*) (MU_SFOZ(I,J),J=1,NTOT)
       ENDDO
! KS_Diff is created, i.e. and array containint the energy separation between the KS_orbitals
       DO I=1,NTOT
        DO J=1,NTOT
         KS_Diff(I,J)=SQRT(TWO*(ABS(KS_E(1,J)-KS_E(1,I)))) ! The SQRT(TWO... factor is included. 
        ENDDO
       ENDDO
      ENDIF
!
! ******* CALCULATION: C^T, C^-1 and C^(-1,T) on the CMOAO matrix *****!
      CALL TRANSPOSE(CMOAO,NTOT,NTOT,CT)       ! C^T 
      CALL INVERSION(CMOAO,NTOT,NTOT,CINV)     ! C^-1
      CALL TRANSPOSE(CINV,NTOT,NTOT,CINVT) ! C^(-1,T)
! Overlap:
!S_AO=C^-(1,T)*C^(-1) (Assuming that MOs are normalized, ie. S_MO is the identity)
!      CALL PRODUCT(CINVT,CINV,NTOT,NTOT,TEST)
!      CALL WRTARRAY(TEST,NTOT,NTOT,666,'inraw')
!
! ******* MAIN LOOP OVER NEXCIATIONS **********************************!
! Lowpez
      DO K=1,NEXCITATIONS     ! Main loop
       CALL AZZERO(WORKLARGE,NOCC,NVIRT)     ! reset work array
       CALL AZZERO(WORKSHORT,NOCC,NVIRT)     ! reset work array
       CALL AZZERO(D,NTOT,NTOT)              ! reset transition density matrix
       CALL AZZERO(OMG,NTOT,NTOT)            ! reset OMG matrix 
! Testing section
!       CALL AZZERO(TEST,NTOT,NTOT)          ! reset OMG matrix 
! swaps in orbitals
!      DO I=1,NTOT
!! here intruduce the orbital to change sign:
!       DO J=1,NTOT
!        CMOAO(I,J)=-CMOAO(I,J)
!       ENDDO
!      ENDDO
! End swaps
! End Testing
! 
! First we 'chop' the eigen(k,I) row to make it handy:
!
       L=0
       DO I=1,NOCC
        DO J=1,NVIRT
         WORKSHORT(I,J)=EIGEN(K,(L*NVIRT)+J)
        ENDDO
         L=L+1
       ENDDO
! Printing some info:
       WRITE(*,*) ""
       WRITE(*,*) "*------------------------------------*"
       WRITE(*,*) " Working on exitation", K
       WRITE(*,*) "*------------------------------------*"
!
! Now we expand the eigenvectors matrix to D(NTOTxNTOT)  
!
       DO I=1,NTOT 
        IF(I.GT.NOCC) THEN
         DO J=1,NTOT 
          D(I,J)=0.0D0 
         ENDDO
        ELSE
         DO J=1,NTOT
          IF((J.LT.NOCC).OR.(J.EQ.NOCC)) THEN
           D(I,J)=0.0D0
          ELSE
           D(I,J)=WORKSHORT(I,J-NOCC) 
          ENDIF
         ENDDO
        ENDIF
       ENDDO
       WRITE(*,*) "Eigenvenctor D.dat matrix has been broaden" 
!
! Calculation of the CT number, OMEGA
!
       CALL AZZERO(WORKLARGE,NTOT,NTOT)
       CALL GETOMG(CMOAO,D,CT,CINV,CINVT,NTOT,NTOT,OMG) ! non-normalized OMG matrix is calculated. 
       CALL NORMALIZE(OMG,NTOT,NTOT,NORM)
       CALL ARRANGEOMG(OMG,FRAG,NOPA,NTOT,NFRAG,NAPF,NATOMS,WORKLARGE) ! normalized OMG matrix is arranged according to the input expecifications
!
! Writing of OMG matrix for each of the exciations 
!
       IF(CALTYPE=='CT') THEN
!        IF (K.EQ.1)   CALL WRTARRAY(OMG,NTOT,NTOT,20,'inraw')
!        IF (K.EQ.2)   CALL WRTARRAY(OMG,NTOT,NTOT,30,'inraw')
!        IF (K.EQ.3)   CALL WRTARRAY(OMG,NTOT,NTOT,40,'inraw')
!        IF (K.EQ.4)   CALL WRTARRAY(OMG,NTOT,NTOT,50,'inraw')
!        IF (K.EQ.5)   CALL WRTARRAY(OMG,NTOT,NTOT,60,'inraw')
! CT Calculation
        CALL CALCT(WORKLARGE,NTOT,NTOT,OMEGA,'CT')
        WRITE(*,*) "CT number is:", OMEGA 
        WRITE(*,*) "with a normalization factor", NORM
       ENDIF
!
! Calculation of DIPOLE MOMENT,  
!
       IF(DIPOTYPE=='DIPO') THEN 
        WRITE(*,*) "*-------*"
        WRITE(*,*) "Calculation of t.d.m. in terms of AO/FOs:"
        CALL AZZERO(WORKLARGE,NTOT,NTOT)
        CALL AZZERO(PROD,NTOT,NTOT)
       IF(XCTYPE=='GGA') THEN
        CONSTANT=1.0D0/SQRT(E_EXCI(1,K))
        CALL MATRIXBYCONSTANT(KS_Diff,NTOT,NTOT,CONSTANT,WORKLARGE)
        CALL HADAMARDPRODUCT(WORKLARGE,D,NTOT,NTOT,PROD)      ! Calculation of D' 
        CALL AZZERO(WORKLARGE,NTOT,NTOT)
        CALL TRANSPOSE(PROD,NTOT,NTOT,WORKLARGE)                   ! D'^T 
       ELSE IF (XCTYPE=='HYBRID') THEN
        CONSTANT=SQRT(2.0D0)
        CALL MATRIXBYCONSTANT(D,NTOT,NTOT,CONSTANT,PROD)
        CALL TRANSPOSE(PROD,NTOT,NTOT,WORKLARGE)
       ENDIF
! 
        CALL AZZERO(PROD,NTOT,NTOT)
        CALL PRODUCT(CMOAO,WORKLARGE,NTOT,NTOT,PROD)                   ! CxD'^T 
        CALL PRODUCT(PROD,CT,NTOT,NTOT,MU_MO)                      !(CxD'^T)xC^T
!
! X component
!
        CALL AZZERO(WORKLARGE,NTOT,NTOT)
        CALL HADAMARDPRODUCT(MU_MO,MU_SFOX,NTOT,NTOT,MUX) 
        CALL ARRANGEOMG(MUX,FRAG,NOPA,NTOT,NFRAG,NAPF,NATOMS,WORKLARGE) 
        CALL CALCT(WORKLARGE,NTOT,NTOT,OMEGA,'DP')
        CALL NORMALIZE(WORKLARGE,NTOT,NTOT,DIPOX)
        WRITE(*,*) "Total t.d.m. componentX=",DIPOX, "a.u."
!
! Y component
!
        CALL AZZERO(WORKLARGE,NTOT,NTOT)
        CALL HADAMARDPRODUCT(MU_MO,MU_SFOY,NTOT,NTOT,MUY) 
        CALL ARRANGEOMG(MUY,FRAG,NOPA,NTOT,NFRAG,NAPF,NATOMS,WORKLARGE) 
        CALL CALCT(WORKLARGE,NTOT,NTOT,OMEGA,'DP')
        CALL NORMALIZE(MUY,NTOT,NTOT,DIPOY)
        WRITE(*,*) "Total t.d.m. componentY=",DIPOY, "a.u."
!
! Z component
!
        CALL AZZERO(WORKLARGE,NTOT,NTOT)
        CALL HADAMARDPRODUCT(MU_MO,MU_SFOZ,NTOT,NTOT,MUZ) 
        CALL ARRANGEOMG(MUZ,FRAG,NOPA,NTOT,NFRAG,NAPF,NATOMS,WORKLARGE) 
        CALL CALCT(WORKLARGE,NTOT,NTOT,OMEGA,'DP')
        CALL NORMALIZE(MUZ,NTOT,NTOT,DIPOZ)
        WRITE(*,*) "Total t.d.m. componentZ=",DIPOZ, "a.u."
!
! Total_dipole:
        DIPO=SQRT(DIPOX**2+DIPOY**2+DIPOZ**2) 
        WRITE(*,*) "|Module t.d.m.|=", DIPO, "a.u."
       ENDIF
!
      ENDDO  ! End of main loop on exciations
!
!     DEALLOCATE(CMOAO,CMOFO,M1,M2)
!
!10 FORMAT (F10.4, A4)
!----------------------------------------------------------------------!
       END PROGRAM DENSITY_MATRIX_AO 
! -------------------------------------------------------------------- C
!     SUBROUTINES #####################################################!
! -------------------------------------------------------------------- C
      SUBROUTINE WRTARRAY(M,DIM1,DIM2,UNITNUMBER,TAG)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! This subroutine write a M matrix.                                    !
! -------------------------------------------------------------------- C
      INTEGER:: I,J 
      INTEGER,intent(IN):: DIM1, DIM2 
      REAL(8), DIMENSION(DIM1,DIM2),intent(IN):: M
      INTEGER,intent(IN):: UNITNUMBER 
      CHARACTER(5),intent(IN):: TAG 
! -------------------------------------------------------------------- C
      IF (TAG=='short') THEN
       DO I=1,DIM1
        WRITE(UNITNUMBER,10) (M(I,J),J=1,DIM2)
       ENDDO
      ENDIF
      IF (TAG=='large') THEN
       DO I=1,DIM1
        WRITE(UNITNUMBER,20) (M(I,J),J=1,DIM2)
       ENDDO
      ENDIF
      IF (TAG=='inraw') THEN
       WRITE(*,*) "here it is ok"
       DO I=1,DIM1
        WRITE(UNITNUMBER,*) (M(I,J),J=1,DIM2)
       ENDDO
      ENDIF
  10 FORMAT (100F10.4)
  20 FORMAT (100F10.6)
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE AZZERO(M,DIM1,DIM2)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! This subroutine restarts to zero a M matrix.                         ! 
! -------------------------------------------------------------------- C
      REAL(8), DIMENSION(DIM1,DIM2),intent(INOUT):: M
      INTEGER,intent(IN):: DIM1, DIM2 
      INTEGER:: I,J 
! -------------------------------------------------------------------- C
      DO I=1,DIM1
       DO J=1,DIM2
        M(I,J)=0.0D0
       ENDDO
      ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE TRANSPOSE(M,DIM1,DIM2,SALIDA) 
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! This subroutine transpose a M given matrix.                          !
! -------------------------------------------------------------------- C
      INTEGER:: I,J
      INTEGER,intent(IN):: DIM1, DIM2 
      REAL(8), DIMENSION(DIM1,DIM2),intent(in):: M
      REAL(8), DIMENSION(DIM1,DIM2),intent(out):: SALIDA
! -------------------------------------------------------------------- C
      DO I=1,DIM1
       DO J=1,DIM2
        SALIDA(I,J)=M(J,I)
       ENDDO
      ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE PRODUCT(M,N,DIM1,DIM2,SALIDA)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! This subroutine multiplies two matrices.                             ! 
! It is done by me and exact to matmul, eg. PROD=matmul(CT,D)          ! 
! -------------------------------------------------------------------- C
      INTEGER:: I,J,K 
      INTEGER,intent(IN):: DIM1, DIM2 
      REAL(8), DIMENSION(DIM1,DIM2),intent(IN):: M, N
      REAL(8), DIMENSION(DIM1,DIM2),intent(out):: SALIDA
! -------------------------------------------------------------------- C
      CALL AZZERO(SALIDA,DIM1,DIM2)
      DO I=1,DIM1
       DO J=1,DIM2
        DO K=1,DIM1
         SALIDA(I,J)=SALIDA(I,J)+M(I,K)*N(K,J) 
        ENDDO 
       ENDDO 
      ENDDO 
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
      SUBROUTINE MATRIXBYCONSTANT(M,DIM1,DIM2,CNST,SALIDA)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! This subroutine multiplies M matrix by a constant CNST.              !   
! product.                                                             ! 
! -------------------------------------------------------------------- C
      INTEGER:: I,J
      INTEGER,intent(IN):: DIM1, DIM2 
      REAL*8:: CNST
      REAL(8), DIMENSION(DIM1,DIM2),intent(IN):: M
      REAL(8), DIMENSION(DIM1,DIM2),intent(out):: SALIDA
! -------------------------------------------------------------------- C
      DO I=1,DIM1
       DO J=1,DIM2
         SALIDA(I,J)=M(I,J)*CNST
       ENDDO 
      ENDDO 
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE HADAMARDPRODUCT(M,N,DIM1,DIM2,SALIDA)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! Instead of matrix product, we calculate a simple (Hadamard) M*N      !
! product.                                                             !
! -------------------------------------------------------------------- C
      INTEGER:: I,J
      INTEGER,intent(IN):: DIM1, DIM2
      REAL(8), DIMENSION(DIM1,DIM2),intent(IN):: M, N
      REAL(8), DIMENSION(DIM1,DIM2),intent(out):: SALIDA
! -------------------------------------------------------------------- C
      DO I=1,DIM1
       DO J=1,DIM2
         SALIDA(I,J)=M(I,J)*N(I,J)
       ENDDO
      ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END
! -------------------------------------------------------------------- C
      SUBROUTINE inversion(A,DIM1,DIM2,Ainv)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! To write the inversion of A matrix.                                  !  
! -------------------------------------------------------------------- C
      REAL*8, DIMENSION(DIM1,DIM2), intent(in) :: A
      integer,intent(IN):: DIM1, DIM2 
      real*8, dimension(DIM1,DIM2), intent(OUT) :: Ainv
      integer :: n, info
      real*8, dimension(DIM1) :: work  ! work array for LAPACK
      integer, dimension(DIM1) :: ipiv   ! pivot indices
! External procedures defined in LAPACK
        external DGETRF
        external DGETRI
! Store A in Ainv to prevent it from being overwritten by LAPACK
        Ainv = A 
!        write(*,*) A
        n = DIM1 
!    
      ! DGETRF computes an LU factorization of a general M-by-N matrix A
      ! using partial pivoting with row interchanges.
      call DGETRF(n, n, Ainv, n, ipiv, info)
    
      if (info /= 0) then
         stop 'Matrix is numerically singular!'
      end if
    
      ! DGETRI computes the inverse of a matrix using the LU factorization
      ! computed by DGETRF.
      call DGETRI(n, Ainv, n, ipiv, work, n, info)
    
      if (info /= 0) then
         stop 'Matrix inversion failed!'
      end if
! -------------------------------------------------------------------- C
      RETURN 
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE SCREEN(M,DIM1,DIM2,THRES,SALIDA)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
      INTEGER:: i,j 
      REAL(8), DIMENSION(DIM1,DIM2),intent(in):: M
      INTEGER,intent(IN):: DIM1, DIM2 
      REAL(8),intent(IN):: THRES 
      REAL(8), DIMENSION(DIM1,DIM2),intent(out):: SALIDA
! -------------------------------------------------------------------- C
! We screen the values of an array M by the threshold THRES.           ! 
! Exit is given in a different array, SALIDA.                          !
! -------------------------------------------------------------------- C
       DO i=1,DIM1
        DO j=1,DIM2
         if (ABS(M(i,j)).GT.THRES) THEN 
           SALIDA(i,j)=M(i,j)
         ELSE 
           SALIDA(i,j)=0.0D0 
         endif 
        ENDDO
       ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
      SUBROUTINE NORMALIZE(M,DIM1,DIM2,NORM)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
      REAL(8), DIMENSION(DIM1,DIM2),intent(inout):: M
      INTEGER,intent(IN):: DIM1, DIM2
      REAL(8), intent(out):: NORM
      INTEGER:: I, J
! -------------------------------------------------------------------- C
! A given matrix M is normalized.                                      !
! -------------------------------------------------------------------- C
! Norm
      NORM=0.0D0
      DO I=1,DIM1
       DO J=1,DIM2
        NORM=NORM+M(I,J)
       ENDDO 
      ENDDO 
!
      DO I=1,DIM1
       DO J=1,DIM2
        M(I,J)=M(I,J)/NORM
       ENDDO 
      ENDDO 
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE GETAMPLINORM(M,DIM1,DIM2,NORM)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
      REAL(8), DIMENSION(DIM1,DIM2),intent(inout):: M
      INTEGER,intent(IN):: DIM1, DIM2
      REAL(8), intent(out):: NORM
      INTEGER:: I, J
! -------------------------------------------------------------------- C
! Obtains the normalized amplitudes for a given M matrix.              ! 
! -------------------------------------------------------------------- C
! Norm
      NORM=0.0D0
      DO I=1,DIM1
       DO J=1,DIM2
        NORM=NORM+(M(I,J)*M(I,J))
       ENDDO
      ENDDO
!
      DO I=1,DIM1
       DO J=1,DIM2
        M(I,J)=(M(I,J)*M(I,J))/NORM
       ENDDO
      ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END
! -------------------------------------------------------------------- C
      SUBROUTINE CALCT(M,DIM1,DIM2,CT,TAG)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
      REAL(8), DIMENSION(DIM1,DIM2),intent(in):: M
      INTEGER,intent(IN):: DIM1, DIM2
      REAL(8),intent(OUT):: CT 
      INTEGER:: I, J, NTOT, NHALF
      CHARACTER(2),intent(IN):: TAG 
      REAL(8):: AA, AB, BA, BB
! -------------------------------------------------------------------- C
! We calculate the CT character according to:                          ! 
! F. Plasser and H. Lischka JCTC, 9, 2777, (2012)                      ! 
! -------------------------------------------------------------------- C
      NTOT=DIM1
      NHALF=NTOT/2.0D0 
! AA terms
      DO I=1,NHALF
       DO J=1,NHALF
        AA=AA+M(I,J)
       ENDDO
      ENDDO
      WRITE(*,*) "*-------*"
      IF (TAG=='CT') THEN
       WRITE(*,10) "Summation of 11 terms:", AA
      ELSE IF (TAG=='DP') THEN
       WRITE(*,*) "T.d.m 1 --> 1 terms:", AA
      ENDIF
! AB terms
      DO I=1,NHALF
       DO J=NHALF+1,NTOT
        AB=AB+M(I,J)
       ENDDO
      ENDDO
      IF (TAG=='CT') THEN
       WRITE(*,10) "Summation of 12 terms:", AB
      ELSE IF (TAG=='DP') THEN
       WRITE(*,*) "T.d.m 1 --> 2 terms:", AB
      ENDIF
! BA terms
      DO I=NHALF+1,NTOT
       DO J=1,NHALF
        BA=BA+M(I,J)
       ENDDO
      ENDDO
      IF (TAG=='CT') THEN
       WRITE(*,10) "Summation of 21 terms:", BA
      ELSE IF (TAG=='DP') THEN
       WRITE(*,*) "T.d.m 2 --> 1 terms:", BA 
      ENDIF
! BB terms
      DO I=NHALF+1,NTOT
       DO J=NHALF+1,NTOT
        BB=BB+M(I,J)
       ENDDO
      ENDDO
      IF (TAG=='CT') THEN
       WRITE(*,10) "Summation of 22 terms:", BB
      ELSE IF (TAG=='DP') THEN
       WRITE(*,*) "T.d.m 2 --> 2 terms:", BB
      ENDIF
! CT number:
      CT=(AB+BA)
  10 FORMAT (A25,F10.4)
! -------------------------------------------------------------------- C
      RETURN
      END 
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE ARRANGEOMG(M,FRAG,NOPA,NTOT,NFRAG,NAPF,NATOMS,SALIDA)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! This subroutine orders M according to MAP, a mapping of NOPA         ! 
! according to FRAG composition.                                       !
! -------------------------------------------------------------------- C
      INTEGER:: I,J,K,LABEL
      INTEGER:: U, V, W
      REAL(8), DIMENSION(NTOT,NTOT),intent(IN):: M
      INTEGER, DIMENSION(NFRAG,NAPF),intent(IN):: FRAG
      INTEGER, DIMENSION(NATOMS,2),intent(IN):: NOPA
      INTEGER, DIMENSION(NATOMS,2):: MAP ! MAP will carry the good order according to FRAG composition 
      INTEGER,intent(IN):: NTOT,NFRAG,NAPF,NATOMS
      REAL(8), DIMENSION(NTOT,NTOT),intent(OUT):: SALIDA
!      REAL(8), DIMENSION(:,:),intent(INOUT):: M
! -------------------------------------------------------------------- C
!
      U=1
      DO K=1,NFRAG ! for a given K fragment
       DO I=1,NAPF ! Orderly, I will look for a particular atom ...
         MAP(U,1)=FRAG(K,I) ! that has this label. 
         DO V=1,NATOMS
          IF (MAP(U,1).EQ.NOPA(V,1))  MAP(U,2)=NOPA(V,2) ! ... with this number of orbitals   
         ENDDO
         U=U+1
       ENDDO
      ENDDO
! Pablo test
!      WRITE(*,*) "Pablo writes FRAG array"
!      DO I=1,NFRAG
!         WRITE(*,*) (FRAG(I,J),J=1,NAPF)
!      ENDDO
!      WRITE(*,*) ""
!      WRITE(*,*) "Pablo writes NOPA array"
!      DO I=1,NATOMS
!         WRITE(*,*) (NOPA(I,J),J=1,2)
!      ENDDO
!      WRITE(*,*) ""
!      WRITE(*,*) "Pablo writes MAP array"
!      DO I=1,NATOMS
!         WRITE(*,*) (MAP(I,J),J=1,2)
!      ENDDO
! End Pablo
! I construct the new SALIDA matrix according to the new MAP
      DO I=1,NTOT 
       DO J=1,NTOT 
         CALL LOCALIZE(NOPA,MAP,NTOT,NATOMS,I,J,U,V)
! Pablo test
!        WRITE(*,*) "I map I,J",I,J, "into U,V",U,V 
! End Pablo
         SALIDA(I,J)=M(U,V)
       ENDDO
      ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END
! -------------------------------------------------------------------- C
      SUBROUTINE LOCALIZE(NOPA,MAP,NTOT,NATOMS,I,J,U,V)
      IMPLICIT NONE
      INTEGER, DIMENSION(NATOMS,2),intent(IN):: MAP, NOPA
      INTEGER, intent(IN):: NTOT,NATOMS, I, J
      INTEGER, intent(OUT):: U, V
      INTEGER, DIMENSION(NTOT,NTOT,1,1,1,1)::MATCH
      INTEGER::P, Q, INIT, ORBITAL, RANGE
      INTEGER::I_A,I_O,J_A,J_O
! -------------------------------------------------------------------- C
!  Makes the mapping of I,J into U,V.                                  !
! -------------------------------------------------------------------- C
! We identify I,J element in terms of Atom/orbital according to (new) MAP
      INIT=1
      DO P=1,NATOMS
       DO RANGE=INIT,(INIT-1)+MAP(P,2)
        ORBITAL=RANGE-(INIT-1)
        IF(I.EQ.RANGE) THEN
         I_A=P
         I_O=ORBITAL
        ENDIF
        IF(J.EQ.RANGE) THEN
         J_A=P
         J_O=ORBITAL
        ENDIF
       ENDDO
       INIT=RANGE
      ENDDO
!
      INIT=1
      DO P=1,NATOMS
       DO RANGE=INIT,(INIT-1)+NOPA(P,2)
        ORBITAL=RANGE-(INIT-1)
        IF ((NOPA(P,1).EQ.I_A).AND.(ORBITAL.EQ.I_O))  U=RANGE
        IF ((NOPA(P,1).EQ.J_A).AND.(ORBITAL.EQ.J_O))  V=RANGE
       ENDDO
       INIT=RANGE
      ENDDO
! -------------------------------------------------------------------- C
      RETURN
      END
! -------------------------------------------------------------------- C
! -------------------------------------------------------------------- C
      SUBROUTINE GETOMG(S,D,ST,SINV,SINVT,DIM1,DIM2,SALIDA)
      IMPLICIT NONE
! -------------------------------------------------------------------- C
! Get OMG matrix using the DS*SD descomposition.                       ! 
! SALIDA output is not nonrmalized.                                   !
! -------------------------------------------------------------------- C
      INTEGER:: I,J
      REAL(8), DIMENSION(DIM1,DIM2),intent(in):: S, D, ST, SINV, SINVT 
      REAL(8), DIMENSION(DIM1,DIM2):: PROD, SD, DS 
      INTEGER,intent(IN):: DIM1, DIM2  
      REAL(8), DIMENSION(DIM1,DIM2),intent(out):: SALIDA
! Calculation of
! D*S = C*D*C^-1
       CALL PRODUCT(S,D,DIM1,DIM2,PROD) ! It is done by me and exact to matmul 
       CALL PRODUCT(PROD,SINV,DIM1,DIM2,DS)
!      IF (K.EQ.1) CALL WRTARRAY(DS,NTOT,NTOT,16,'large')
! Calculation of:
! S*D = C^(-1,T)*D*CT 
       CALL AZZERO(PROD,DIM1,DIM2)
       CALL PRODUCT(SINVT,D,DIM1,DIM2,PROD)
       CALL PRODUCT(PROD,ST,DIM1,DIM2,SD) 
! Calculation of: 
! OMG=DS*SD
       CALL HADAMARDPRODUCT(DS,SD,DIM1,DIM2,SALIDA)
! S_AO=C^-(1,T)*C^(-1) (Assuming that MOs are normalized, ie. S_MO is the identity) 
!       CALL PRODUCT(CINVT,CINV,NTOT,NTOT,S_AO) ! It is done by me and exact to matmul
! D_AO = C*D*CT
!       CALL AZZERO(PROD,NTOT,NTOT)
!       CALL PRODUCT(CMOAO,D,NTOT,NTOT,PROD) ! It is done by me and exact to matmul
!       CALL PRODUCT(PROD,CT,NTOT,NTOT,D_AO) ! It is done by me and exact to matmul
! -------------------------------------------------------------------- C
      RETURN
      END
! -------------------------------------------------------------------- C
