cmake_minimum_required(VERSION 3.22)

set(CMAKE_BUILD_TYPE Release)
set(BUILD_SHARED_LIBS OFF)
set(GGML_STATIC ON)
set(GGML_LTO ON)
set(GGML_OPENMP ON)
#set(GGML_VULKAN ON)
set(GGML_BLAS ON)
set(GGML_BLAS_VENDOR "OpenBLAS")

if(ANDROID)
  set(ANDROID_ABI "arm64-v8a")
  set(ANDROID_PLATFORM "android-34")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -march=armv8.4a+dotprod")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=armv8.4a+dotprod")
endif()

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

add_subdirectory(./woolydart/src/woolycore)