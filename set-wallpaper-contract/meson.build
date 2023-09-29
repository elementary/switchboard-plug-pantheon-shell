contract_exec_name = 'io.elementary.contract.set-wallpaper'
contract_path = libexecdir

contract_configuration = configuration_data()
contract_configuration.set('EXEC_NAME', contract_exec_name)
contract_configuration.set('SWEXECDIR', join_paths(get_option('prefix'), contract_path))
contract_configuration.set('GETTEXT_DOMAIN', gettext_name)

wallpaper_contract = configure_file(
    input: 'set-wallpaper.contract.in',
    output: '@BASENAME@',
    configuration: contract_configuration,
    install_dir: join_paths(datadir, 'contractor')
)

contract_config_file = configure_file(
    input: 'Config.vala.in',
    output: '@BASENAME@',
    configuration: contract_configuration
)

executable(
    contract_exec_name,
    contract_config_file,
    'set-wallpaper.vala',
    meson.source_root () / 'src' / 'WallpaperOperation.vala',
    dependencies: [
        glib_dep,
        gio_dep,
        gobject_dep,
#        granite_dep,
#        gtk_dep,
        # TODO: Re-use the variables above when the plug itself is ported to GTK 4
        dependency('gtk4'),
        dependency('granite-7'),
        posix_dep,
        meson.get_compiler('c').find_library('m')
    ],
    install: true,
    install_dir: contract_path
)
