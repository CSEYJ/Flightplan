/*
 * RSE.H
 */

#ifndef _FEC_H
#define _FEC_H

#include <stdio.h>
#include <sys/time.h>
#include <assert.h>
#include <string.h>

/***************************************************************************/
/* FEC Packet Definitions                                                  */
/***************************************************************************/
//#define     FEC_M           3               /* symbol size (SMALL TEST) */
#define     FEC_M           8               /* symbol size (default) */
//#define     FEC_M           16              /* symbol size (Faster?) */
#define     FEC_MAX_COLS	10000           /* Max symbols in one packet */
#define     FEC_EXTRA_COLS	1               /* Extra Parity symbols to code length */

/***************************************************************************/
/* Codeword Definition (using m-bit symbols defined for FEC packet)        */
/***************************************************************************/
#define     FEC_N           (1 << FEC_M)    /* 2^m = Max symbol value + 1 */
//#define     FEC_MAX_N       12        /* Max packets in FEC block (< FEC_N) */
#define     FEC_MAX_N       12 /* Max packets in FEC block (< FEC_N) */
#define     FEC_MAX_H       4         /* MAX h parities (< FEC_N -1) */
#define     FEC_MAX_K       (FEC_MAX_N - FEC_MAX_H)  /* MAX k data packets */

/***************************************************************************/
/* FEC Block Definitions                                                   */
/***************************************************************************/
//typedef unsigned short  fec_sym;            /* 16 bit symbol */
typedef unsigned char	fec_sym;            /* 8 bit symbol */
typedef fec_sym (*fec_blk)[FEC_MAX_COLS];	/* packet structure of C columns */

/* Information about an FEC Block */
/* Packet Storage in rsetest.c is contiguous ([K+H] by [FEC_MAX_COLS] matrix) */
/* but, in general, need not be (so pass as pointers) */
struct fec_block {
    fec_sym    block_C;                     /* Number of Symbols in Parity packets */
    fec_sym    block_N;                     /* Actual number of packets in FEC block */
    fec_sym    *pdata[FEC_N-1];             /* ptrs to each possible packet in FEC block */
    fec_sym    cbi[FEC_N-1];                /* Code-Block Index (0 to FEC_N-2) */
    int        plen[FEC_N-1];               /* Packet length: number of symbols */
    char       pstat[FEC_N-1];              /* Packet stauts flag: known, wanted, ... */
};
extern struct fec_block fb;                 /* Declare FEC block fb */

/** packet status flags **/
#define		FEC_FLAG_KNOWN      0           /* data packet status: Known */
#define		FEC_FLAG_WANTED     1           /* data packet status: Wanted */
#define		FEC_FLAG_IGNORE     2           /* data packet status: Not Want */

/* Matrix storage */
struct fec_matrices {
    fec_sym    d[FEC_MAX_H][FEC_MAX_H+1];   /* Duplicate Matrix (generated each symbol) */
    fec_sym    e[FEC_MAX_H][FEC_MAX_H+1];   /* Equation Matrix (once per FEC Block) */
};
extern struct fec_matrices fcm;             /* Declare FEC code matrix fcm */

/***************************************************************************/
/* Error codes                                                             */
/***************************************************************************/

#define     FEC_ERR_INVALID_PARAMS         -1
#define     FEC_ERR_ENC_MISSING_DATA       -20
#define     FEC_ERR_MOD_NOT_FOUND          4
#define     FEC_ERR_TRANS_FAILED           82

/***************************************************************************/
/* Run Option Control (to stderr)                                        */
/***************************************************************************/

//#define  FEC_MAC_LOOKUP                 /* use gf lookup table in FEC_MAC */
//#define     FEC_SPEED_TEST


#define     MAX_PRINT_COLUMNS   18      /* Max columns printed in tables */
#define     FEC_DBG_LEVEL_0             /* Leave defined, unless want no printing */

//#define     FEC_DBG_LEVEL_1
//#define     FEC_DBG_LEVEL_2             /* print major events */
//#define     FEC_DBG_LEVEL_3             /* Print Encoding and Decoding Steps */
//#define     FEC_DBG_MATH_TABLES         /* print math tables */
//#define     FEC_DBG_PRINT_RS            /* print RS fec_weights (on init) */
//#define     FEC_DBG_PRINT_TRANS         /* print matrix transform (to 3 rows) */

#ifdef FEC_DBG_LEVEL_0
    #define D0(x) x
#else
    #define D0(x)
#endif

#ifdef FEC_DBG_LEVEL_1
    #define D1(x) x
#else
    #define D1(x)
#endif

#ifdef FEC_DBG_LEVEL_2
    #define D2(x) x
#else
    #define D2(x)
#endif

#ifdef FEC_DBG_LEVEL_3
    #define D3(x) x
#else
    #define D3(x)
#endif

/***************************************************************************/
/* Function prototypes                                                     */
/***************************************************************************/
int  rse_code(int);
int  rse_init(void);
void fec_block_delete(int *);
#ifdef FEC_DBG_LEVEL_0
void fec_block_print(void);
#endif
#ifdef FEC_SPEED_TEST
unsigned long fec_get_time_delta(int);
#endif

/***************************************************************************/

#endif    //_FEC_H