#include <stdio.h>
#include "dsp_functions.h"
#include "functions.h"
#include "klessydra_defs.h"

int main()
{
    Klessydra_En_Int();

    int hart_ID = Klessydra_get_coreID();

    sync_barrier_thread_registration();
    sync_barrier();

    volatile int div_res = 0;
    volatile int add_res = 0;

    if (hart_ID == 0) {
        int a = 100;
        int b = 3;
        int r;

        asm volatile(
            "div %[out], %[in1], %[in2]\n"
            : [out] "=r" (r)
            : [in1] "r" (a), [in2] "r" (b)
        );

        div_res = r;
    }
    else if (hart_ID == 1) {
        int x = 0;

        asm volatile(
            "addi %[val], %[val], 1\n"
            : [val] "+r" (x)
        );

        add_res = x;
    }

    return 0;
}