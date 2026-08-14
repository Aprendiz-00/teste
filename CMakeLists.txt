cmake_minimum_required(VERSION 3.24)

project(WydModernization
    VERSION 0.1.0
    DESCRIPTION "Modernization foundation for the New World/WYD server"
    LANGUAGES CXX
)

option(WYD_BUILD_MODERN_TESTS "Build tests for the modernized components" ON)

add_library(wyd_modern_foundation INTERFACE)

target_include_directories(wyd_modern_foundation
    INTERFACE
        ${CMAKE_CURRENT_SOURCE_DIR}/Source/Modern
)

target_compile_features(wyd_modern_foundation INTERFACE cxx_std_20)

if(MSVC)
    target_compile_options(wyd_modern_foundation INTERFACE /W4 /permissive-)
else()
    target_compile_options(wyd_modern_foundation INTERFACE -Wall -Wextra -Wpedantic)
endif()

if(WYD_BUILD_MODERN_TESTS)
    enable_testing()

    add_executable(modern_foundation_tests
        tests/foundation/BuildSanityTests.cpp
    )

    target_link_libraries(modern_foundation_tests
        PRIVATE wyd_modern_foundation
    )

    add_test(
        NAME modern_foundation_sanity
        COMMAND modern_foundation_tests
    )

    add_executable(database_config_tests
        tests/persistence/DatabaseConfigTests.cpp
    )

    target_link_libraries(database_config_tests
        PRIVATE wyd_modern_foundation
    )

    add_test(
        NAME database_configuration
        COMMAND database_config_tests
    )
endif()

message(STATUS "Legacy TMSrv/DBSrv remain on the Visual Studio solution during the migration.")
message(STATUS "This CMake project intentionally builds only modernized, dependency-isolated components for now.")
