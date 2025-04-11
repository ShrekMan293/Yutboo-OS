#include "stddef.h"
#include "stdint.h"
#include "limine.h"

int memcmp(const void *s1, const void *s2, size_t n);
void *memmove(void *dest, const void *src, size_t n);
void *memset(void *s, int c, size_t n);
void *memcpy(void *dest, const void *src, size_t n);
uint64_t memscan(limine_memmap_request* request);