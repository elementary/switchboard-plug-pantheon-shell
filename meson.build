project(
    'desktop',
    'vala', 'c',
    version: '8.1.0'
)
gettext_name = 'io.elementary.settings.' + meson.project_name()
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))
libexecdir = join_paths(prefix, get_option('libexecdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    '-DG_LOG_DOMAIN="@0@"'.format(gettext_name),
    language: 'c'
)

gio_dep = dependency('gio-2.0')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite-7', version: '>=7.5.0')
gtk_dep = dependency('gtk4', version: '>=4.10')
hdy_dep = dependency ('libadwaita-1')
posix_dep = meson.get_compiler('vala').find_library('posix')

plug_resources = gnome.compile_resources(
    'plug_resources',
    'data/icons.gresource.xml',
    source_dir: 'data'
)

subdir('data')
subdir('src')
subdir('po')
