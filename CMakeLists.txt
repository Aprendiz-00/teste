cmake_minimum_required(VERSION 3.24)

project(WydModernization
    VERSION 0.1.0
    DESCRIPTION "Modernization foundation for the New World/WYD server"
    LANGUAGES CXX
)

option(WYD_BUILD_MODERN_TESTS "Build tests for the modernized components" ON)

add_library(wyd_protocol_legacy INTERFACE)

target_include_directories(wyd_protocol_legacy
    INTERFACE
        ${CMAKE_CURRENT_SOURCE_DIR}/Source/Modern
)

target_compile_features(wyd_protocol_legacy INTERFACE cxx_std_20)

if(MSVC)
    target_compile_options(wyd_protocol_legacy INTERFACE /W4 /permissive-)
else()
    target_compile_options(wyd_protocol_legacy INTERFACE -Wall -Wextra -Wpedantic)
endif()

if(WYD_BUILD_MODERN_TESTS)
    enable_testing()

    add_executable(legacy_protocol_layout_tests
        tests/protocol/LegacyProtocolLayoutTests.cpp
    )

    target_link_libraries(legacy_protocol_layout_tests
        PRIVATE wyd_protocol_legacy
    )

    add_test(
        NAME legacy_protocol_layout
        COMMAND legacy_protocol_layout_tests
    )
endif()

message(STATUS "Legacy TMSrv/DBSrv remain on the Visual Studio solution during the migration.")
message(STATUS "This CMake project intentionally builds only modernized, dependency-isolated components for now.")
