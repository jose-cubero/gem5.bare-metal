/*
 * Copyright (c) 2015, University of Kaiserslautern
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Matthias Jung
 */

NUM_CORES = DEFINED( NUM_CORES ) ? NUM_CORES : 4;

STACK_PCORE     = 0x01000;     /* 4KB stack space per core */
IRQ_STACK_PCORE = 0x00100;     /* 256B IRQ stack per core */

ENTRY(Vectors)
SECTIONS
{
    /* . = 0x80000000;              start of DRAM */
    .vectors 0x80000000:
    {
        _code_start = .;
        KEEP(*(StartUp))
    }

    .text : {
        *(.text*)
    }

    .data : { *(.data) }
    .bss : { *(.bss COMMON) }

    .stack (NOLOAD):
    {
        . = ALIGN(64);
        . = . + STACK_PCORE*NUM_CORES;
        stack_top = .;
    }

    .irq_stacks (NOLOAD):
    {
        . = ALIGN(64);
        . = . + IRQ_STACK_PCORE*NUM_CORES;
        irq_stack_top = .;
    }

    /*Page table shall not be in the same 1MB page as the .text and stack sections. */
    .pagetable 0x90000000 (NOLOAD):
    {
        _pagetable_start = .;
        . = . + 0x00100000;
    }
    PROVIDE (end = .);
}
