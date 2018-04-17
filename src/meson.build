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

vala_args = []
if (plank_dep.version().version_compare('>=0.10.9'))
  vala_args += '--define=HAVE_PLANK_0_11'
endif

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
