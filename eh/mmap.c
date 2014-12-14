#include "mmap.h"
#include "eh.h"
#include <sys/types.h>
#include <fxcg/file.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fxcg/keyboard.h>

typedef struct map_t
{
  void* start, *end;
  unsigned short *path;
  off_t offset;
  struct map_t *next;
} mmap_t;

static mmap_t *mmaps = (mmap_t*)0;

void munmap(void *addr)
{
  mmap_t *map = mmaps, *prev = 0;
  
  errno = 0;
  
  while(map && !(addr >= map->start && addr < map->end))
  {
    prev = map;
    map = map->next;
  }
  
  if(!map)
  {
    errno = EINVAL;
    return;
  }
  
  // Purge the old pages, can't trust them.
  // Much easier to re-add
  volatile unsigned int* ptr;
  for(ptr = (volatile unsigned int*)EH_Page_Table; (volatile unsigned int)ptr != EH_Data[4]; ptr += 2)
  {
    unsigned int masked = *ptr & 0xFFFFFFFB;
    if(masked >= (unsigned int)map->start && masked <= (unsigned int)map->end)
    {
      EH_DelPage(masked);
      ptr -= 2;
    }
  }
  
  if(prev)
  {
    prev->next = map->next;
  } else {
    mmaps = map->next;
  }
  
  free(map->path);
  free(map);
}

void mremap(void *addr)
{
  mmap_t *map = mmaps;
  
  errno = 0;
  
  while(map && (map->start > addr || map->end <= addr))
    map = map->next;
  
  if(!map)
  {
    errno = EINVAL;
    return;
  }
  
  // Purge the old pages, can't trust them.
  // Much easier to re-add
  volatile unsigned int* ptr;
  for(ptr = (volatile unsigned int*)EH_Page_Table; (volatile unsigned int)ptr != EH_Data[4]; ptr += 2)
  {
    unsigned int masked = *ptr & 0xFFFFFFFB;
    if(masked >= (unsigned int)map->start && masked <= (unsigned int)map->end)
    {
      EH_DelPage(masked);
      ptr -= 2;
    }
  }
  
  // Add a new mapping
  int handle = Bfile_OpenFile_OS(map->path, READ);
  
  if(handle < 0)
  {
    errno = EBADF;
    return;
  } else {
    int pos = map->offset;
    int size = Bfile_GetFileSize_OS(handle);
    unsigned char buffer[0x1000];
    unsigned int* ptr = map->start;
    
    Bfile_SeekFile_OS(handle, pos);
    size -= pos;
    
    while(ptr < (unsigned int*)map->end)
    {
      int read = size > 0x1000 ? 0x1000 : size;
      
      Bfile_ReadFile_OS(handle, buffer, read, -1);
      unsigned int search = 0x80000000;
      
      for(; search < 0x82000000; search+=0x1000)
      {
        if(memcmp((unsigned int*)search, buffer, read) == 0)
        {
          // Found a match
          if(!EH_AddPage((unsigned int)ptr, search, TLB_FLAG_4KB))
          {
            errno = -11;
            ptr = map->end;
            break;
          }
          ptr += 0x1000 / sizeof(unsigned int);
          size -= read;
          break;
        }
      }
      if(search >= 0x82000000)
      {
        errno = EIO;
        break;
      }
    }
  }
  
  Bfile_CloseFile_OS(handle);
}

// ENOMEM - The memory would overlap an existing mapped location
// EINVAL - Bad alignment (must be at least 4KB aligned)
#define MMAP_STARTING_ADDRESS (void*)0x00100000

void *mmap(void *addr, size_t length, int prot, int flags, const char* file, off_t offset)
{
  mmap_t* next_map;
  unsigned short *filename;
  
  errno = 0;
  
  if(((unsigned int)addr | (unsigned int)offset | (unsigned int)length) & 0xFFF)
  {
    // Not page-aligned (1KB)
    errno = EINVAL;
    return MAP_FAILED;
  }
  
  filename = (unsigned short*)malloc((strlen(file)+1)*2);
  Bfile_StrToName_ncpy(filename, (const unsigned char*)file, strlen(file) + 1);
  int handle = Bfile_OpenFile_OS(filename, READ);
  
  if(handle < 0)
  {
    errno = EBADF;
    free(filename);
    Bfile_CloseFile_OS(handle);
    return MAP_FAILED;
  }
  
  if((length <= 0 && Bfile_GetFileSize_OS(handle) < offset) ||
    (Bfile_GetFileSize_OS(handle) < length + offset))
  {
    errno = EINVAL;
    free(filename);
    Bfile_CloseFile_OS(handle);
    return MAP_FAILED;
  }
  
  int size = Bfile_GetFileSize_OS(handle);
  if(length <= 0)
    length = (size + 0xFFF) & 0xFFFFF000;
  
  Bfile_CloseFile_OS(handle);
  
  if(!addr)
  {
    // Pick the first location that works.
    addr = MMAP_STARTING_ADDRESS;
    mmap_t *map = mmaps;
    
    while(map)
    {
      if(addr < map->end && (unsigned int)addr + length > (unsigned int)map->start)
      {
        addr = map->end;
        map = mmaps;
      }
      else
        map = map->next;
    }
  }
  
  if(!mmaps)
  {
    mmaps = (mmap_t*)malloc(sizeof(mmap_t));
    next_map = mmaps;
  } else {
    next_map = mmaps;
    
    while(next_map->next)
    {
      if(addr < next_map->end && (unsigned int)addr + length > (unsigned int)next_map->start)
      {
        errno = ENOMEM;
        return MAP_FAILED;
      }
      next_map = next_map->next;
    }
    
    if(addr < next_map->end && (unsigned int)addr + length > (unsigned int)next_map->start)
    {
      errno = ENOMEM;
      return MAP_FAILED;
    }
    
    next_map = (next_map->next = (mmap_t*)malloc(sizeof(mmap_t)));
  }
  
  next_map->start = addr;
  next_map->end = (unsigned int*)((unsigned int)addr + length);
  next_map->offset = offset;
  next_map->path = filename;
  next_map->next = (mmap_t*)0;
  
  mremap(addr);
  
  if(errno)
    return MAP_FAILED;
  else
    return addr;
}