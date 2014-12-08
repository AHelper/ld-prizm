/*
 * Original linker script was used from libfxcg.  Modified for ld-prizm. libfxcg copywrite block below:

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
/* OUTPUT_FORMAT(binary) */
OUTPUT_FORMAT(binary)
/*OUTPUT_FORMAT(elf32-sh)*/
OUTPUT_ARCH(sh3)
 
/* Entry point.  Not really important here, since doing binary output */
ENTRY(initialize)
 
MEMORY
{
        /* Loads code at 300000, skips g3a header */
        rom (rx) : o = 0x00300000, l = 1024k
        ram (rwx) : o = 0x0810264C, l =  514483 /* old 524283 */  /* 0x1FFFF */
        heap (rwx) : o =0x88160004, l = 9804
}
 
SECTIONS
{
        /* Code, in ROM */
        .text : {
                *(.pretext)     /* init stuff */
                *(.text)
                *(.text.*)
                *(.gnu.linkonce.t*)
        } > rom
       
        /* Read-only data, in ROM */
        .rodata : {
		start_ctors = .;
		*(SORT(.ctors*))
		end_ctors = .;
		
		start_dtors = .;
		*(SORT(.dtors*))
		end_dtors = .;
		
                *(.rodata)
                *(.rodata.*)
        } > rom
        
        .eh : {
          _ehld = LOADADDR(.eh) ;
          _seh = . ;
          KEEP(*(.eh))
          KEEP(*(.eh.*))
          _eeh = . ;
        } >heap AT>rom
       
        /* RW initialized data, VMA in RAM but LMA in ROM */
        .data : {
                _datald = LOADADDR(.data) ;
                _sdata = . ;
                *(.data)
                *(.data.*);
                *(.gnu.linkonce.d*)
                _edata = . ;
        } >ram AT>rom
       
        /* Uninitialized data (fill with 0), in RAM */
        .bss : {
                _bbss = . ;
                *(.bss) *(COMMON);
                *(.gnu.linkonce.b*)
                _ebss = . ;
        } >ram
        
        .gcc_except_table : {
		*(.gcc_except_table)
	} > rom
	
	.eh_frame : {
		*(.eh_frame)
	} > rom
	
	.got : {
          _GLOBAL_OFFSET_TABLE_ = . ;
          *(.got)
          *(.igot)
        } > ram
        
        .dynamic        : { *(.dynamic) }
        .dynsym         : { *(.dynsym) }
        .dynstr         : { *(.dynstr) }
        rela.dyn       :
        {
          *(.rela.init)
          *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
          *(.rela.fini)
          *(.rela.rodata .rela.rodata.* .rela.gnu.linkonce.r.*)
          *(.rela.data .rela.data.* .rela.gnu.linkonce.d.*)
          *(.rela.tdata .rela.tdata.* .rela.gnu.linkonce.td.*)
          *(.rela.tbss .rela.tbss.* .rela.gnu.linkonce.tb.*)
          *(.rela.ctors)
          *(.rela.dtors)
          *(.rela.got)
          *(.rela.bss .rela.bss.* .rela.gnu.linkonce.b.*)
          *(.rela.ldata .rela.ldata.* .rela.gnu.linkonce.l.*)
          *(.rela.lbss .rela.lbss.* .rela.gnu.linkonce.lb.*)
          *(.rela.lrodata .rela.lrodata.* .rela.gnu.linkonce.lr.*)
          *(.rela.ifunc)
        }
}
