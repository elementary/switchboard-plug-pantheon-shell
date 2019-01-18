contract_exec_name = 'io.elementary.contract.set-wallpaper'
contract_path = get_option('libexecdir')

contract_configuration = configuration_data()
contract_configuration.set('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
contract_configuration.set('EXEC_NAME', contract_exec_name)
contract_configuration.set('SWEXECDIR', join_paths(get_option('prefix'), contract_path))
contract_configuration.set('GETTEXT_DOMAIN', gettext_name)

config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : contract_configuration
)

wallpaper_contract = configure_file(
    input: 'set-wallpaper.contract.in',
    output: '@BASENAME@',
    configuration: contract_configuration,
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'contractor')
)

executable(
    contract_exec_name,
    'set-wallpaper.vala',
    config_header,
    dependencies: [
        glib_dep,
        gio_dep,
        gobject_dep,
        gtk_dep,
        posix_dep,
        meson.get_compiler('c').find_library('m')
    ],
    install: true,
    install_dir: contract_path
)
