#ifndef NUM_CORES
.equ NUM_CORES, 4
#endif

.equ UNLOCKED, 0xFF

.section StartUp, "ax"
.balign 0x20

.global Vectors
Vectors:

    b Reset_Handler    /* Reset */
    b .                /* Undefined */
    b .                /* SWI */
    b .                /* Prefetch Abort */
    b .                /* Data Abort */
    b .                /* reserved */
    b .                /* IRQ */
    b .                /* FIQ */

.global Reset_Handler
.type Reset_Handler, "function"
Reset_Handler:

    /*Initialize InitDone Semaphore */
    ldr r1, =.LinitDone
    mov r0, #0
    str r0, [r1]

    //Set ACTLR.SMP bit
    bl  joinSMP               //does nothing, SMP bit not implemented in gem5

    // Disable caches, MMU and branch prediction in case they were left enabled from an earlier run
    // This does not need to be done from a cold reset
    // ------------------------------------------------------------
    mrc p15, 0, r0, c1, c0, 0       // Read System Control Register
    bic r0, r0, #(0x1 << 12)        // Clear I, bit 12, to disable I Cache
    bic r0, r0, #(0x1 << 11)        // Clear Z, bit 11, to disable branch prediction
    bic r0, r0, #(0x1 <<  2)        // Clear C, bit  2, to disable D Cache
    bic r0, r0, #(0x1 <<  1)        // Clear A, bit  1, to disable strict alignment fault checking
    bic r0, r0, #0x1                // Clear M, bit  0, to disable MMU
    mcr p15, 0, r0, c1, c0, 0       // Write System Control Register
    isb

    /* Initialize Stack Pointer, Use CPU to compute mem address */
    mrc p15, 0, r0, c0, c0, 5   // Get CPU ID.
    bic r0, r0, #0xFF000000     // Mask off, leaving 24 LSBs
    ldr r1, =stack_top
    sub r1, r1, r0, LSL #12     // 4KB stack per CPU
    mov sp, r1

    // Set Vector Base Address Register (VBAR)
    // ------------------------
    ldr r0, =Vectors
    mcr p15, 0, r0, c12, c0, 0

    bl  disableHighVecs         //Ensure that V-bit is cleared

    bl  invalidateCaches        //Not mandatory for gem5.

    // Clear Branch Prediction Array
    mov r0, #0x0
    mcr p15, 0, r0, c7, c5, 6     // BPIALL - Invalidate entire branch predictor array
    isb                           // BPIALL, gem5 does not implement it.

    // Invalidate TLBs
    mov r0, #0x0
    mcr p15, 0, r0, c8, c7, 0     // TLBIALL - Invalidate entire Unified TLB !!
    isb

    // Set up Domain Access Control Reg
    mrc p15, 0, r0, c3, c0, 0      // Read Domain Access Control Register
    ldr r0, =0x55555555            // Initialize every domain entry to b01 (client)
    mcr p15, 0, r0, c3, c0, 0      // Write Domain Access Control Register
    isb

  // Set location of level 1 page table
  //------------------------------------
  // 31:14 - Base addr
  // 13:5  - 0x0
  // 4:3   - RGN 0x0 (Outer Noncachable)
  // 2     - P   0x0
  // 1     - S   0x0 (Non-shared)
  // 0     - C   0x0 (Inner Noncachable)
    ldr r0, =_pagetable_start       //address is aligned and all 14 LSBs are zero!
    mcr p15, 0, r0, c2, c0, 0

    //SMP Initialization
    mrc p15, 0, r0, c0, c0, 5   // Get CPU ID.
    bics r0, r0, #0xFF000000
    beq .Lcpu0_only

    // Holding Pen. Wait for CPU0 to finish initialization
.holding_pen:
    ldr r0, .LinitDone  //TODO validate, this against double instruction..
    cmp r0, #1
    dsb                         // Clear all pending data accesses
    wfene
    bne .holding_pen

    // Enable MMU
    // -----------
    // Leave the caches disabled. They will be enabled them inside main.
    mrc     p15, 0, r0, c1, c0, 0       // Read System Control Register
    orr     r0, r0, #0x1                // Set M bit 0 to enable MMU
    mcr     p15, 0, r0, c1, c0, 0       // Write System Control Register
    isb

    /*Run Main*/
    mov r0, #0
    bl main

    /*notify end */
    ldr r0, =.Llock
.lock_mutex:
    ldrex   r1, [r0]            // Read lock field
    cmp     r1, #UNLOCKED       // Compare with "unlocked"
    wfene                       // If mutex is locked, go into standby
    bne     .lock_mutex         // On waking re-check the mutex

    // Attempt to lock mutex
    // -----------------------
    mrc     p15, 0, r1, c0, c0, 5   // Read CPU ID register
    bic     r1, r1, #0xFF000000     // Mask off, leaving 24 LSBs

    strex   r2, r1, [r0]            // Attempt to lock mutex, by write CPU's ID to lock field
    cmp     r2, #0x0                // Check whether store completed successfully (0=succeeded)
    bne     .lock_mutex             // If store failed, go back to beginning and try again
    dmb

    /*update counter */
    ldr r1, .Lcount
    add r1, r1, #1
    str r1, .Lcount

//    LDR r0, =.Llock
.unlockMutex:
    // Unlock mutex
    // -------------
    dmb                             // Ensure that accesses to shared resource have completed
    mov     r1, #UNLOCKED            // Write "unlocked" into lock field
    str     r1, .Llock
    dsb                             // Ensure that no instructions following the barrier execute until
                                    // all memory accesses prior to the barrier have completed.
    sev                             // Send event to other CPUs, wakes anyone waiting on a mutex (using WFE)
.sleep_forever:
    wfe
    b .sleep_forever

.Lcpu0_only:
    /*Initialize sync mutex */
    mov r0, #UNLOCKED
    ldr r1, =.Llock
    str r0, [r1]
    mov r0, #0x0
    ldr r1, =.Lcount
    str r0, [r1]

    bl  init_pagetable

    // Enable MMU, Leave the caches disabled
    mrc     p15, 0, r0, c1, c0, 0       // Read System Control Register
    orr     r0, r0, #0x1                // Set M bit 0 to enable MMU before scatter loading
    mcr     p15, 0, r0, c1, c0, 0       // Write System Control Register
    isb

    //init done, sync
    ldr r1, =.LinitDone
    mov r0, #1
    str r0, [r1]
    dsb
    sev

    /*Run Main0*/
    mov r0, #0
    bl main
.Lcpu0_spin_end:
    wfe
    ldr r0, .Lcount
    cmp r0, #NUM_CORES-1
    bne .Lcpu0_spin_end
    mov r0, #0
    bl _exit

.global _exit
.type _exit, "function"
_exit:
    mov r0, #0
    mov r1, #0
    .inst 0xEE000110 | (0x21 << 16) //gem5 Sim exit m5op
    wfi

// Shared variables for synchronization
.Llock:
    .skip 4
.Lcount:
    .skip 4
.LinitDone:
    .skip 4
