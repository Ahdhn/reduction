#include <assert.h>
#include <cuda_runtime.h>
#include <stdio.h>
#include <limits>
#include <numeric>
#include <random>

#include <thrust/copy.h>
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/random.h>
#include <thrust/transform.h>

#include "helper.h"

__device__ __inline__ void reset_res(volatile int* d_flag,
                                     int*          d_res,
                                     int           init_value)
{
    __threadfence();
    while (true) {
        __threadfence();

        int prv = ::atomicCAS((int*)d_flag, 0, 1);

        // means some other thread set the value
        if (prv == 2) {
            break;
        }

        // means this is the first threads to set the flag
        if (prv == 0) {
            __threadfence();
            d_res[0] = init_value;            
            __threadfence();
            // set the flag to 2, so other threads stop spinning
            ::atomicExch((int*)d_flag, 2);
            break;
        }
    }
}

__device__ __inline__ void reset_flag(volatile int* d_counter,
                                      volatile int* d_flag,
                                      int           size)
{
    __threadfence();
    int id = atomicAdd((int*)d_counter, 1);
    if (id == size - 1) {
        // this is the last thread to contrinute so it can reset the counter and
        // the flag
        d_flag[0]    = 0;
        d_counter[0] = 0;
    }
}

__global__ void sum(int*          d_data,
                    int*          d_res,
                    volatile int* d_flag,
                    volatile int* d_counter,
                    int           init_value,
                    int           size)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;


    reset_res(d_flag, d_res, init_value);

    if (idx < size) {
        atomicAdd(d_res, d_data[idx]);
        reset_flag(d_counter, d_flag, size);
    }
}

__global__ void mmin(int*          d_data,
                     int*          d_res,
                     volatile int* d_flag,
                     volatile int* d_counter,
                     int           init_value,
                     int           size)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;


    reset_res(d_flag, d_res, init_value);

    if (idx < size) {
        atomicMin(d_res, d_data[idx]);
        reset_flag(d_counter, d_flag, size);
    }
}


__global__ void mmax(int*          d_data,
                     int*          d_res,
                     volatile int* d_flag,
                     volatile int* d_counter,
                     int           init_value,
                     int           size)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;


    reset_res(d_flag, d_res, init_value);

    if (idx < size) {
        atomicMax(d_res, d_data[idx]);
        reset_flag(d_counter, d_flag, size);
    }
}

void verify_sum(thrust::host_vector<int>&   h_vec,
                thrust::device_vector<int>& d_res)
{

    thrust::host_vector<int> h_res = d_res;

    int sum_val = std::accumulate(h_vec.begin(), h_vec.end(), 0);

    printf("\nres= %d, sum_val= %d", h_res[0], sum_val);
    if (sum_val != h_res[0]) {
        printf("verify_sum FAILED!!!!!!");
    }
}

void verify_min(thrust::host_vector<int>&   h_vec,
                thrust::device_vector<int>& d_res)
{

    thrust::host_vector<int> h_res = d_res;

    int min_val = *std::min_element(h_res.begin(), h_res.end());

    printf("\nres= %d, min_val= %d", h_res[0], min_val);
    if (min_val != h_res[0]) {
        printf("verify_min FAILED!!!!!!");
    }
}

void verify_max(thrust::host_vector<int>&   h_vec,
                thrust::device_vector<int>& d_res)
{

    thrust::host_vector<int> h_res = d_res;

    int max_val = *std::max_element(h_res.begin(), h_res.end());


    printf("\nres= %d, max_val= %d", h_res[0], max_val);
    if (max_val != h_res[0]) {
        printf("verify_max FAILED!!!!!!");
    }
}

int main(int argc, char** argv)
{

    int N = 10000;
    if (argc == 2) {
        N = std::atoi(argv[1]);
    }


    // Generate a thrust::host_vector with random integers
    thrust::host_vector<int> h_vec(N);

    std::iota(h_vec.begin(), h_vec.end(), N / 4);
    std::random_device rd;
    std::mt19937       g(rd());
    std::shuffle(h_vec.begin(), h_vec.end(), g);

    // Move data to the GPU
    thrust::device_vector<int> d_vec = h_vec;

    // result, flag -- uninitialized
    thrust::device_vector<int> d_res(1);
    thrust::device_vector<int> d_flag(1);

    // counter initilized to zero
    thrust::device_vector<int> d_counter(1, 0);


    // Sum kernel launch
    const int threads = 512;
    const int blocks  = DIVIDE_UP(N, threads);

    mmax<<<blocks, threads>>>(thrust::raw_pointer_cast(d_vec.data()),
                              thrust::raw_pointer_cast(d_res.data()),
                              thrust::raw_pointer_cast(d_flag.data()),
                              thrust::raw_pointer_cast(d_counter.data()),
                              std::numeric_limits<int>::lowest(),
                              N);
    verify_max(h_vec, d_res);

    sum<<<blocks, threads>>>(thrust::raw_pointer_cast(d_vec.data()),
                             thrust::raw_pointer_cast(d_res.data()),
                             thrust::raw_pointer_cast(d_flag.data()),
                             thrust::raw_pointer_cast(d_counter.data()),
                             0,
                             N);
    verify_sum(h_vec, d_res);


    mmin<<<blocks, threads>>>(thrust::raw_pointer_cast(d_vec.data()),
                              thrust::raw_pointer_cast(d_res.data()),
                              thrust::raw_pointer_cast(d_flag.data()),
                              thrust::raw_pointer_cast(d_counter.data()),
                              std::numeric_limits<int>::max(),
                              N);
    verify_min(h_vec, d_res);


    CUDA_ERROR(cudaDeviceSynchronize());


    return 0;
}
