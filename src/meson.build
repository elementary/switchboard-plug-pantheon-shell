plug_files = files(
    'IOHelper.vala',
    'PantheonAccountsServicePlugin.vala',
    'Plug.vala',
    'ThumbnailGenerator.vala',
    'Views/Appearance.vala',
    'Views/Dock.vala',
    'Views/Multitasking.vala',
    'Views/Wallpaper.vala',
    'Widgets/SolidColorContainer.vala',
    'Widgets/WallpaperContainer.vala',
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

plank_datadir = plank_dep.get_pkgconfig_variable('pkgdatadir')

configuration = configuration_data()
configuration.set('PLANKDATADIR', plank_datadir)
configuration.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
configuration.set('GETTEXT_PACKAGE', meson.project_name() + '-plug')

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
