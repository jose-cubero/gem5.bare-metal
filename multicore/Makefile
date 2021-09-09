include ../common/Makefile

NUM_CORES ?= 4
ARR_SIZE ?= 1000
REPEAT_WL ?=1
LNK_SCRIPT = multicore.ld

CFLAGS += -DNUM_CORES=$(NUM_CORES) -DARR_SIZE=$(ARR_SIZE) -DREPEAT_WL=${REPEAT_WL}

LNK_FILE_OPT := -Xlinker --defsym=NUM_CORES=$(NUM_CORES) $(LNK_FILE_OPT)

OBJS = boot.o ../common/syscalls.o main.o workloads.o armv7.o

all: main.elf

main.elf: $(OBJS) $(LNK_SCRIPT) Makefile
	$(CC) $(LNK_FILE_OPT) -o $@ $(OBJS) $(LNK_OPT)

boot.o: Makefile
	$(CPP) boot.s $(CFLAGS) | $(AS) $(ASFLAGS) -o boot.o

armv7.o: Makefile
	$(CPP) armv7.s $(CFLAGS) | $(AS) $(ASFLAGS) -o armv7.o

clean:
	rm -f *.o *.elf
