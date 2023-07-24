/*
* Copyright 2011-2019 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Tom Beckmann
*/

public class PantheonShell.Multitasking : Gtk.Box {
    private GLib.Settings behavior_settings;

    construct {
        var hotcorner_title = new Gtk.Label (_("When the pointer enters a display corner")) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        hotcorner_title.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var topleft = new HotcornerControl (_("Top Left"), "topleft");
        var topright = new HotcornerControl (_("Top Right"), "topright");
        var bottomleft = new HotcornerControl (_("Bottom Left"), "bottomleft");
        var bottomright = new HotcornerControl (_("Bottom Right"), "bottomright");

        var workspaces_label = new Granite.HeaderLabel (_("Move windows to a new workspace")) {
            margin_top = 12
        };

        var fullscreen_checkbutton = new Gtk.CheckButton.with_label (_("When entering fullscreen"));
        var maximize_checkbutton = new Gtk.CheckButton.with_label (_("When maximizing"));

        var checkbutton_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_bottom = 12
        };
        checkbutton_grid.add (fullscreen_checkbutton);
        checkbutton_grid.add (maximize_checkbutton);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        grid.attach (hotcorner_title, 0, 0, 2);
        grid.attach (topleft, 0, 1, 2);
        grid.attach (topright, 0, 2, 2);
        grid.attach (bottomleft, 0, 3, 2);
        grid.attach (bottomright, 0, 4, 2);
        grid.attach (workspaces_label, 0, 6, 2);
        grid.attach (checkbutton_grid, 0, 7, 2);

        var clamp = new Hdy.Clamp ();
        clamp.add (grid);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        scrolled.add (clamp);

        add (scrolled);

        behavior_settings = new GLib.Settings ("org.pantheon.desktop.gala.behavior");
        behavior_settings.bind ("move-fullscreened-workspace", fullscreen_checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);
        behavior_settings.bind ("move-maximized-workspace", maximize_checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);
    }

    private class HotcornerControl : Gtk.Grid {
        public string label { get; construct; }
        public string position { get; construct; }

        private Gtk.Entry command_entry;
        private static Settings settings;
        private static Gtk.SizeGroup size_group;

        public HotcornerControl (string label, string position) {
            Object (
                label: label,
                position: position
            );
        }

        static construct {
            settings = new Settings ("org.pantheon.desktop.gala.behavior");
            size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
        }

        construct {
            var label = new Gtk.Label (label) {
                max_width_chars = 12,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD_CHAR
            };

            unowned var label_style_context = label.get_style_context ();
            label_style_context.add_class (Granite.STYLE_CLASS_CARD);
            label_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);
            label_style_context.add_class ("hotcorner");
            label_style_context.add_class (position);

            var combo = new Gtk.ComboBoxText () {
                hexpand = true,
                valign = Gtk.Align.END
            };
            combo.append ("none", _("Do nothing"));
            combo.append ("show-workspace-view", _("Multitasking View"));
            combo.append ("maximize-current", _("Maximize current window"));
            combo.append ("open-launcher", _("Show Applications Menu"));
            combo.append ("window-overview-all", _("Show all windows"));
            combo.append ("switch-to-workspace-previous", _("Switch to previous workspace"));
            combo.append ("switch-to-workspace-next", _("Switch to next workspace"));
            combo.append ("switch-to-workspace-last", _("Switch to new workspace"));
            combo.append ("custom-command", _("Execute custom command"));

            command_entry = new Gtk.Entry () {
                primary_icon_name = "utilities-terminal-symbolic",
            };

            var command_revealer = new Gtk.Revealer () {
                margin_top = 6,
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
            };
            command_revealer.add (command_entry);

            margin_bottom = 12;
            column_spacing = 12;
            attach (label, 0, 0, 1, 2);
            attach (combo, 1, 0);
            attach (command_revealer, 1, 1);

            size_group.add_widget (label);

            settings.bind ("hotcorner-" + position, combo, "active-id", SettingsBindFlags.DEFAULT);

            settings.bind_with_mapping (
                "hotcorner-" + position, command_revealer, "reveal-child", SettingsBindFlags.GET,
                (value, variant, user_data) => {
                    value.set_boolean (variant.get_string () == "custom-command");
                    return true;
                },
                (value, expected_type, user_data) => {
                    return new Variant.string ("custom-command");
                },
                null, null
            );

            get_command_string ();

            settings.changed["hotcorner-custom-command"].connect (() => {
                get_command_string ();
            });

            command_entry.changed.connect (() => {
                var this_command = "hotcorner-%s:%s".printf (position, command_entry.text);

                var setting_string = settings.get_string ("hotcorner-custom-command");

                var found = false;
                string[] commands = setting_string.split (";;");
                for (int i = 0; i < commands.length ; i++) {
                    if (commands[i].has_prefix ("hotcorner-" + position)) {
                        found = true;
                        commands[i] = this_command;
                    }
                }

                if (!found) {
                    commands += this_command;
                }

                settings.set_string ("hotcorner-custom-command", string.joinv (";;", commands));
            });
        }

        private void get_command_string () {
            var setting_string = settings.get_string ("hotcorner-custom-command");
            var this_command = "";

            string[] commands = setting_string.split (";;");
            foreach (unowned string command in commands) {
                if (command.has_prefix ("hotcorner-" + position)) {
                    this_command = command.replace ("hotcorner-%s:".printf (position), "");
                }
            }

            command_entry.text = this_command;
        }
    }
}
