cmake_minimum_required(VERSION 3.31)
project(karten)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Boost REQUIRED)
find_package(yaml-cpp REQUIRED)

add_executable(karten)
target_link_libraries(karten
  ${Boost_LIBRARIES}
  ${YAML_CPP_LIBRARIES}
)
target_sources(karten PRIVATE
  src/main.cpp
)
