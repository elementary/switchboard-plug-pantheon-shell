plug_files = files(
    'ThumbnailGenerator.vala',
    'IOHelper.vala',
    'GalaSettings.vala',
    'desktop-plug.vala',
    'Widgets/WallpaperContainer.vala',
    'Widgets/SolidColorContainer.vala',
    'Views/Wallpaper.vala',
    'Views/HotCorners.vala',
    'Views/Dock.vala',
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    plug_files,
    config_file,
    plug_resources,
    vala_args: vala_args,
    dependencies: [
        glib_dep,
        gio_dep,
        gobject_dep,
        gtk_dep,
        dependency('granite'),
        dependency('gexiv2'),
        dependency('gnome-desktop-3.0'),
        plank_dep,
        posix_dep,
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'personal')
)
