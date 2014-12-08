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

#define TLB_FLAG_1KB  0b0101101100
#define TLB_FLAG_4KB  0b0101111100
#define TLB_FLAG_64KB 0b0111101100
#define TLB_FLAG_1MB  0b0111111100

extern volatile unsigned int _EH_Data;
extern volatile unsigned int _EH_Page_Table;
extern volatile unsigned int _EH_Page_Table_End;

extern int EH_Install();
extern int EH_Uninstall();
extern const volatile unsigned int* EH_Data;
extern const volatile unsigned int* EH_Page_Table;
extern const volatile unsigned int* EH_Page_Table_End;
/// For flags, see bits[10:0] of UTLB data entry.
extern int EH_AddPage(unsigned int src_virtual, unsigned int dest_physical, int flags);
extern int EH_DelPage(unsigned int src_virtual);
extern void EH_SetTrapHandler(void (*callback)(int code));
extern unsigned int EH_Lookup(unsigned int addr_virtual);

#ifdef __cplusplus
}
#endif

#endif