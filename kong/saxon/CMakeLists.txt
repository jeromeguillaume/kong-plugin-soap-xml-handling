cmake_minimum_required(VERSION 3.27)
project(saxonc_samples)

set(CMAKE_CXX_STANDARD 14)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

list(APPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")

find_package(SaxonCHE 12.10.0 EXACT REQUIRED)

add_library(libsaxon-4-kong SHARED src/kong-adapter.cpp)
target_link_libraries(libsaxon-4-kong PRIVATE SaxonCHE::saxonc-he)
set_target_properties(libsaxon-4-kong PROPERTIES PREFIX "")