find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED glib-2.0 switchboard-2.0 granite gtk+-3.0>=3.10)

add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${PLUGNAME}
    desktop-plug.vala
    GalaSettings.vala
    PlankSettings.vala
    Wallpaper.vala
    SlingshotSettings.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    switchboard-2.0
    granite
OPTIONS
    --thread
)

add_library (${PLUGNAME} MODULE ${VALA_C})
target_link_libraries(${PLUGNAME} m)

# Installation
install (TARGETS ${PLUGNAME} DESTINATION ${PKGDATADIR})