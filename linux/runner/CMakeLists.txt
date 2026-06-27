cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

find_package(X11 QUIET)
if(X11_FOUND AND X11_Xss_FOUND)
  add_definitions(-DHAVE_X11_IDLE)
endif()

target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::APPINDICATOR)

if(X11_FOUND AND X11_Xss_FOUND)
  target_link_libraries(${BINARY_NAME} PRIVATE X11::X11 X11::Xss)
endif()

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
