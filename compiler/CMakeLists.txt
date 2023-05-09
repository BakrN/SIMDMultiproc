cmake_minimum_required(VERSION 3.10)

project(fast_mmul)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
# Add source files to a library
file(GLOB SOURCES "src/*.cpp")
add_library(compiler SHARED ${SOURCES})

# Add include directories for library and test executables
target_include_directories(compiler PUBLIC ${PROJECT_SOURCE_DIR}/src)
include_directories(${PROJECT_SOURCE_DIR}/src)
 
# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# Add test executables
file(GLOB TEST_SOURCES "test/*.cpp")
foreach(TEST_SOURCE ${TEST_SOURCES})
    get_filename_component(TEST_NAME ${TEST_SOURCE} NAME_WE)
    add_executable(${TEST_NAME} ${TEST_SOURCE})
    target_link_libraries(${TEST_NAME} compiler)
    set_target_properties(${TEST_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/test"
    )
endforeach()


