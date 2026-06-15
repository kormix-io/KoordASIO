cmake_minimum_required(VERSION 3.16)

project(kdasioconfig VERSION 0.1 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

enable_language("RC")

find_package(Qt6 COMPONENTS Quick QuickControls2 Multimedia Widgets REQUIRED)

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/../../CMakeLists.txt" KOORDASIO_ROOT_CMAKE)
string(REGEX MATCH "project\\(KoordASIO VERSION ([0-9.]+)" _ "${KOORDASIO_ROOT_CMAKE}")
if(NOT CMAKE_MATCH_1)
    message(FATAL_ERROR "Could not read VERSION from root CMakeLists.txt")
endif()
set(KOORDASIO_VERSION "${CMAKE_MATCH_1}")

set(PROJECT_SOURCES
    main.cpp
    appinstance.cpp
    appinstance.h
    configmodel.cpp
    configmodel.h
    traymanager.cpp
    traymanager.h
)

set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/mainicon.rc")

qt_add_executable(kdasioconfig
    WIN32
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
    app.qrc
    ${app_icon_resource_windows}
)

target_compile_definitions(kdasioconfig PRIVATE KOORDASIO_VERSION="${KOORDASIO_VERSION}")

target_link_libraries(kdasioconfig PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Widgets
)

set_target_properties(kdasioconfig PROPERTIES
    OUTPUT_NAME "KoordASIOControl"
    WIN32_EXECUTABLE TRUE
)

qt_finalize_executable(kdasioconfig)
