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
  mov.l 1f, r2 ! EH_PAGE_TABLE_END
  mov.l 2f, r3 ! EH_PAGE_TABLE_DATA_END
  mov.l @r2, r1
  mov.l @r3, r0
  add   #8, r1
  cmp/ge r0, r1
  mov.l @r2, r1
  ! T=1 if we can't store anymore
  bf 10f
  ! If at the end, return false 
  rts
  mov   #0, r1
10:
  ! Insert a cache of entry registers for quick access 
  ! ENTRY[0] = Source | size{0,1,2,3}
  ! ENTRY[1] = Dest | Flags
  ! Put the size in bits[0:1] of the source entry
  mov   r6, r0
  and   #0b10010000, r0
  shll  r0
  cmp/eq #0b00100000, r0
  shlr8 r0
  addc  r0, r0 ! Magic!
  ! Make entry 0
  mov.l 7f, r3
  and   r3, r4
  or    r4, r0
  ! Store entry 0
  mov.l r0, @r1
  add   #4, r1
  ! Make entry 1
  mov.l 8f, r3
  and   r3, r5
  or    r6, r5
  ! Store entry 1
  mov.l r5, @r1
  add   #4, r1
  ! Save the end pointer
  mov.l r1, @r2
  ! Return true 
  rts
  mov   #1, r0
  
  .align 4
1:
  .long EH_PAGE_TABLE_END
2:
  .long EH_PAGE_TABLE_DATA_END
7:
  .long 0xFFFFFC00
8:
  .long 0x1FFFFC00
  
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
  ! Restore the VBR JUST IN CASE
  mov.l Lvars03, r0
  mov.l @(0*4,r0), r1
  ldc   r1, vbr
    ! Check the exception type
    mov.l 2f, r2
    mov.l @r2, r3
    mov.l 3f, r2
    ! Did someone activate my TRAPA card?
    cmp/eq r2, r3
    bf    EH100_UNHANDLED
    ! Is there a handler registered?
    mov.l @(6*4,r0), r2
    tst   r2, r2
    bt    EH100_UNHANDLED
    ! Now we are in full control, restore registers, RTE to a safe spot, call, then jump out
    stc.l r7_bank, @-r15
    stc.l r6_bank, @-r15
    stc.l r5_bank, @-r15
    stc.l r4_bank, @-r15
    stc.l r3_bank, @-r15
    stc.l r2_bank, @-r15
    stc.l r1_bank, @-r15
    stc.l r0_bank, @-r15
    sts.l pr, @-r15
    ! This is a weird call, so set the calling address...
    ldc   r2, spc
    ! ... and set that function's return address
    mov.l 4f, r2
    lds   r2, pr
    ! Get the trap code
    mov.l 5f, r2
    mov.l @r2, r2
    shlr2 r2
    ldc   r2, r4_bank
    ! I hope to god this works
    rte
    nop
  ! If unhandled, jump into the OS (incrementing usage timer for debugging)
EH100_UNHANDLED:
  ! Add our own
  mov.l 1f, r1
  ldc   r1, spc
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  mov.l @(1*4,r0), r0
  jmp   @r0
  nop
EH100_RESTORE:
  ! wb
  ldc.l @r15+, vbr
  ldc.l @r15+, ssr
  ldc.l @r15+, spc
  ! Go back as normal
  rte
  nop
  
EH_HANDLED_RETURN:
  lds.l @r15+, pr
  ldc.l @r15+, r0_bank
  ldc.l @r15+, r1_bank
  ldc.l @r15+, r2_bank
  ldc.l @r15+, r3_bank
  ldc.l @r15+, r4_bank
  ldc.l @r15+, r5_bank
  ldc.l @r15+, r6_bank
  bra   EH100_RESTORE
  ldc.l @r15+, r7_bank

  .align 4
1:
  .long EH100_RESTORE
2:
  .long 0xFF000024
3:
  .long 0x160
4:
  .long EH_HANDLED_RETURN
5:
  .long 0xFF000020
Lvars03:
  .long EH_OLDVBR
 
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
  ! Add to counter
  mov.l Lvars04, r0
  mov.l @(5*4,r0), r1
  add   #1, r1
  mov.l r1, @(5*4,r0)
  ! Restore the VBR JUST IN CASE
  mov.l @(0*4,r0), r1
  ldc   r1, vbr
    ! Check the exception type
    mov.l 2f, r2
    mov.l @r2, r3
    ! Is this a TLB miss?
    mov.l 3f, r2
    cmp/eq r2, r3
    bt    EH400_HANDLED
    mov.l 4f, r2
    cmp/eq r2, r3
    bf    EH400_UNHANDLED
EH400_HANDLED:
    !
    ! BEGIN MMU TLB UPDATE CODE
    !
    mov.l 5f, r4
    sts.l pr, @-r15
    bsr   EH_LOOKUP_PAGE
    mov.l @r4, r4
    lds.l @r15+, pr
    ! If unhandled, jump into the OS (incrementing usage timer for debugging)
    bf    EH400_UNHANDLED
    ! r0 has ptr to entry
    mov.l 6f, r1
    add   #4, r0
    mov.l @r0, r0
    mov.l r0, @r1 ! PTEL set
    ! Pray
    ldtlb
    nop
    ! Time to go
    ldc.l @r15+, vbr
    ldc.l @r15+, ssr
    ldc.l @r15+, spc
    rte
    nop
  
EH400_UNHANDLED:
    mov.l Lvars04, r0
  ! Add our own
  mov.l 1f, r1
  ldc   r1, spc
  mov.l @(2*4,r0), r0
  jmp   @r0
  nop
EH400_RESTORE:
  ! wb
  ldc.l @r15+, vbr
  ldc.l @r15+, ssr
  ldc.l @r15+, spc
  ! Go back as normal
  rte
  nop
  
  .align 4
1:
  .long EH400_RESTORE
2:
  .long 0xFF000024
3:
  .long 0x040
4:
  .long 0x060
5:
  .long 0xFF000000 ! PTEH
6:
  .long 0xFF000004 ! PTEL
7:
  .long 0xFF000010 ! MMUCR
8:
  .long 0xFF000034 ! PTEA
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
  
  .align 2
EH_LOOKUP_PAGE: ! (args: r4=int address, returns T on success and r0=address of matched entry, not T on failure)
  ! ptr = table data
  mov.l 1f, r2
  mov.l 2f, r1
  mov.l @r1, r1
  ! While ptr != table data end
10:
  cmp/eq r2, r1
  bf    11f
  ! Clear T
  rts
  clrt
  ! Return
11:
    ! Extract size
    mov.l @r2, r0
    and   #0b11, r0
    ! If size == 0
    tst   r0, r0
    bf    12f
      ! AND 0xFFFFFC00
      mov.l 3f, r3
      bra   15f
      nop
12:
    ! ElIf size == 1
    dt    r0
    bf    13f
      ! AND 0xFFFFF000
      mov.l 4f, r3
      bra   15f
      nop
13:
    ! ElIf size == 2
    dt    r0
    bf    14f
      ! AND 0xFFFF0000
      mov.l 5f, r3
      bra   15f
      nop
14:
    ! ElIf size == 3
      ! AND 0xFFF00000
      mov.l 6f, r3
15:     
    mov.l @r2, r0
    and   r3, r0
    ! If mask matches
    and   r4, r3
    cmp/eq r3, r0
    bf    16f
      ! Set T
      sett
      ! Return
      rts
      mov   r2, r0
16:
    ! Else
      ! ptr+=8
    bra   10b
      add   #8, r2
  
  .align 4
1:
  .long EH_PAGE_TABLE_DATA
2:
  .long EH_PAGE_TABLE_END
3:
  .long 0xFFFFFC00
4:
  .long 0xFFFFF000
5:
  .long 0xFFFF0000
6:
  .long 0xFFF00000
  
  .align 2
  .globl _EH_DelPage
  .type _EH_DelPage, @function
_EH_DelPage: ! (args: int source, returns 1 on success, 0 on failure) 
  ! Scan the table for a matching source (slow, needs logic ops on the table)
  sts.l pr, @-r15
  bsr   EH_LOOKUP_PAGE
  nop
  lds.l @r15+, pr
  ! If not found, return false 
  bt    10f
  rts
  mov   #0, r0
10:
  mov.l @r0, r2
  mov.l r2, @-r15
  ! If the end ptr points to the current entry, jump to EH_DelPage_Success 
  mov   r0, r2
  add   #8, r0 ! r2 is entry, r0 is next entry
  mov.l 1f, r4
  mov.l @r4, r1
  cmp/eq r0, r1
  bf    11f
  ! Decrease the end ptr
  add   #-8, r1
  bra 12f
  mov.l r1, @r4
  ! Copy the entry at the end point over the current entry 
  ! dest=r2, src=r0, stop when r0=r1
11:
  mov.l @r0+, r3
  mov.l r3, @r2
  cmp/eq r0, r1
  bf/s    11b
  add   #4, r2
  ! Copied, save new end
  mov.l r2, @r4
12:
  ! Scan the UTLB for matching entries
  mov.l @r15+, r1
  mov   r1, r0
  ! Get the mask
  and   #0b11, r0
  ! If size == 0
  tst   r0, r0
  bf    13f
    ! AND 0xFFFFFC00
    mov.l 3f, r3
    bra   16f
    nop
13:
  ! ElIf size == 1
  dt    r0
  bf    14f
    ! AND 0xFFFFF000
    mov.l 4f, r3
    bra   16f
    nop
14:
  ! ElIf size == 2
  dt    r0
  bf    15f
    ! AND 0xFFFF0000
    mov.l 5f, r3
    bra   16f
    nop
15:
  ! ElIf size == 3
    ! AND 0xFFF00000
    mov.l 6f, r3
16:     
  and   r3, r1
  mov   r1, r0
  ! For e=3; e >= 0; e--
  mov   #63, r1
15: ! r0=entry, r1=entry ID, r3=mask
  mov   #0, r2
  cmp/ge r2, r1
  bf    16f
  add   #-1, r1
  ! Do we match?
  mov.l 9f, r2
  add   r1, r2
  shll8 r2
  mov.l @r2, r4
  and   r3, r4
  cmp/eq r0, r4
  bf    15b
  ! Matched, invalidate it
  mov.l @r2, r4
  mov.l 7f, r5
  and   r5, r4
  mov.l r4, @r2 ! Invalidated the address
  mov.l 10f, r2
  add   r1, r2
  shll8 r2
  mov.l @r2, r4
  and   r5, r4
  mov.l r4, @r2 ! Invalidated the data
16:
  ! For e=3; e >= 0; e--
  mov   #3, r1
13: ! r0=entry, r1=entry ID, r3=mask
  mov   #0, r2
  cmp/ge r2, r1
  bf    14f
  add   #-1, r1
  ! Do we match?
  mov.l 2f, r2
  add   r1, r2
  shll8 r2
  mov.l @r2, r4
  and   r3, r4
  cmp/eq r0, r4
  bf    13b
  ! Matched, invalidate it
  mov.l @r2, r4
  mov.l 7f, r5
  and   r5, r4
  mov.l r4, @r2 ! Invalidated the address
  mov.l 8f, r2
  add   r1, r2
  shll8 r2
  mov.l @r2, r4
  and   r5, r4
  mov.l r4, @r2 ! Invalidated the data
14:
  ! Return true
  rts
  mov   #1, r0
  
  .align 4
1:
  .long EH_PAGE_TABLE_END
2:
  .long 0x00F20000
3:
  .long 0xFFFFFC00
4:
  .long 0xFFFFF000
5:
  .long 0xFFFF0000
6:
  .long 0xFFF00000
7:
  .long 0xFFFFFEFF
8:
  .long 0x00F30000
9:
  .long 0x00F60000
10:
  .long 0x00F70000
  
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
  nop
EH600_RESTORE:
  ! wb
  ldc.l @r15+, vbr
  ldc.l @r15+, ssr
  ldc.l @r15+, spc
  ! Go back as normal
  rte
  nop
  
  .align 4
1:
  .long EH600_RESTORE
Lvars05:
  .long EH_OLDVBR
  
 .align 4
 .globl __EH_Page_Table
 .type __EH_Page_Table, @notype
__EH_Page_Table:
EH_PAGE_TABLE_DATA:
  
  .globl __EH_Page_Table_End
  .type __EH_Page_Table_End, @notype
__EH_Page_Table_End:
EH_PAGE_TABLE_DATA_END:
