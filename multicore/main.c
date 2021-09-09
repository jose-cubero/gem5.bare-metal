#include <stdio.h>
#include <stdlib.h>
#include "armv7.h"
#include "workloads.h"

#ifndef NUM_CORES
#define NUM_CORES 4
#endif

int arr[NUM_CORES][ARR_SIZE+1];

int main()
{

#ifdef REPEAT_WL
    unsigned int repeat=REPEAT_WL;
#else
    unsigned int repeat=1;
#endif

    unsigned int id = 0;
    unsigned int sctlr;
    int r=0;

    id = getCPUID();

    sctlr = enable_caches();

    while (repeat--)
    {
       r=bsort_main(arr[id], ARR_SIZE);
        if (r)
            printf("CPU%d: bubble sort failed\n", id);
    }

    printf("CPU%d: done\n", id);

    sctlr = disable_caches();
	return 0;
}