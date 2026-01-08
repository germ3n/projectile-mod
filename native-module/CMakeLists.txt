cmake_minimum_required(VERSION 3.10)
project(projectile-native-module LANGUAGES CXX)

set(CMAKE_CONFIGURATION_TYPES Release Debug)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_subdirectory(gmod-headers/include)

add_library(projectile_native SHARED)
target_sources(projectile_native PRIVATE module.cpp)
target_link_libraries(projectile_native gmod-module-base)
set_gmod_suffix_prefix(projectile_native)
