cmake_minimum_required(VERSION 3.7.0)

project(ondemandnavi VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 COMPONENTS Core Quick Location Widgets REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(QTAPPFW_NAVIGATION qtappfw-navigation REQUIRED)

add_subdirectory(app)
add_subdirectory(package)
