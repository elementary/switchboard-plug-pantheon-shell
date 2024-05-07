# Desktop Settings
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-pantheon-shell/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot-appearance.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libswitchboard-3-dev
* libgee-0.8-dev
* libgexiv2-dev
* libgtk-4-dev (>=4.10)
* libgranite-7-dev (>=7.5.0)
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
