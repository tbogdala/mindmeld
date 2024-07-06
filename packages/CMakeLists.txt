cmake_minimum_required(VERSION 3.10)

set(BUILD_SHARED_LIBS OFF)
set(GGML_STATIC ON)
set(GGML_OPENMP OFF)
set(GGML_SVE OFF)
set(GGML_VULKAN ON)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

add_subdirectory(./woolydart/src)