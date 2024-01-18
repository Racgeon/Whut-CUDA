cmake_minimum_required(VERSION 3.26)
project(cuda_work CUDA)

set(CMAKE_CUDA_STANDARD 11)

add_executable(cuda_work
        gpu.cu
        cpu.cu
)

set_target_properties(cuda_work PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
