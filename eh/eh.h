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

extern volatile unsigned int _EH_Data;
extern volatile unsigned int _EH_Page_Table;

extern int EH_Install();
extern int EH_Uninstall();
const volatile unsigned int* EH_Data = &_EH_Data;
const volatile unsigned int* EH_Page_Table = &_EH_Page_Table;
extern int EH_AddPage(int source, int dest, int flags);
extern int EH_DelPage(int source);

#ifdef __cplusplus
}
#endif

#endif