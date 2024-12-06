#CMake minimum requirement 
cmake_minimum_required(VERSION 3.19 FATAL_ERROR)

set(exec_name "reduction")


#Executable
add_executable(${exec_name} helper.h main.cu)

#Libs linked to the executable
target_link_libraries( ${exec_name}   	
	$<BUILD_INTERFACE:developer_flags>	
)

#gtest_discover_tests(${exec_name})
