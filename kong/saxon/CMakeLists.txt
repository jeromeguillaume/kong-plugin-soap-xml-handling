cmake_minimum_required(VERSION 3.27)
project(libsaxon-4-kong-prj)

set(CMAKE_CXX_STANDARD 14)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

set(SaxonCHE_DIR ../SaxonCHE/lib/cmake/SaxonCHE)
find_package(SaxonCHE 12.8.0 EXACT REQUIRED)

add_library(libsaxon-4-kong SHARED src/kong-adapter.cpp)
target_link_libraries(libsaxon-4-kong PRIVATE SaxonCHE::saxonc-he)
set_target_properties(libsaxon-4-kong PROPERTIES PREFIX "")
