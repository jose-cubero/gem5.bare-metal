/* Helper functions for ARMv7-A */

//////////////////////////////////////////////////////////////
.global getCPUID
.type getCPUID, "function"
/* int getCPUID(void)
   Returns the CPU ID (0 to N) of the CPU executed on */
getCPUID:
    mrc     p15, 0, r0, c0, c0, 5   // Read CPU ID register
    bic     r0, r0, #0xFF000000   // Mask off, leaving the CPU ID field, 24 bit. see explanation below
    bx      lr

//FROM: gem5/src/arch/arm/utility.cc
    // Multiprocessor Affinity Register MPIDR from Cortex(tm)-A15 Technical
    // Reference Manual
    //
    // bit   31 - Multi-processor extensions available
    // bit   30 - Uni-processor system
    // bit   24 - Multi-threaded cores
    // bit 11-8 - Cluster ID
    // bit  1-0 - CPU ID
    //
    // We deliberately extend both the Cluster ID and CPU ID fields to allow
    // for simulation of larger systems

//////////////////////////////////////////////////////////////
.global joinSMP
.type joinSMP, "function"
/* void joinSMP(void)
   Sets the ACTRL.SMP bit */
joinSMP:
    // SMP status is controlled by bit 6 of the CP15 Aux Ctrl Reg
    mrc     p15, 0, r0, c1, c0, 1   // Read ACTLR
    mov     r1, r0
    orr     r0, r0, #0x040          // Set bit 6
    cmp     r0, r1
    mcrne   p15, 0, r0, c1, c0, 1   // Write ACTLR
    isb                             // Synchronize fetched instruction stream
    bx      lr

//////////////////////////////////////////////////////////////
.global disableHighVecs
.type disableHighVecs, "function"
  // void disable_highvecs(void);
disableHighVecs:
    mrc     p15, 0, r0, c1, c0, 0 // Read System Control Register (SCTLR)
    bic     r0, r0, #(1 << 13)    // Clear the V bit (bit 13)
    mcr     p15, 0, r0, c1, c0, 0 // Write Control Register
    isb
    bx      lr

//////////////////////////////////////////////////////////////
.global enable_mmu
.type enable_mmu, "function"
// unsigned int enable_caches(void);
// returns final value of SCTLR
enable_mmu:
    dsb
    mrc p15, 0, r0, c1, c0, 0      // Read System Control Register
    orr r0, r0, #0x1               // Set M bit 0 to enable MMU
    mcr p15, 0, r0, c1, c0, 0      // Write System Control Register
    isb
    dsb
    mrc p15, 0, r0, c1, c0, 0
    bx  lr

//////////////////////////////////////////////////////////////
.global disable_mmu
.type disable_mmu, "function"
// unsigned int disable_mmu(void);
// returns final value of SCTLR
disable_mmu:
    dsb
    mrc p15, 0, r0, c1, c0, 0      // Read System Control Register
    bic r0, r0, #0x1               // ReSet M bit 0 to disable MMU
    mcr p15, 0, r0, c1, c0, 0      // Write System Control Register
    isb
    dsb
    mrc p15, 0, r0, c1, c0, 0
    bx  lr

//////////////////////////////////////////////////////////////
.global enable_caches
.type enable_caches, "function"
// unsigned int enable_caches(void);
// returns final value of SCTLR
enable_caches:
/*  Enable caches and branch prediction */
    mrc p15, 0, r0, c1, c0, 0      // Read System Control Register
    orr r0, r0, #(0x1 << 12)       // Set I bit 12 to enable I Cache
    orr r0, r0, #(0x1 << 2)        // Set C bit  2 to enable D Cache
    orr r0, r0, #(0x1 << 11)       // Set Z bit 11 to enable branch prediction
    mcr p15, 0, r0, c1, c0, 0      // Write System Control Register
    isb
    mrc p15, 0, r0, c1, c0, 0
    bx  lr

//////////////////////////////////////////////////////////////
.global disable_caches
.type disable_caches, "function"
  // unsigned int disable_caches(void);
  // returns final value of SCTLR
disable_caches:
    mrc p15, 0, r0, c1, c0, 0      // Read System Control Register
    bic r0, r0, #(0x1 << 12)       // ReSet I bit 12 to disable I Cache
    bic r0, r0, #(0x1 << 2)        // ReSet C bit  2 to disable D Cache
    bic r0, r0, #(0x1 << 11)       // ReSet Z bit 11 to disable branch prediction
    mcr p15, 0, r0, c1, c0, 0      // Write System Control Register
    isb
    mrc p15, 0, r0, c1, c0, 0
    bx  lr

//////////////////////////////////////////////////////////////
//Page attribute templates
.equ L1_NONCOHERENT, 0x00000c1e
.equ L1_COHERENT,    0x00015C06
// S:1 shared
// AP:011 (RW full access),
// TEX[2]:1, Cacheable mem, TEX[1:0]=C:B = 01, Write-back, Write-allocate
.equ L1_DEVICE,      0x00010C02
// S:1 shared
// AP:011 (RW full access),
// TEX[2:0]:000 C:B =00, Non-cacheable, strongly ordered
.equ UART_ADDR,      0x1c090000

.global init_pagetable
.type init_pagetable, "function"
init_pagetable:

  // Translation tables
  // -------------------
  // The translation tables are generated at boot time.
  // First the table is zeroed.  Then the individual valid
  // entries are written.
  //
    ldr  r0, =_pagetable_start

@   // Fill table with zeros. Not necessary in gem5
@   mov     r2, #1024                 // Set r3 to loop count (4 entries per iteration, 1024 iterations)
@   mov     r1, r0                    // Make a copy of the base dst
@   mov     r3, #0
@   mov     r4, #0
@   mov     r5, #0
@   mov     r6, #0
@ ttb_zero_loop:
@   stmIA   r1!, {r3-r6}              // Store out four entries
@   subS    r2, r2, #1                // Decrement counter
@   bne     ttb_zero_loop

/// initialize TTBCR.
    mov    R0, #0                   // Use    short descriptor.
    mcr    P15, 0, R0, C2, C0, 2    // Base address is 16KB aligned.
                                    // Perform translation table walk for TTBR0.
// Initialize SCTLR.AFE.
    mrc    P15, 0, R1, C1, C0, 0    //   Read SCTLR.
    bic       R1, R1, #(0x1 <<29)   //   Set    AFE  to 0 and disable Access Flag.
    mcr    P15, 0, R1, C1, C0, 0    //   Write SCTLR.

// Initialize TTBR0.
    ldr    R0, =_pagetable_start    // ttb0_base must be a 16KB-aligned address.
    mov    R1, #0x2B                // The translation table walk is normal, inner
    orr    R1,   R0,  R1            // and    outer cacheable, WB WA, and inner
    mcr    P15, 0, R1, C2, C0, 0    // shareable.

  // PTE 1. Region covering program code and data
    ldr     r1,=_code_start
    lsr     r1, r1, #20               // Clear bottom 20 bits, to find which 1MB block it is in
    lsl     r2, r1, #2                // Make a copy, and multiply by four.  This gives offset into the page tables
    lsl     r1, r1, #20               // Put back in address format
    ldr     r3, =L1_COHERENT          // Descriptor template
    orr     r1, r1, r3                // Combine address and template
    str     r1, [r0, r2]              // Store table entry

  // PTE 2. For Device memory
    ldr     r1,=UART_ADDR
    lsr     r1, r1, #20               // Clear bottom 20 bits, to find which 1MB block it is in
    lsl     r2, r1, #2                // Make a copy, and multiply by four.  This gives offset into the page tables
    lsl     r1, r1, #20               // Put back in address format
    ldr     r3, =L1_DEVICE            // Descriptor template
    orr     r1, r1, r3                // Combine address and template
    str     r1, [r0, r2]              // Store table entry

    dsb
    bx lr

//////////////////////////////////////////////////////////////
.global invalidateCaches
.type invalidateCaches, "function"
// void invalidateCaches(void);
invalidateCaches:
    /* Based on code example given in section B2.2.4/11.2.4 of Armv7-A/R Architecture Reference Manual (DDI 0406B) */
    push    {r4-r12}
    mov     r0, #0
    mcr     p15, 0, r0, c7, c5, 0       // ICIALLU - Invalidate entire I Cache, and flushes branch target cache

    mrc     p15, 1, r0, c0, c0, 1       // Read CLIDR, in gem5, this is always 0.
    ands    r3, r0, #0x7000000
    mov     r3, r3, LSR #23             // Cache level value (naturally aligned)
    beq     invalidate_caches_finished  //gem5, always jumps.
    mov     r10, #0

invalidate_caches_loop1:
    add     r2, r10, r10, LSR #1      // Work out 3xcachelevel
    mov     r1, r0, LSR r2            // bottom 3 bits are the Cache type for this level
    and     r1, r1, #7                // get those 3 bits alone
    cmp     r1, #2
    blt     invalidate_caches_skip    // no cache or only instruction cache at this level
    mcr     p15, 2, r10, c0, c0, 0    // write the Cache Size selection register
    isb                               // ISB to sync the change to the CacheSizeID reg
    mrc     p15, 1, r1, c0, c0, 0     // reads current Cache Size ID register
    and     r2, r1, #7                // extract the line length field
    add     r2, r2, #4                // add 4 for the line length offset (log2 16 bytes)
    ldr     r4, =0x3FF
    ands    r4, r4, r1, LSR #3        // R4 is the max number on the way size (right aligned)
    clz     r5, r4                    // R5 is the bit position of the way size increment
    ldr     r7, =0x00007FFF
    ands    r7, r7, r1, LSR #13       // R7 is the max number of the index size (right aligned)

invalidate_caches_loop2:
    mov     r9, R4                    // R9 working copy of the max way size (right aligned)

invalidate_caches_loop3:
    orr     r11, r10, r9, LSL r5      // factor in the way number and cache number into R11
    orr     r11, r11, r7, LSL r2      // factor in the index number
    mcr     p15, 0, r11, c7, c6, 2    // DCISW - invalidate by set/way
    subs    r9, r9, #1                // decrement the way number
    bge     invalidate_caches_loop3
    subs    r7, r7, #1                // decrement the index
    bge     invalidate_caches_loop2

invalidate_caches_skip:
    add     r10, r10, #2              // increment the cache number
    cmp     r3, r10
    bgt     invalidate_caches_loop1

invalidate_caches_finished:
    pop     {r4-r12}
    bx      lr
