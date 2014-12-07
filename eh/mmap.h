#ifndef __MMAP_H
#define __MMAP_H

#ifdef __cplusplus
extern "C" {
#endif
  
#include <sys/types.h>
#include <stddef.h>

#define MAP_FAILED ((void *) -1)

/**
 * Removes the mapping for a file.
 * 
 * errno is set for certain errors:
 * EINVAL - addr doesn't match any currently mapped region starting addresses.
 * 
 * @arg addr Starting address for a mapped memory region
 */
void munmap(void *addr);

/**
 * Updates the MMU mapping for a file.
 * 
 * errno is set for certain errors:
 * EINVAL - addr doesn't match any currently mapped region starting addresses.
 * EBADF - The file the region is mapped to doesn't exist anymore.
 * EIO - Internal error
 * 
 * @arg addr Starting address for a mapped memory region
 * @warning Timers cannot be running/installed when calling this  
 * 
 */
void mremap(void *addr);

// ENOMEM - The memory would overlap an existing mapped location
// EINVAL - Bad alignment (must be at least 4KB aligned)
/**
 * Maps a region of a file to memory. Similar to Linux's mmap function.
 * 
 * @todo prot and flags are ignored
 * @todo Only 4KB page mappings are done.
 * 
 * errno is set for certain errors:
 * ENOMEM - The memory would overlap an existing mapped location
 * EINVAL - Bad alignment (must be at least 4KB aligned) or the range is invalid for the given file
 * EBADF - File to map to doesn't exist.
 * EIO - Internal error
 * 
 * @arg addr Address to map to in virtual memory that is at least 4KB aligned
 * @arg length Length in byts to map from the file, or 0 to map all
 * @arg prot ignored
 * @arg flags ignored
 * @arg file Full path to a file to map to from flash
 * @arg offset Offset in the file to start mapping from
 * @returns Pointer to mapped region or MAP_FAILED on error.
 */
void *mmap(void *addr, size_t length, int prot, int flags, char* file, off_t offset);

#ifdef __cplusplus
}
#endif

#endif // __MMAP_H