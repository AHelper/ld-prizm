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
        ram (rwx) : o = 0x08100700, l =  522495 /* old 524283 */  /* 0x1FFFF */
        heap (rwx) : o =0x88160004, l = 1788
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
