plug_files = files(
    'ThumbnailGenerator.vala',
    'IOHelper.vala',
    'PantheonAccountsServicePlugin.vala',
    'Plug.vala',
    'Widgets/WallpaperContainer.vala',
    'Widgets/SolidColorContainer.vala',
    'Views/Wallpaper.vala',
    'Views/Appearance.vala',
    'Views/HotCorners.vala',
    'Views/Dock.vala',
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

plank_datadir = plank_dep.get_pkgconfig_variable('pkgdatadir')

configuration = configuration_data()
configuration.set('PLANKDATADIR', plank_datadir)

config_file = configure_file(
    input: 'Config.vala.in',
    output: '@BASENAME@',
    configuration: configuration
)

shared_module(
    meson.project_name(),
    plug_files,
    config_file,
    plug_resources,
    dependencies: [
        glib_dep,
        gio_dep,
        gobject_dep,
        granite_dep,
        gtk_dep,
        dependency('gexiv2'),
        dependency('gnome-desktop-3.0'),
        plank_dep,
        posix_dep,
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'personal')
)
