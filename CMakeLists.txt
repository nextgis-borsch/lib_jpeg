################################################################################
# Project:  Lib JPEG
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2015, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

cmake_minimum_required(VERSION 2.8.10 FATAL_ERROR)

project(jpeg C)

# some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/bin" CACHE INTERNAL "Installation directory for executables" FORCE)
set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib" CACHE INTERNAL "Installation directory for libraries" FORCE)
set(INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE INTERNAL "Installation directory for headers" FORCE)

option(BMP_SUPPORTED "BMP image file format" ON)
option(GIF_SUPPORTED "GIF image file format" ON)
option(PPM_SUPPORTED "PBMPLUS PPM/PGM image file format" ON)
option(RLE_SUPPORTED "Utah RLE image file format" ON)
option(TARGA_SUPPORTED "Targa image file format" ON)

include(CheckTypeSize)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckCSourceCompiles)

check_include_file ( stddef.h HAVE_STDDEF_H )
check_include_file ( stdlib.h HAVE_STDLIB_H )
check_include_file ( string.h HAVE_STRING_H )

if(NOT HAVE_STRING_H)
    check_include_file ( strings.h HAVE_STRINGS_H )
    if(HAVE_STRINGS_H)
        set(NEED_BSD_STRINGS TRUE)
    endif()    
endif()

if ( WIN32 AND NOT CYGWIN )
  set (TWO_FILE_COMMANDLINE TRUE)
endif ( )

configure_file(${CMAKE_MODULE_PATH}/jconfig.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/jconfig.h )
configure_file(${CMAKE_MODULE_PATH}/cmake_uninstall.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)

include_directories ( ${CMAKE_CURRENT_BINARY_DIR} )

if(NOT BUILD_JPEG_8 AND NOT BUILD_JPEG_12)
    set(BUILD_JPEG_8 TRUE)
endif()

if(BUILD_JPEG_8) 
    configure_file(${CMAKE_MODULE_PATH}/jmorecfg.h.8 ${CMAKE_CURRENT_BINARY_DIR}/jmorecfg.h )
endif()    

if(BUILD_JPEG_12 AND NOT BUILD_JPEG_8) 
    configure_file(${CMAKE_MODULE_PATH}/jmorecfg.h.12 ${CMAKE_CURRENT_BINARY_DIR}/jmorecfg.h )
endif()   

set(JPEG_PUBLIC_HDRS
    ${CMAKE_CURRENT_BINARY_DIR}/jconfig.h
    jpeglib.h
    ${CMAKE_CURRENT_BINARY_DIR}/jmorecfg.h
)

set(JPEG_PRIVATE_HDRS
    jerror.h 
    cderror.h
    cdjpeg.h 
    jdct.h
    jinclude.h 
    jmemsys.h 
    jpegint.h 
    jversion.h 
    transupp.h
)

set(JPEG_SRCS
    jmemnobs.c 
    jaricom.c 
    jcapimin.c 
    jcapistd.c 
    jcarith.c 
    jccoefct.c
    jccolor.c
    jcdctmgr.c 
    jchuff.c 
    jcinit.c 
    jcmainct.c 
    jcmarker.c 
    jcmaster.c 
    jcomapi.c 
    jcparam.c
    jcprepct.c
    jcsample.c 
    jctrans.c
    jdapimin.c 
    jdapistd.c
    jdarith.c
    jdatadst.c
    jdatasrc.c
    jdcoefct.c 
    jdcolor.c 
    jddctmgr.c
    jdhuff.c
    jdinput.c 
    jdmainct.c 
    jdmarker.c 
    jdmaster.c
    jdmerge.c 
    jdpostct.c 
    jdsample.c 
    jdtrans.c 
    jerror.c 
    jfdctflt.c 
    jfdctfst.c 
    jfdctint.c
    jidctflt.c 
    jidctfst.c 
    jidctint.c
    jquant1.c 
    jquant2.c 
    jutils.c 
    jmemmgr.c
)


# parse the full version number from jpeglib.h and include in JPEG_FULL_VERSION
include(util)
set(JPEG_VERSION_MAJOR)
set(JPEG_VERSION_MINOR)
check_version(JPEG_VERSION_MAJOR JPEG_VERSION_MINOR)
set(VERSION "${JPEG_VERSION_MAJOR}.${JPEG_VERSION_MINOR}")

if(BUILD_JPEG_8)
    set(VERSION_FULL "${VERSION} [8-bit]")
elseif(BUILD_JPEG_12)
    set(VERSION_FULL "${VERSION} [12-bit]")
endif()
report_version(${PROJECT_NAME} ${VERSION_FULL})
 
if(BUILD_SHARED_LIBS)
    set(LIB_NAME jpeg)
    add_library(${LIB_NAME} SHARED ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS} ${JPEG_PRIVATE_HDRS})
    set_target_properties(${LIB_NAME} PROPERTIES DEFINE_SYMBOL JPEG_DLL)
    set_target_properties(${LIB_NAME} PROPERTIES SOVERSION 1)
else()    
    set(LIB_NAME jpegstatic)
    add_library(${LIB_NAME} STATIC ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS} ${JPEG_PRIVATE_HDRS})
    set_target_properties(${LIB_NAME} PROPERTIES SOVERSION 1)
endif()    

export(TARGETS ${LIB_NAME} FILE ${LIB_NAME}-exports.cmake)
add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

if(NOT CYGWIN)
    set_target_properties(${LIB_NAME} PROPERTIES VERSION ${VERSION})
endif()

if(UNIX)
    # On unix-like platforms the library is almost always called libjpeg
    if(BUILD_JPEG_12 AND NOT BUILD_JPEG_8) 
        set_target_properties(${LIB_NAME} PROPERTIES OUTPUT_NAME jpeg12)
    elseif(BUILD_JPEG_8)
        set_target_properties(${LIB_NAME} PROPERTIES OUTPUT_NAME jpeg)
    endif()
    if(NOT APPLE AND BUILD_SHARED_LIBS)
        set_target_properties(${LIB_NAME} PROPERTIES LINK_FLAGS "-Wl,--version-script,\"${CMAKE_CURRENT_SOURCE_DIR}/libjpeg.map\"")
    endif()
elseif(BUILD_SHARED_LIBS AND WIN32)
    if(BUILD_JPEG_12 AND NOT BUILD_JPEG_8) 
        set_target_properties(${LIB_NAME} PROPERTIES SUFFIX "12_${JPEG_VERSION_MAJOR}${JPEG_VERSION_MINOR}.dll")
    elseif(BUILD_JPEG_8)
        set_target_properties(${LIB_NAME} PROPERTIES SUFFIX "${JPEG_VERSION_MAJOR}${JPEG_VERSION_MINOR}.dll")
    endif()
endif()

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL )
    install(TARGETS ${LIB_NAME} 
        RUNTIME DESTINATION "${INSTALL_BIN_DIR}"
        ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
        LIBRARY DESTINATION "${INSTALL_LIB_DIR}" )
endif()
if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL )
    install(FILES ${JPEG_PUBLIC_HDRS} DESTINATION "${INSTALL_INC_DIR}")
endif()

