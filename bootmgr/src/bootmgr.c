#include "bootmgr.h"

void __start() {
start:
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("hlt");
}