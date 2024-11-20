cmake_minimum_required(VERSION 3.31)
project(karten)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(karten)
target_sources(karten PRIVATE
  src/main.cpp
)
