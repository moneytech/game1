cmake_minimum_required(VERSION 2.6)
project(renderer)
find_package (Threads)
find_package (OpenGL REQUIRED)

#include_directories()

if (WIN32)
    add_definitions(/GR-)
	set (EDITOR_SRCS
	    src/main.cpp
        src/renderer_gl.cpp
        src/obj_reader.cpp
	    src/os_windows.cpp
        src/stb_image.cpp
        src/html_parser.cpp
	)
else()
	add_definitions(--std=c++1y -g -fno-rtti)

	set (EDITOR_SRCS
	    src/main.cpp
        src/renderer_gl.cpp
        src/obj_reader.cpp
	    src/os_linux.cpp
        src/stb_image.cpp
	)
endif()

add_executable(renderer ${EDITOR_SRCS})

# ${X11_LIBRARIES}
target_link_libraries(renderer ${OPENGL_gl_LIBRARY} ${CMAKE_THREAD_LIBS_INIT})

add_custom_command(TARGET renderer POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -E copy_directory
                       ${CMAKE_SOURCE_DIR}/assets $<TARGET_FILE_DIR:renderer>/assets)
