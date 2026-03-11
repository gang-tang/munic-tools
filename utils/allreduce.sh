#!/bin/bash
export NCCL_IB_HCA="mlx5_${OMPI_COMM_WORLD_LOCAL_RANK}"
#export CUDA_VISIBLE_DEVICES="${OMPI_COMM_WORLD_LOCAL_RANK}"
/home/munic/nccl-tests/build/all_reduce_perf -n 1 -g 1 -b 6G  -e 6G
#/home/munic/nccl-tests/build/alltoall_perf -n 5  -g 1 -b 4G -e 4G
