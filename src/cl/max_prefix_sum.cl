#ifdef __CLION_IDE__
#include <libgpu/opencl/cl/clion_defines.cl>
#endif

#line 6

#define WORK_GROUP_SIZE 64

__kernel void max_prefix_sum(int n, __global int* nums, __global int* maxs, __global int* idxs,
                             __local int* cnums, __local int* cmaxs, __local int* cidxs) {
    const int i = get_global_id(0);
    const int li = get_local_id(0);
    const int ls = get_local_size(0);

    cnums[li] = 0;
    cmaxs[li] = 0;
    cidxs[li] = 0;

    if (i < n) {
        cnums[li] = nums[i];
        cmaxs[li] = maxs[i];
        cidxs[li] = idxs[i];
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    for (int cd = 1; cd < ls; cd *= 2) {
        int mask = (cd - 1) | 1;
        if ((li & mask) == 0 && li + cd < ls && i + cd < n) {
            cidxs[li] = cmaxs[li] > cnums[li] + cmaxs[li + cd] ? cidxs[li] : cidxs[li + cd];
            cmaxs[li] = max(cmaxs[li], cnums[li] + cmaxs[li + cd]);
            cnums[li] += cnums[li + cd];
        }

    barrier(CLK_LOCAL_MEM_FENCE);

    }

    if (li == 0) {
        nums[i] = cnums[0];
        maxs[i] = cmaxs[0];
        idxs[i] = cidxs[0];
    }
}