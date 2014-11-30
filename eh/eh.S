! Calling conventions: (From https://www.taricorp.net/muse/casio-prizm-binaries) (Quick reference)
! R0-R1: Function return value; caller saves
! R2-R3: Scratch; caller saves
! R2: Aggregate return address; caller save (GNU ABI only)
! R4-R7: Parameter passing; caller saves
! R8-R13: Callee Saves
! R14: Frame Pointer (FP); callee saves
! R15: Stack Pointer (SP); callee saves
! MACH, MACL: Caller saves3
! PR: Linkage register (saves the subroutine return address); caller saves
! SR: Status register
! GBR: Reserved
! VBR: Reserved

! License pending
! Copyright 2014 Collin Eggert

! Non-PIC, Renesas ABI
  .section ".eh", "ax" ! MUST SET THESE ELF SECTION FLAGS. a - ALLOC, x - EXEC. The binary BSF checks these to see if it should write to the binary.
  
  .org 0
  .align 2
  .globl _EH_Install
  .type _EH_Install, @function
_EH_Install:
  ! Are we already installed?
  stc   vbr, r2
  mov.l Lstart01, r3
  cmp/eq r2, r3
  bf    1f
  rts
  mov   #0, r0
  
1:
  ! Save the old VBR 
  mov.l Lvars01, r3
  mov.l r2, @(0*4,r3)
  
  ! Cache the offsets into the OS's exception vector 
  mov.l 2f, r0
  add   r0, r2
  mov.l r2, @(1*4,r3)
  mov.l 3f, r0
  add   r0, r2
  mov.l r2, @(2*4,r3)
  mov.l 4f, r0
  add   r0, r2
  mov.l r2, @(3*4,r3)
  
  ! Init the TLB table 
  mov.l 5f, r2
  mov.l r2, @(4*4,r3)
  mov   #0, r2
  mov.l r2, @(5*4,r3)
  
  ! Clear the trap handler
  mov.l r2, @(6*4,r3)
  
  ! Do the VBR swap
  mov.l Lstart01, r2
  ldc   r2, vbr
  nop
  
  ! Return
  rts
  mov   #1, r0
  
  .align 4
2:
  .long 0x100
3:
  .long 0x300
4:
  .long 0x200
5:
  .long EH_PAGE_TABLE_DATA
Lvars01:
  .long EH_OLDVBR
Lstart01:
  .long _EH_Install
  
  .align 2
  .globl _EH_Uninstall
  .type _EH_Uninstall, @function
_EH_Uninstall:
  ! Swap the old VBR back
  mov.l Lvars02, r3
  mov.l @(0*4,r3), r2
  tst   r2, r2  ! Can't uninstall, not installed
  bt/s  1f
  mov   #0, r0
  ldc   r2, vbr
  mov.l r0, @(0*4,r3)
  mov   #1, r0
  
  ! Return
1:
  rts
  nop
  
  .align 4
Lvars02:
  .long EH_OLDVBR
  
  .align 2
  .globl _EH_AddPage
  .type _EH_AddPage, @function
_EH_AddPage: ! (args: r4=source, r5=dest, r6=flags, returns 1 on success, 0 on failure) 
  ! Considering pages can be 4KB, you can have a LOT of pages.  Maybe a self-balancing binary tree? 
  ! But you can always improve, bare essentials first: 
  ! Get the position of the end of the table 
  ! If at the end, return false 
  ! Insert a cache of entry registers for quick access 
  ! Bump up the end pointer 
  ! Return true 
  rts
  mov   #0, r0
  
  .align 2
  .globl _EH_DelPage
  .type _EH_DelPage, @function
_EH_DelPage: ! (args: int source, returns 1 on success, 0 on failure) 
  ! Scan the table for a matching source (slow, needs logic ops on the table) 
  ! If not found, return false 
  ! If the end ptr points to the current entry, jump to EH_DelPage_Success 
  ! Copy the entry at the end point over the current entry 
  
EH_DelPage_Success: 
  ! Decrease the end ptr 
  ! Return true 
  rts
  mov   #0, r0
  
  .align 2
  .globl _EH_SetTrapHandler
  .type _EH_SetTrapHandler, @function
_EH_SetTrapHandler: ! (args: void (*callback)())
  ! Just copy
  mov.l 1f, r2
  rts
  mov.l r4, @(6*4,r2)
  
  .align 4
1:
  .long EH_OLDVBR
  
  .align 2
  .org 0x100
EH100: ! (VBR+H'100, ignore) 
  /*
  mov.l Lvars03, r0
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(1*4,r0), r0
  jmp   @r0
  nop
  */
  ! Safer method
  /*
  When an exception happens, r0-r7 are swapped with the bank registers, so those are free.
  pc, sr, r15 are moved to spc, ssr, sgr.
  When the exception handler is done, it rte's, which means it uses spc.
  */
  ! Save the registers
  stc.l spc, @-r15
  stc.l ssr, @-r15
  stc.l vbr, @-r15
  ! Add our own
  mov.l 1f, r0
  ldc   r0, spc
  ! Restore the VBR JUST IN CASE
  mov.l Lvars03, r0
  mov.l @(0*4,r0), r1
  ldc   r1, vbr
  ! Check the exception type?
    mov.l 2f, r2
    mov.l @(0*4,r2), r3
    mov.l @(1*4,r2), r2
    ! Did someone activate my TRAPA card?
    cmp/eq r2, r3
    bf    EH100_UNHANDLED
    ! Is there a handler registered?
    mov.l @(6*4,r0), r2
    tst   r2, r2
    bf    EH100_UNHANDLED
    ! Now we are in full control, restore registers, RTE to a safe spot, call, then jump out
    ! TODO
  ! If unhandled, jump into the OS (incrementing usage timer for debugging)
EH100_UNHANDLED:
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(1*4,r0), r0
  jmp   @r0
EH100_RESTORE:
  ! wb
  ldc.l @r15+, vbr
  ldc.l @r15+, ssr
  ldc.l @r15+, spc
  ! Go back as normal
  rte
  nop

  .align 4
1:
  .long EH100_RESTORE
2:
  .long 0xFF000024
  .long 0x160
Lvars03:
  .long EH_OLDVBR
 
 .globl __EH_Page_Table
 .type __EH_Page_Table, @notype
__EH_Page_Table:
EH_PAGE_TABLE_DATA:
  ! This is a nice spot for a small table
  
  .align 2
  .org 0x400
EH400:
  /*
  mov.l Lvars04, r0
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(2*4,r0), r0
  jmp   @r0
  nop
  */
  ! Safer method from above
  ! Save the registers
  stc.l spc, @-r15
  stc.l ssr, @-r15
  stc.l vbr, @-r15
  ! Add our own
  mov.l 1f, r0
  ldc   r0, spc
  ! Restore the VBR JUST IN CASE
  mov.l Lvars04, r0
  mov.l @(0*4,r0), r1
  ldc   r1, vbr
  ! Check the exception type?
  ! If unhandled, jump into the OS (incrementing usage timer for debugging)
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(2*4,r0), r0
  jmp   @r0
EH200_RESTORE:
  ! wb
  ldc.l @r15+, vbr
  ldc.l @r15+, ssr
  ldc.l @r15+, spc
  ! Go back as normal
  rte
  nop
  
  .align 4
1:
  .long EH200_RESTORE
Lvars04:
  .long EH_OLDVBR
  
  .globl __EH_Data
  .type __EH_Data, @notype
  .align 4
__EH_Data:
EH_OLDVBR:
  .long 0
EH_JMP:
  .long 0 ! 0x100
  .long 0 ! 0x400
  .long 0 ! 0x600
EH_PAGE_TABLE_END:
  .long 0
EH_INVOCATION_COUNTER:
  .long 0
EH_TRAP_CALLBACK:
  .long 0
  
  .org 0x600
  .align 2
EH600:
  /*
  mov.l Lvars05, r0
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(3*4,r0), r0
  jmp   @r0
  nop
  */
  ! Safer method from above
  ! Save the registers
  stc.l spc, @-r15
  stc.l ssr, @-r15
  stc.l vbr, @-r15
  ! Add our own
  mov.l 1f, r0
  ldc   r0, spc
  ! Restore the VBR JUST IN CASE
  mov.l Lvars05, r0
  mov.l @(0*4,r0), r1
  ldc   r1, vbr
  ! Check the exception type?
  ! If unhandled, jump into the OS (incrementing usage timer for debugging)
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(3*4,r0), r0
  jmp   @r0
EH300_RESTORE:
  ! wb
  ldc.l @r15+, vbr
  ldc.l @r15+, ssr
  ldc.l @r15+, spc
  ! Go back as normal
  rte
  nop
  
  .align 4
1:
  .long EH300_RESTORE
Lvars05:
  .long EH_OLDVBR