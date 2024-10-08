# Yutboo Driver Protocol

Yutboo drivers must be set up in a specific format to ensure proper function.

## Format
Yutboo drivers use the ELF format. Compile all drivers as so.

Drivers must have a main entry point of 'drvmain'

***.init MUST BE THE FIRST SECTION***

***Remember that ELF executables must be signed with the ELF Signature: 0x7F454C46***

## Sections
Yutboo drivers should have these sections:

1. ".init": This is the section called on initialization, it must be signed with the signature 0x59626F6F, or 'Yboo'. This is a required section.
2. ".text": This is the section called on routine usage. The RBX register will be loaded with the action wanting to be done, the driver will act depending on the RBX. This is a required section.
3. ".panic": This section is called on a device or system panic. While this section is not required, it is strongly recommended. In the absence of a panic section, the system will shut down the device as gracefully as possible.
4. ".repair": This section is called when the device needs a repair. Whether it be a recalibration, a firmware update, etc, this section will be called. This section is also strongly recommended. If this section is absent, the system will repair the device as best as possible. Specific needs will not be met.
5. ".data": Straightforward, this section is for initialized data. This is required.
6. ".rodata": Readonly data, this section is for constant data. This is required.
7. ".bss": Straightforward, this section is for uninitialized data. This is required.

***".init" MUST BE LOCATED AT 0x1000***

**Failure to fulfill this protocol will result in driver failure.**
## All Drivers Run in Kernel Space