/* Set our output format */
OUTPUT_FORMAT(elf64-x86-64)

/* Set Entry point */
ENTRY(drvmain)

/* Define Program Headers */
PHDRS
{
    init PT_LOAD;
    text PT_LOAD;
    panic PT_LOAD;
    repair PT_LOAD;
    rodata PT_LOAD;
    data PT_LOAD;
}

SECTIONS
{
    . = 0x1000;

    /* Define a section to contain the initialization */
    .init : {
        KEEP(*(.magic_number))
        *(.init .init.*)
    } :init

    /* Move to the next memory page */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .text : {
        *(.text .text.*)
    } :text

    /* Move to the next memory page */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .panic : {
        *(.panic .panic.*)
    } :panic

    /* Move to the next memory page */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .repair : {
        *(.repair .repair.*)
    } :repair

    /* Move to the next memory page */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    .data : {
        *(.data .data.*)
    } :data

    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    } :data

    /DISCARD/ : {
        *(.eh_frame*)
        *(.note .note.*)
    }
}