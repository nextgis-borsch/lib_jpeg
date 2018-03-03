################################################################################
# Project:  Lib JPEG
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2015-2018, NextGIS <info@nextgis.com>
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

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(jpeg)

if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()

# some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
    set(INSTALL_BIN_DIR "bin" CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR "Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_CMAKECONF_DIR_8 ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Resources/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
    set(INSTALL_CMAKECONF_DIR_12 ${INSTALL_LIB_DIR}/${PROJECT_NAME}12.framework/Resources/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
    set(INSTALL_INC_DIR_12 ${INSTALL_LIB_DIR}/${PROJECT_NAME}12.framework/Headers CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_INC_DIR_8 ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers CACHE INTERNAL "Installation directory for headers" FORCE)

    set(SKIP_INSTALL_HEADERS ON)
    set(SKIP_INSTALL_EXECUTABLES ON)
    set(SKIP_INSTALL_FILES ON)
    set(SKIP_INSTALL_EXPORT ON)
    set(CMAKE_MACOSX_RPATH ON)
else()
    include(GNUInstallDirs)

    set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR_12 ${CMAKE_INSTALL_INCLUDEDIR}/jpeg12 CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_INC_DIR_8 ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_CMAKECONF_DIR_8 ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
    set(INSTALL_CMAKECONF_DIR_12 ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}12/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
    set(INSTALL_MAN_DIR ${CMAKE_INSTALL_MANDIR} CACHE INTERNAL "Installation directory for manual pages" FORCE)
    set(INSTALL_DOC_DIR ${CMAKE_INSTALL_DOCDIR} CACHE INTERNAL "Installation directory for doc pages" FORCE)
endif()

if(CMAKE_GENERATOR_TOOLSET MATCHES "v([0-9]+)_xp")
    add_definitions(-D_WIN32_WINNT=0x0501)
endif()

option(BMP_SUPPORTED "BMP image file format" ON)
option(GIF_SUPPORTED "GIF image file format" ON)
option(PPM_SUPPORTED "PBMPLUS PPM/PGM image file format" ON)
option(RLE_SUPPORTED "Utah RLE image file format" OFF)
option(TARGA_SUPPORTED "Targa image file format" ON)

include(CheckTypeSize)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckCSourceCompiles)

check_include_file ( stddef.h HAVE_STDDEF_H )
check_include_file ( stdlib.h HAVE_STDLIB_H )
check_include_file ( string.h HAVE_STRING_H )
check_function_exists(tmpfile HAVE_TMPFILE)
check_function_exists(mktemp HAVE_MKTEMP)

if(NOT HAVE_STRING_H)
    check_include_file ( strings.h HAVE_STRINGS_H )
    if(HAVE_STRINGS_H)
        set(NEED_BSD_STRINGS TRUE)
    endif()
endif()

if( WIN32 AND NOT CYGWIN )
  set (TWO_FILE_COMMANDLINE TRUE)
endif()

set(MEMORYMGR jmemnobs.c)
if(ENABLE_MAXMEM AND ENABLE_MAXMEM GREATER 0)
    math(EXPR DEFAULT_MAX_MEM "${ENABLE_MAXMEM} * 1048576")
    if(HAVE_TMPFILE)
        set(MEMORYMGR jmemansi.c)
    elseif(HAVE_MKTEMP)
        set(MEMORYMGR jmemname.c)
        set(NEED_SIGNAL_CATCHER ON)
    else()
        set(NO_MKTEMP ON)
    endif()
endif()

configure_file(${PROJECT_SOURCE_DIR}/cmake/jconfig.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/jconfig.h )
configure_file(${PROJECT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)

include_directories ( ${CMAKE_CURRENT_BINARY_DIR} )

if(NOT BUILD_JPEG_8 AND NOT BUILD_JPEG_12)
    set(BUILD_JPEG_8 TRUE)
endif()

configure_file(${PROJECT_SOURCE_DIR}/cmake/jmorecfg.h.8 ${CMAKE_CURRENT_BINARY_DIR}/8/jmorecfg.h )
configure_file(${PROJECT_SOURCE_DIR}/cmake/jmorecfg.h.12 ${CMAKE_CURRENT_BINARY_DIR}/12/jmorecfg.h )

if(EXISTS ${PROJECT_SOURCE_DIR}/jmorecfg.h)
    file(RENAME ${PROJECT_SOURCE_DIR}/jmorecfg.h ${PROJECT_SOURCE_DIR}/jmorecfg.skip)
endif()

set(JPEG_PUBLIC_HDRS
    ${CMAKE_CURRENT_BINARY_DIR}/jconfig.h
    jpeglib.h
    jerror.h
)

set(JPEG_PUBLIC_HDRS_8 ${JPEG_PUBLIC_HDRS}
    ${CMAKE_CURRENT_BINARY_DIR}/8/jmorecfg.h
)

set(JPEG_PUBLIC_HDRS_12 ${JPEG_PUBLIC_HDRS}
    ${CMAKE_CURRENT_BINARY_DIR}/12/jmorecfg.h
)

set(JPEG_PRIVATE_HDRS
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
    jaricom.c jcapimin.c jcapistd.c jcarith.c jccoefct.c jccolor.c
    jcdctmgr.c jchuff.c jcinit.c jcmainct.c jcmarker.c jcmaster.c
    jcomapi.c jcparam.c jcprepct.c jcsample.c jctrans.c jdapimin.c
    jdapistd.c jdarith.c jdatadst.c jdatasrc.c jdcoefct.c jdcolor.c
    jddctmgr.c jdhuff.c jdinput.c jdmainct.c jdmarker.c jdmaster.c
    jdmerge.c jdpostct.c jdsample.c jdtrans.c jerror.c jfdctflt.c
    jfdctfst.c jfdctint.c jidctflt.c jidctfst.c jidctint.c jquant1.c
    jquant2.c jutils.c jmemmgr.c ${MEMORYMGR}
)


# parse the full version number from jpeglib.h and include in JPEG_FULL_VERSION
include(util)
check_version(JPEG_VERSION_MAJOR JPEG_VERSION_MINOR)
set(VERSION "${JPEG_VERSION_MAJOR}.${JPEG_VERSION_MINOR}")

if(OSX_FRAMEWORK)
    set(FRAMEWORK_VERSION "${JPEG_VERSION_MAJOR}")
endif()

report_version(${PROJECT_NAME} ${VERSION})

set(LIB_NAME ${PROJECT_NAME})

if(BUILD_SHARED_LIBS)
    if(BUILD_JPEG_8)
        add_library(${LIB_NAME} SHARED ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS_8} ${JPEG_PRIVATE_HDRS})
        set_target_properties(${LIB_NAME} PROPERTIES
            VERSION ${VERSION}
            SOVERSION ${JPEG_VERSION_MAJOR}
            DEFINE_SYMBOL JPEG_DLL_EXPORTS)
    endif()
    if(BUILD_JPEG_12)
        add_library(${LIB_NAME}12 SHARED ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS_12} ${JPEG_PRIVATE_HDRS})
        set_target_properties(${LIB_NAME}12 PROPERTIES
            VERSION ${VERSION}
            SOVERSION ${JPEG_VERSION_MAJOR}
            DEFINE_SYMBOL JPEG_DLL_EXPORTS)
    endif()
elseif(OSX_FRAMEWORK)
    if(BUILD_JPEG_8)
        add_library(${LIB_NAME} SHARED ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS_8} ${JPEG_PRIVATE_HDRS})
        set_target_properties(${LIB_NAME} PROPERTIES
            FRAMEWORK TRUE
            FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
            MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
            MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
            MACOSX_FRAMEWORK_IDENTIFIER org.libjpeg.libjpeg
            XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
            VERSION ${VERSION}
            SOVERSION ${JPEG_VERSION_MAJOR}
            PUBLIC_HEADER "${JPEG_PUBLIC_HDRS_8}")
    endif()
    if(BUILD_JPEG_12)
        add_library(${LIB_NAME}12 SHARED ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS_12} ${JPEG_PRIVATE_HDRS})
        set_target_properties(${LIB_NAME}12 PROPERTIES
            FRAMEWORK TRUE
            FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
            MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
            MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
            MACOSX_FRAMEWORK_IDENTIFIER org.libjpeg.libjpeg12
            XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
            VERSION ${VERSION}
            SOVERSION ${JPEG_VERSION_MAJOR}
            PUBLIC_HEADER "${JPEG_PUBLIC_HDRS_12}")
    endif()
else()
    if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
        set( CMAKE_CXX_FLAGS "-fpic ${CMAKE_CXX_FLAGS}" )
        set( CMAKE_C_FLAGS   "-fpic ${CMAKE_C_FLAGS}" )
    endif()
    add_definitions(-DJPEG_STATIC)
    if(BUILD_JPEG_8)
        add_library(${LIB_NAME} STATIC ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS_8} ${JPEG_PRIVATE_HDRS})
    endif()
    if(BUILD_JPEG_12)
        add_library(${LIB_NAME}12 STATIC ${JPEG_SRCS} ${JPEG_PUBLIC_HDRS_12} ${JPEG_PRIVATE_HDRS})
    endif()
endif()

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

if(UNIX)
    # On unix-like platforms the library is almost always called libjpeg
    if(NOT APPLE AND BUILD_SHARED_LIBS)
        if(TARGET ${LIB_NAME})
            set_target_properties(${LIB_NAME} PROPERTIES LINK_FLAGS "-Wl,--version-script,\"${CMAKE_CURRENT_SOURCE_DIR}/libjpeg.map\"")
        endif()
        if(TARGET ${LIB_NAME}12)
            set_target_properties(${LIB_NAME}12 PROPERTIES LINK_FLAGS "-Wl,--version-script,\"${CMAKE_CURRENT_SOURCE_DIR}/libjpeg.map\"")
        endif()
    endif()
elseif(BUILD_SHARED_LIBS AND WIN32)
    if(TARGET ${LIB_NAME})
        set_target_properties(${LIB_NAME} PROPERTIES SUFFIX "${JPEG_VERSION_MAJOR}${JPEG_VERSION_MINOR}.dll")
    endif()
    if(TARGET ${LIB_NAME}12)
        set_target_properties(${LIB_NAME}12 PROPERTIES SUFFIX "_${JPEG_VERSION_MAJOR}${JPEG_VERSION_MINOR}.dll")
    endif()
endif()

set(PACKAGE_NAME ${PROJECT_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)
set(INSTALL_TARGETS)
if(BUILD_JPEG_8)
    set(INSTALL_TARGETS ${INSTALL_TARGETS} ${LIB_NAME})
endif()
if(BUILD_JPEG_12)
    set(INSTALL_TARGETS ${INSTALL_TARGETS} ${LIB_NAME}12)
endif()

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL )
    if(BUILD_JPEG_8)
        install(TARGETS ${LIB_NAME}
            EXPORT ${PACKAGE_UPPER_NAME}Targets
            RUNTIME DESTINATION ${INSTALL_BIN_DIR}
            LIBRARY DESTINATION ${INSTALL_LIB_DIR}
            ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
            INCLUDES DESTINATION ${INSTALL_INC_DIR_8}
            FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})
    endif()
    if(BUILD_JPEG_12)
        install(TARGETS ${LIB_NAME}12
            EXPORT ${PACKAGE_UPPER_NAME}12Targets
            RUNTIME DESTINATION ${INSTALL_BIN_DIR}
            LIBRARY DESTINATION ${INSTALL_LIB_DIR}
            ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
            INCLUDES DESTINATION ${INSTALL_INC_DIR_12}
            FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})
    endif()
endif()

if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL )
    if(BUILD_JPEG_8)
        install(FILES ${JPEG_PUBLIC_HDRS_8} DESTINATION "${INSTALL_INC_DIR_8}")
    endif()
    if(BUILD_JPEG_12)
        install(FILES ${JPEG_PUBLIC_HDRS_12} DESTINATION "${INSTALL_INC_DIR_12}")
    endif()
endif()

set(DISTMANS cjpeg.1 djpeg.1 jpegtran.1 rdjpgcom.1 wrjpgcom.1)
set(DOCS README example.c change.log)
if(NOT SKIP_INSTALL_DOCS AND NOT SKIP_INSTALL_ALL)
    if(NOT OSX_FRAMEWORK)
        install(FILES ${DISTMANS} DESTINATION "${INSTALL_MAN_DIR}")
        install(FILES ${DOCS} DESTINATION "${INSTALL_DOC_DIR}")
    endif()
endif()

# Executables to build
set(cjpeg_SOURCES cjpeg.c rdppm.c rdgif.c rdtarga.c rdrle.c rdbmp.c
    rdswitch.c cdjpeg.c
)
add_executable(cjpeg ${cjpeg_SOURCES})
target_link_libraries(cjpeg ${LIB_NAME})

set(djpeg_SOURCES djpeg.c wrppm.c wrgif.c wrtarga.c wrrle.c wrbmp.c
    rdcolmap.c cdjpeg.c
)
add_executable(djpeg ${djpeg_SOURCES})
target_link_libraries(djpeg ${LIB_NAME})

set(jpegtran_SOURCES jpegtran.c rdswitch.c cdjpeg.c transupp.c)
add_executable(jpegtran ${jpegtran_SOURCES})
target_link_libraries(jpegtran ${LIB_NAME})

set(rdjpgcom_SOURCES rdjpgcom.c)
add_executable(rdjpgcom ${rdjpgcom_SOURCES})
target_link_libraries(rdjpgcom ${LIB_NAME})

set(wrjpgcom_SOURCES wrjpgcom.c)
add_executable(wrjpgcom ${wrjpgcom_SOURCES})
target_link_libraries(wrjpgcom ${LIB_NAME})

install(TARGETS cjpeg djpeg jpegtran rdjpgcom wrjpgcom
    RUNTIME DESTINATION ${INSTALL_BIN_DIR}
    LIBRARY DESTINATION ${INSTALL_LIB_DIR}
    ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
    INCLUDES DESTINATION ${INSTALL_INC_DIR_12}
    FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})

# Tests

enable_testing()
if(BUILD_TESTING)
    # ./djpeg -dct int -ppm -outfile testout.ppm  $(srcdir)/testorig.jpg
    add_test(NAME djpeg1
             COMMAND ${CMAKE_COMMAND}
             -DTEST_APP=$<TARGET_FILE:djpeg>
             -DTEST_ARG1=-dct
             -DTEST_ARG2=int
             -DTEST_ARG3=-ppm
             -DTEST_ARG4=-outfile
             -DTEST_ARG5=${CMAKE_CURRENT_BINARY_DIR}/testout.ppm
             -DTEST_ARG6=${CMAKE_CURRENT_SOURCE_DIR}/testorig.jpg
             -DTEST_NAME=djpeg1
             -DTEST_COMPARE1=${CMAKE_CURRENT_SOURCE_DIR}/testimg.ppm
             -DTEST_COMPARE2=${CMAKE_CURRENT_BINARY_DIR}/testout.ppm
             -P ${CMAKE_SOURCE_DIR}/cmake/TestCompareFiles.cmake)

    if(UNIX) # Skin on Windows as it failed
    # ./djpeg -dct int -bmp -colors 256 -outfile testout.bmp  $(srcdir)/testorig.jpg
    add_test(NAME djpeg2
        COMMAND ${CMAKE_COMMAND}
            -DTEST_APP=$<TARGET_FILE:djpeg>
            -DTEST_ARG1=-dct
            -DTEST_ARG2=int
            -DTEST_ARG3=-bmp
            -DTEST_ARG4=-colors
            -DTEST_ARG5=256
            -DTEST_ARG6=-outfile
            -DTEST_ARG7=${CMAKE_CURRENT_BINARY_DIR}/testout.bmp
            -DTEST_ARG8=${CMAKE_CURRENT_SOURCE_DIR}/testorig.jpg
            -DTEST_NAME=djpeg1
            -DTEST_COMPARE1=${CMAKE_CURRENT_SOURCE_DIR}/testimg.bmp
            -DTEST_COMPARE2=${CMAKE_CURRENT_BINARY_DIR}/testout.bmp
            -P ${CMAKE_SOURCE_DIR}/cmake/TestCompareFiles.cmake)
    endif()
    # ./cjpeg -dct int -outfile testout.jpg  $(srcdir)/testimg.ppm
    add_test(NAME cjpeg1
        COMMAND ${CMAKE_COMMAND}
            -DTEST_APP=$<TARGET_FILE:cjpeg>
            -DTEST_ARG1=-dct
            -DTEST_ARG2=int
            -DTEST_ARG3=-outfile
            -DTEST_ARG4=${CMAKE_CURRENT_BINARY_DIR}/testout.jpg
            -DTEST_ARG5=${CMAKE_CURRENT_SOURCE_DIR}/testimg.ppm
            -DTEST_NAME=cjpeg1
            -DTEST_COMPARE1=${CMAKE_CURRENT_SOURCE_DIR}/testimg.jpg
            -DTEST_COMPARE2=${CMAKE_CURRENT_BINARY_DIR}/testout.jpg
            -P ${CMAKE_SOURCE_DIR}/cmake/TestCompareFiles.cmake)

    # ./djpeg -dct int -ppm -outfile testoutp.ppm $(srcdir)/testprog.jpg
    add_test(NAME djpeg3
        COMMAND ${CMAKE_COMMAND}
            -DTEST_APP=$<TARGET_FILE:djpeg>
            -DTEST_ARG1=-dct
            -DTEST_ARG2=int
            -DTEST_ARG3=-ppm
            -DTEST_ARG4=-outfile
            -DTEST_ARG5=${CMAKE_CURRENT_BINARY_DIR}/testoutp.ppm
            -DTEST_ARG6=${CMAKE_CURRENT_SOURCE_DIR}/testprog.jpg
            -DTEST_NAME=djpeg3
            -DTEST_COMPARE1=${CMAKE_CURRENT_SOURCE_DIR}/testimg.ppm
            -DTEST_COMPARE2=${CMAKE_CURRENT_BINARY_DIR}/testoutp.ppm
            -P ${CMAKE_SOURCE_DIR}/cmake/TestCompareFiles.cmake)

    # ./cjpeg -dct int -progressive -opt -outfile testoutp.jpg $(srcdir)/testimg.ppm
    add_test(NAME cjpeg2
        COMMAND ${CMAKE_COMMAND}
            -DTEST_APP=$<TARGET_FILE:cjpeg>
            -DTEST_ARG1=-dct
            -DTEST_ARG2=int
            -DTEST_ARG3=-progressive
            -DTEST_ARG4=-opt
            -DTEST_ARG5=-outfile
            -DTEST_ARG6=${CMAKE_CURRENT_BINARY_DIR}/testoutp.jpg
            -DTEST_ARG7=${CMAKE_CURRENT_SOURCE_DIR}/testimg.ppm
            -DTEST_NAME=cjpeg2
            -DTEST_COMPARE1=${CMAKE_CURRENT_SOURCE_DIR}/testimgp.jpg
            -DTEST_COMPARE2=${CMAKE_CURRENT_BINARY_DIR}/testoutp.jpg
            -P ${CMAKE_SOURCE_DIR}/cmake/TestCompareFiles.cmake)

    # ./jpegtran -outfile testoutt.jpg $(srcdir)/testprog.jpg
    add_test(NAME jpegtran
        COMMAND ${CMAKE_COMMAND}
            -DTEST_APP=$<TARGET_FILE:jpegtran>
            -DTEST_ARG1=-outfile
            -DTEST_ARG2=${CMAKE_CURRENT_BINARY_DIR}/testoutt.jpg
            -DTEST_ARG3=${CMAKE_CURRENT_SOURCE_DIR}/testprog.jpg
            -DTEST_NAME=jpegtran
            -DTEST_COMPARE1=${CMAKE_CURRENT_SOURCE_DIR}/testorig.jpg
            -DTEST_COMPARE2=${CMAKE_CURRENT_BINARY_DIR}/testoutt.jpg
            -P ${CMAKE_SOURCE_DIR}/cmake/TestCompareFiles.cmake)

endif()

# Export package ===============================================================

# Create the <Package>Config.cmake file

if(BUILD_JPEG_12)
    target_include_directories(${LIB_NAME}12 PUBLIC
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/12>
    )

    set(PACKAGE_NAME ${PROJECT_NAME}12)
    string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

    # Add all targets to the build-tree export set
    export(TARGETS ${INSTALL_TARGETS}
        FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

    if(REGISTER_PACKAGE)
        # Export the package for use from the build-tree
        # (this registers the build-tree with a global CMake-registry)
        export(PACKAGE ${PACKAGE_UPPER_NAME})
    endif()

    configure_file(cmake/PackageConfig.cmake.in
        ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)

    if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
        # Install the <Package>Config.cmake
        install(FILES
            ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
            DESTINATION ${INSTALL_CMAKECONF_DIR_12} COMPONENT dev)

        # Install the export set for use with the install-tree
        install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR_12} COMPONENT dev)
    endif()
endif()

if(BUILD_JPEG_8)
    target_include_directories(${LIB_NAME} PUBLIC
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/8>
    )

    set(PACKAGE_NAME ${PROJECT_NAME})
    string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

    # Add all targets to the build-tree export set
    export(TARGETS ${INSTALL_TARGETS}
        FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

    if(REGISTER_PACKAGE)
        # Export the package for use from the build-tree
        # (this registers the build-tree with a global CMake-registry)
        export(PACKAGE ${PACKAGE_UPPER_NAME})
    endif()

    configure_file(cmake/PackageConfig.cmake.in
        ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)

    if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
        # Install the <Package>Config.cmake
        install(FILES
            ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
            DESTINATION ${INSTALL_CMAKECONF_DIR_8} COMPONENT dev)

        # Install the export set for use with the install-tree
        install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR_8} COMPONENT dev)
    endif()
endif()

set(PACKAGE_NAME ${PROJECT_NAME})

# Archiving ====================================================================

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_NAME} Installation")
set(CPACK_PACKAGE_RELOCATABLE TRUE)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_GENERATOR "ZIP")
set(CPACK_MONOLITHIC_INSTALL ON)
set(CPACK_STRIP_FILES TRUE)

# Get cpack zip archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_CPACK_FILENAME})

include(CPack)
