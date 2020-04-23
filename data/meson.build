i18n.merge_file(
    input: 'io.elementary.switchboard.pantheon-shell.appdata.xml.in',
    output: 'io.elementary.switchboard.pantheon-shell.appdata.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(datadir, 'metainfo'),
    install: true
)

install_data (
    'gschema.xml',
    install_dir: join_paths (get_option ('datadir'), 'glib-2.0', 'schemas'),
    rename: 'io.elementary.desktop.interface.gschema.xml'
)

