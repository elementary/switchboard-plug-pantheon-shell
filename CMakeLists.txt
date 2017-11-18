# This a sample CMakeLists.txt for compiling plug for Switchboard
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

# Set the Properties of your Plug

# Set the Name of the plug, should be an executable command, lowercase, no spaces 
set (PLUGNAME "pantheon-desktop")
# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "personal")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "Desktop")
# The symbolic name of the Icon to use for the plug
set (PLUGICON "preferences-desktop-wallpaper")
# Set the version for the plug
set (VERSION "0.2.6")

project (${PLUGNAME} C)

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

include (GNUInstallDirs)
set (DATADIR ${CMAKE_INSTALL_FULL_LIBDIR}/switchboard)
set (PLANKDATADIR ${CMAKE_INSTALL_FULL_DATADIR}/plank)
set (PKGDATADIR ${DATADIR}/${PLUGCATEGORY}/${PLUGNAME})
set (GETTEXT_PACKAGE ${PLUGNAME}-plug)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Comment this out to enable C compiler warnings
add_definitions (-w)
add_definitions (-DGNOME_DESKTOP_USE_UNSTABLE_API)

find_package (PkgConfig)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

include(GSettings)
add_schema("data/io.elementary.switchboard.plug.desktop.gschema.xml")

# Files
file (GLOB resources ${CMAKE_CURRENT_SOURCE_DIR}/data/*.svg)

# Traslation stuff
add_subdirectory (po)
# Info-plug
install (FILES ${resources} DESTINATION ${PKGDATADIR})

add_subdirectory(src)
add_subdirectory(set-wallpaper-contract)
