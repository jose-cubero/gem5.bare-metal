gem5 ARM Bare-Metal tests
===========================

This repository is based on (https://github.com/tukl-msd/gem5.bare-metal).
It contains a set of basic ARM bare-metal applications which can be used to run gem5 simulations in full system mode.

Included are 3 independent applications, placed inside a folder with the same name:

Name      | Description
----------|---------------------------------------------------------------------------------------
simple    | Single-core minimal "Hello World" application
interrupt | Single-core application showing the usage of the Generic Timer and Interrupt handling
multicore | Multi-core application with minimal MMU and cache initializaiton

## Requirements

### Working gem5 build

For information on gem5, including mandatory system dependencies and installation instructions please look at [gem5.org](http://www.gem5.org/Main_Page).

We test the generated ARM binaries with gem5 v21.0.0.0 and v21.1.0.1.

### GNU Arm Embedded Toolchain

You can download this cross-compilation toolchain from the [official website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads).

Alternatively, use a pre-built package for your system.

On Mac OSX you can yous macports:
``` bash
    sudo port install arm-none-eabi-gcc
    sudo port install arm-none-eabi-gdb
```
or Homebrew:
``` bash
    brew tap PX4/homebrew-px4
    brew update
    brew install gcc-arm-none-eabi
```

on Linux based systems (e.g. Ubuntu/Debian):
``` bash
    apt-get install gcc-arm-none-eabi
```

After installation, set a proper path to you bare metal toolchain in common/Makefile.

## Usage

### Single core applications: simple and interrupt

1. Change directory to the selected application folder (simple, interrupt)
2. Run make
3. Launch gem5 using the flags shown below.

Example for the "simple" app:

``` bash
    export GEM5_PATH="/path/to/gem5/repository"
    export TEST_BIN_PATH="/path/to/this/repository"

    cd simple
    make

    ${GEM5_PATH}/build/ARM/gem5.opt \
    ${GEM5_PATH}/configs/example/fs.py \
    --bare-metal \
    --kernel=${TEST_BIN_PATH}/simple/main.elf \
    --machine-type=VExpress_GEM5_V1
    --
```

### Build and run the multi core application

It is necessary to specify the desired number of cores to the build and launch command.
Example for 4 cores, atomic CPU model and L1 & L2 caches:

``` bash
    export GEM5_PATH="/path/to/gem5/repository"
    export TEST_BIN_PATH="/path/to/this/repository"
    export NUM_CORES=4

    cd multicore
    make NUM_CORES=${NUM_CORES}

    ${GEM5_PATH}/build/ARM/gem5.opt \
    ${GEM5_PATH}/configs/example/fs.py \
    --bare-metal \
    --cpu-type=AtomicSimpleCPU \
    --machine-type=VExpress_GEM5_V1 \
    --caches \
    --l2cache \
    --kernel=${TEST_BIN_PATH}/multicore/main.elf \
    --num-cpus=${NUM_CORES}
```

Licence
=======
```
Copyright (c) 2015, University of Kaiserslautern
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Matthias Jung
```
