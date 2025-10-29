cmake_minimum_required(VERSION 3.10)
project(unitree_legged_sdk VERSION 0.0.0 LANGUAGES C CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
add_compile_options(-O3 -fPIC)

find_package(Threads REQUIRED)

set(UNITREE_SDK_ARCH "" CACHE STRING "Prebuilt Unitree SDK architecture directory (amd64 or arm64)")

if(NOT UNITREE_SDK_ARCH)
  message(STATUS "Detecting architecture from CMAKE_SYSTEM_PROCESSOR='${CMAKE_SYSTEM_PROCESSOR}'")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64)")
    set(UNITREE_SDK_ARCH "amd64" CACHE STRING "Prebuilt Unitree SDK architecture directory (amd64 or arm64)" FORCE)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
    set(UNITREE_SDK_ARCH "arm64" CACHE STRING "Prebuilt Unitree SDK architecture directory (amd64 or arm64)" FORCE)
  else()
    message(FATAL_ERROR "Unsupported architecture '${CMAKE_SYSTEM_PROCESSOR}'. Please set UNITREE_SDK_ARCH explicitly to either 'amd64' or 'arm64'.")
  endif()
endif()

set(_unitree_sdk_lib "${CMAKE_CURRENT_SOURCE_DIR}/lib/cpp/${UNITREE_SDK_ARCH}/libunitree_legged_sdk.a")
if(NOT EXISTS "${_unitree_sdk_lib}")
  message(FATAL_ERROR "Prebuilt library not found for architecture '${UNITREE_SDK_ARCH}' at '${_unitree_sdk_lib}'.")
endif()

add_library(unitree_legged_sdk INTERFACE)
add_library(unitree_legged_sdk::unitree_legged_sdk ALIAS unitree_legged_sdk)

target_include_directories(unitree_legged_sdk
  INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_link_libraries(unitree_legged_sdk
  INTERFACE
    Threads::Threads
    $<BUILD_INTERFACE:${_unitree_sdk_lib}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_LIBDIR}/libunitree_legged_sdk.a>
    $<$<AND:$<PLATFORM_ID:Linux>,$<OR:$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>>:-no-pie>
)

option(PYTHON_BUILD "Build python wrapper" OFF)
if(PYTHON_BUILD)
  add_subdirectory(python_wrapper)
endif()

option(BUILD_EXAMPLES "Build C++ example applications" ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

if(BUILD_EXAMPLES)
  add_executable(example_position example/example_position.cpp)
  target_link_libraries(example_position PRIVATE unitree_legged_sdk::unitree_legged_sdk)

  add_executable(example_velocity example/example_velocity.cpp)
  target_link_libraries(example_velocity PRIVATE unitree_legged_sdk::unitree_legged_sdk)

  add_executable(example_torque example/example_torque.cpp)
  target_link_libraries(example_torque PRIVATE unitree_legged_sdk::unitree_legged_sdk)

  add_executable(example_walk example/example_walk.cpp)
  target_link_libraries(example_walk PRIVATE unitree_legged_sdk::unitree_legged_sdk)

  add_executable(example_joystick example/example_joystick.cpp)
  target_link_libraries(example_joystick PRIVATE unitree_legged_sdk::unitree_legged_sdk)
endif()

find_package(catkin QUIET)
if(catkin_FOUND)
  catkin_package(
    INCLUDE_DIRS include
    LIBRARIES ${PROJECT_SOURCE_DIR}/lib/cpp/${UNITREE_SDK_ARCH}/libunitree_legged_sdk.a
  )
endif()

# Install headers and static library
install(TARGETS unitree_legged_sdk
  EXPORT unitree_legged_sdkTargets
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(FILES ${_unitree_sdk_lib}
  DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

if(BUILD_EXAMPLES)
  install(TARGETS
    example_position example_velocity example_torque example_walk example_joystick
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/unitree
  )
endif()

set(_unitree_config_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/unitree_legged_sdk")

install(EXPORT unitree_legged_sdkTargets
  NAMESPACE unitree_legged_sdk::
  DESTINATION ${_unitree_config_install_dir}
)

configure_package_config_file(
  cmake/unitree_legged_sdkConfig.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/unitree_legged_sdkConfig.cmake"
  INSTALL_DESTINATION ${_unitree_config_install_dir}
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/unitree_legged_sdkConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/unitree_legged_sdkConfig.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/unitree_legged_sdkConfigVersion.cmake"
  DESTINATION ${_unitree_config_install_dir}
)
