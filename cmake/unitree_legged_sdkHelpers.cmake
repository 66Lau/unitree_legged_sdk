function(unitree_legged_sdk_disable_pie target)
  if(NOT TARGET "${target}")
    message(FATAL_ERROR "unitree_legged_sdk_disable_pie: '${target}' is not a valid target.")
  endif()

  if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND
     (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
      CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
    target_compile_options(${target} PRIVATE -fno-pie)
    set_target_properties(${target} PROPERTIES POSITION_INDEPENDENT_CODE OFF)

    if(CMAKE_VERSION VERSION_LESS "3.13")
      set_property(TARGET ${target} APPEND PROPERTY LINK_FLAGS " -no-pie")
    else()
      target_link_options(${target} PRIVATE -no-pie)
    endif()
  endif()
endfunction()
