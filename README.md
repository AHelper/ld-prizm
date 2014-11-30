ld-prizm
========
This project is an attempt to add support for running ELF binaries including dynamic linking.  This project is broken up in *eh*, the custom exception handling code, and *dl*, the dynamic linker.

eh
--
In order for a custom exception handler to be used in an addin, quite a few changes must happen with the structure of the generated binary.  This subproject includes the source of the exception handler as well as a modified crt0.S (crtEH.S) and prizm.x (eh.x) linker script. 

There are certain precautions that must be observed while the EH has been installed.  First, the EH **must** be uninstalled before another process is switched to.  Failure to do so will trigger an OS reboot.  Second, the full effects of overriding the exception handler are not fully known.  This may cause highly unexpected behavior or data loss/damage (which can be avoided once more is known about how the OS handles exceptions).

dl
--
This is the dynamic linker that handles shared objects.  No progress has been made on this as-of yet.