! C runtime initialization for Prizm addins
! By Tari and calc84maniac, based on Kristaba's reverse-engineered crt0.
/*
 * Original crt0.S from libfxcg.  Modified for ld-prizm. libfxcg copywrite block below:

Copyright (c) 2014, The libfxcg Project Contributors
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the project nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
! Contains modifications for C++ support and EH copying.

    .extern _main
    
    .extern start_ctors
    .extern end_ctors
    .extern start_dtors
    .extern end_dtors
    
    .globl initialize
   
    .section ".pretext"
    .align 2
initialize:
! Preserve things on the stack
    mov.l r14, @-r15    ! Frame pointer
    sts.l pr, @-r15     ! Return address
    mov.l r4, @-r15     ! Parameter 1
   
! Copy .data section into RAM
    mov.l v_datald, r0      ! From
    mov.l v_sdata, r2       ! To
    mov.l v_edata, r3       ! Limit
dataLoop:
    cmp/hs r3, r2
    bt dataDone             ! Stop when r2 >= r3
    mov.l @r0+, r1
    mov.l r1, @r2
    bra dataLoop
    add #4, r2              ! Delay slot
dataDone:
   
! Copy .eh section into the heap
    mov.l v_ehld, r0      ! From
    mov.l v_seh, r2         ! To
    mov.l v_eeh, r3         ! Limit
ehLoop:
   cmp/hs r3, r2
    bt ehDone             ! Stop when r2 >= r3
    mov.l @r0+, r1
    mov.l r1, @r2
    bra ehLoop
    add #4, r2              ! Delay slot
ehDone:
 
! Zero out .bss
    mov.l v_ram_ebss, r2    ! To
    mov.l v_ram_bbss, r3    ! Limit
    mov #0, r1              ! Constant
bssLoop:
    cmp/hi r3, r2
    bf bssDone              ! Stop when r2 <= r3
    nop
    bra bssLoop
    mov.b r1, @-r2          ! Delay slot
bssDone:
   
! RAM is now initialized
 
    mov r5, r14             ! Save parameter 2
    mov.l ctors_s,r7
    mov.l ctors_e, r8
    mov.l @r7,r7
    mov.l @r8,r8
    cmp/eq r7, r8
    bt no_ctors
    jsr @r7
    nop
no_ctors:
!    mov.l ctors_s, r8
!    mov.l ctors_e, r9
!    mov.l @r8,r8
!    bra .const_until_end
!    mov.l @r9,r9
!.call_constructor:
!    jsr @r8
!    nop
!    add #4,r8
!.const_until_end:
!    cmp/eq r9, r8
!    bf .call_constructor
!    nop
    mov r14, r5
    mov #1, r6
    mov #0, r4
    bsr _GlibAddinAplExecutionCheck
    mov r6, r5
   
! main(r4, r5) with same state as input (returns to our caller)
   
    mov.l main, r7
    extu.w r14, r5
    mov.l @r15+, r5
    lds.l @r15+, pr
    jmp @r7
    mov.l @r15+, r14        ! Delay slot
   
_GlibAddinAplExecutionCheck:
    mov.l v_syscall, r2
    jmp @r2                 ! _GlibAddinAplExecutionCheck
    mov #0x29, r0           ! Delay slot
   
! Constants
    .align 4
ctors_s:
    .long start_ctors
ctors_e:
    .long end_ctors
dtors_s:
    .long start_dtors
dtors_e:
    .long end_dtors
main:
    .long _main
v_syscall:
    .long 0x80020070
 
v_datald:
    .long _datald
v_edata:
    .long _edata
v_sdata:
    .long _sdata
v_ehld:
    .long _ehld
v_eeh:
    .long _eeh
v_seh:
    .long _seh
   
v_ram_bbss:
    .long _bbss
v_ram_ebss:
    .long _ebss
 