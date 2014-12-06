/*
 * License pending
 * Copyright 2014 Collin Eggert
 */
/*
 * API for custom Exception Handler code.
 */
#ifndef __EH_H
#define __EH_H

#ifdef __cplusplus
extern "C" {
#endif

struct EH_Data_t {
  unsigned int oldVBR;
  unsigned int VBR100;
  unsigned int VBR400;
  unsigned int VBR600;
  unsigned int pageTableEnd;
  unsigned int invocationCounter;
  void (*trapCallback)(int);
};

#define TLB_FLAG_1KB  0b0101101000
#define TLB_FLAG_4KB  0b0101111000
#define TLB_FLAG_64KB 0b0111101000
#define TLB_FLAG_1MB  0b0111111000

extern volatile unsigned int _EH_Data;
extern volatile unsigned int _EH_Page_Table;
extern volatile unsigned int _EH_Page_Table_End;

extern int EH_Install();
extern int EH_Uninstall();
const volatile  unsigned int* EH_Data = &_EH_Data;
const volatile unsigned int* EH_Page_Table = &_EH_Page_Table;
const volatile unsigned int* EH_Page_Table_End = &_EH_Page_Table_End;
/// For flags, see bits[10:0] of UTLB data entry.
extern int EH_AddPage(unsigned int source, unsigned int dest, int flags);
extern int EH_DelPage(unsigned int source);
extern void EH_SetTrapHandler(void (*callback)(int code));

#ifdef __cplusplus
}
#endif

#endif