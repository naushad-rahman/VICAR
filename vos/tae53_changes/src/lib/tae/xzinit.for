C TDM CHECKOUT FILE_TIME= 7-MAY-1984 20:14 DUA0:[TAEV1.OLB]XZINIT.FOR;42
C TDM CHECKOUT FILE_TIME=23-MAR-1984 10:12 DUA0:[TAEV1.OLB]XZINIT.FOR;40
C TDM CHECKOUT FILE_TIME=22-DEC-1983 15:53 DUA0:[TAEV1.OLB]XZINIT.FOR;39
C TDM CHECKOUT FILE_TIME=17-NOV-1983 10:01 DUA0:[TAEV1.OLB]XZINIT.FOR;38
C TDM CHECKOUT FILE_TIME= 5-OCT-1983 09:15 DUA0:[TAEV1.OLB]XZINIT.FOR;36
C TPEB CHECKOUT FILE_TIME=29-MAR-1983 14:56 DUA0:[TAEV1.OLB]XZINIT.FOR;35
CTDM         CHECKOUT FILE_TIME=25-MAR-1983 17:59 DMA1:[TAEV1.OLB]XZINIT.FOR;32
C
C	XZINIT. FORTRAN CALLABLE ROUTINE .
C	WRITTEN IN FORTRAN TO AVOID PROBLEM OF CONVERTING A C STRING
C	TO A FORTRAN-77 STRING (FOR THE STANDARD OUTPUT FILE NAME ).
C
C
C	CHANGE LOG:
C	
C	29-MAR-83	HARDCODE PGMINC.FIN...DM
C	30-SEP-83	STORE TERMINAL TYPE, GETTERM -> XUGETT...peb
C	15-NOV-83	LIMIT VARIABLE NAMES TO 6 CHARS FOR PORTABILITY...dm
C	17-NOV-83	Add call to xzcall...palm
C	22-DEC-83	Update for new xrstr calling sequence...dm
C	20-DEC-84	Limit  output messages to single records...dm
C	12-APR-84	Eliminate XZSAVL common block reference...dm
C	07-MAY-84	Get rid of CARRIAGE CONTROL in OPEN...nhe
C	21-AUG-84	Make xzinit portable, Isolate non-portable 
C			routines to a different source module...dm
C

	SUBROUTINE XZINIT(BLOCK, DIM, STDLUN, MODE, STATUS)
C
C	NOTE: XTINIT SHOULD BE CALLED AFTER SETLUN AND SETSTD CALLS.
C

	INCLUDE	'$taeINC:PGMINC.FIN'	

	INTEGER BLOCK(1)		
	INTEGER DIM			
	INTEGER STDLUN			
	INTEGER MODE			
	INTEGER STATUS			


	CHARACTER*(xfssiz)	STDREC(2)	
	CHARACTER*(xfssiz)	TERMNM	
	INTEGER		LENGTH(2)
	INTEGER		COUNT
	LOGICAL 	NEWFIL
	LOGICAL 	OPENED
	INTEGER 	L
	INTEGER		LINES, COLS
	LOGICAL		TERMNL			

	INTEGER		LUN			
	INTEGER		TTYPE			

	STATUS = xsucc					
	CALL SETLUN (STDLUN)				
	CALL XRINIM(BLOCK, DIM, MODE, STATUS)		
	IF (STATUS .NE. xsucc) RETURN
	CALL XZCALL(BLOCK)				
    	CALL XRSTR(BLOCK, '_STDOUT', 2, STDREC, LENGTH, 
     +		COUNT, STATUS)
	IF (STATUS. NE. xsucc) RETURN

	NEWFIL = .TRUE.
	IF (STDREC(2) .NE. 'CREATE') NEWFIL = .FALSE.	

	CALL XUGETT(TERMNM)				
	IF (TERMNM .EQ. STDREC(1)) THEN
	    TERMNL = .TRUE.				
	ELSE
	    TERMNL = .FALSE.
	ENDIF
CC #ifdef VICAR_BATCH_LOG, #ifdef VAX_VMS
        IF ('SYS$OUTPUT:.;' .EQ. STDREC(1)) TERMNL = .TRUE.
CC #endif, #endif
	CALL SETSTD(TERMNL)				

	CALL XTINIT(TTYPE, LINES, COLS)			
C
C	Prepare to open the standard output file, and make sure 
C	that it is not already open (Applicable for UNIX only.)
C	

	OPENED = .FALSE.
	CALL PREOPN(LUN, STDREC(1), OPENED)
        IF (OPENED) RETURN				

	CALL OPNSTD(STDREC(1), NEWFIL, OPENED)		
	IF (.NOT. OPENED) THEN
c Don't fail simply because stdout couldn't be opened, so that we can
c run from something other than a terminal without triggering shell-vicar
ccccc	    STATUS = xfail
	    IF (MODE .EQ. xabort) THEN
	        L = LEN(STDREC(1))			
	        CALL XTWRIT(
     +		'Could not open standard output file '//STDREC(1)(1:L), xccstd)
		CALL XZEXIT(-1, 'TAE-STDOPN')		
	    ENDIF
	ENDIF
	RETURN
	END

C
C  OPNSTD.  Fotran open for an output file.
C	    NOTE: If file is old, open and position for appending.
C
    
	SUBROUTINE OPNSTD(FILENM, NEWFIL, OPENED)
	
	CHARACTER*(*)	FILENM	
	LOGICAL		NEWFIL			
	LOGICAL 	OPENED		

	CHARACTER*132	DUMMY
	CHARACTER*4	STAT
	INTEGER		LUN			
  	LOGICAL		TERMNL

	CALL GETLUN_TAE(LUN)
	CALL GETSTD(TERMNL)			
	IF (NEWFIL) THEN
	    STAT = 'NEW'
	ELSE
	    STAT = 'OLD'
	ENDIF
	OPEN (FILE=FILENM, UNIT=LUN, STATUS=STAT, ERR=200)
	OPENED = .TRUE.
	IF (NEWFIL .OR. TERMNL) THEN
	    RETURN
	ENDIF
C
C	IF OLD FILE, POSITION AT THE END.
C
999	CONTINUE
	READ(UNIT=LUN, FMT=101, END=150, ERR=150) DUMMY
101	FORMAT (A)
	GOTO 999
150	RETURN

200	CONTINUE
	OPENED = .FALSE.
	RETURN
	END
