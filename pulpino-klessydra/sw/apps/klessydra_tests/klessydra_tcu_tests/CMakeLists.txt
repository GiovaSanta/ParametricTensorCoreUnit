include_directories(
  ${CMAKE_SOURCE_DIR}/libs/bench_lib/inc
  ${CMAKE_SOURCE_DIR}/libs/stdio_lib/inc
  ${CMAKE_SOURCE_DIR}/libs/string_lib/inc
  ${CMAKE_SOURCE_DIR}/libs/sys_lib/inc
  .
)

add_subdirectory(TCUopFP16)
add_subdirectory(TCUopPOSIT16)
add_subdirectory(TCUopFP8)
add_subdirectory(TCUopPOSIT8)
add_subdirectory(TCUopINT8_16)
add_subdirectory(TCUopFIXED8_16)
add_subdirectory(TCUopFP32)
add_subdirectory(TCUopPOSIT32)