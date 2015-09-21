
set (TARGET "set-wallpaper")
set (SOURCES "set-wallpaper.vala")
set (DEPENDENCIES granite posix)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${DEPENDENCIES})

vala_precompile (WALLPAPER_CONTRACT_VALA_C ${TARGET} ${SOURCES} PACKAGES ${DEPENDENCIES})
add_executable (${TARGET} ${WALLPAPER_CONTRACT_VALA_C})

link_directories (${DEPS_LIBRARY_DIRS})
target_link_libraries (${TARGET} m ${DEPS_LIBRARIES})
set_target_properties (${TARGET} PROPERTIES
	COMPILE_OPTIONS "${DEPS_CFLAGS} -DGETTEXT_PACKAGE=${GETTEXT_PACKAGE}")

install (TARGETS ${TARGET} DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/set-wallpaper.contract DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/contractor)

