cmake_minimum_required(VERSION 3.10)

set(BUILD_SHARED_LIBS ON)
set(LLAMA_OPENMP OFF)
set(LLAMA_SVE ON)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

add_subdirectory(./woolydart/src/llama.cpp)