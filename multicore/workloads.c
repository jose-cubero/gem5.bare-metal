#include <stdio.h>

#include "workloads.h"

void print_arr(int arr[], unsigned num)
{
    for (unsigned i=1; i<num; i++)
        printf("%d\n",arr[i]);
}

static long Rand (long seed) {
    seed = (seed * 1309L + 13849L) & 65535L;  /* constants to long WR*/
    return seed;     
}

static void bInitarr(int *arr, unsigned int size, long seed, int *biggest,int *littlest)	{
	unsigned int i;
	long temp;
	*biggest = 0; *littlest = 0;

	for ( i = 1; i <= size; i++ ) {
	    seed = Rand(seed);
        temp = (int) seed;

	    /* converted constants to long in next stmt, typecast back to int WR*/
	    arr[i] = (int)(temp - (temp/100000L)*100000L - 50000L);
	    if ( arr[i] > *biggest ) *biggest = arr[i];
	    else if ( arr[i] < *littlest ) *littlest = arr[i];
	}
}

int bsort_main(int arr[], unsigned int size)
{
    int biggest, littlest;
    long seed = SEED;

    bInitarr(arr, size, seed, &biggest, &littlest);

	int i, j, top;
	top=size;

	while ( top>1 ) {
		
		i=1;
		while ( i<top ) {
			
			if ( arr[i] > arr[i+1] ) {
				j = arr[i];
				arr[i] = arr[i+1];
				arr[i+1] = j;
			}
			i=i+1;
		}
		
		top=top-1;
	}

 	if ( (arr[1] != littlest) || (arr[size] != biggest) )
    {
        return -1;
    }
#ifdef PRINT_ARR
    print_arr(arr, 100);
#endif
    return 0;
}