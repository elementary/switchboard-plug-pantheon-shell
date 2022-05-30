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
    private Gtk.Revealer custom_command_revealer;
    private Gee.HashSet<string> keys_using_custom_command = new Gee.HashSet<string> ();
    private const string ANIMATIONS_SCHEMA = "org.pantheon.desktop.gala.animations";
    private const string ANIMATIONS_KEY = "enable-animations";

    construct {
        var hotcorner_title = new Gtk.Label (_("When the cursor enters the corner of the display:")) {
            halign = Gtk.Align.START,
            margin_bottom = 6,
            margin_top = 6
        };
        hotcorner_title.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var topleft = new HotcornerControl (_("Top Left"), "topleft");
        var topright = new HotcornerControl (_("Top Right"), "topright");
        var bottomleft = new HotcornerControl (_("Bottom Left"), "bottomleft");
        var bottomright = new HotcornerControl (_("Bottom Right"), "bottomright");

        var custom_command = new Gtk.Entry () {
            hexpand = true,
            primary_icon_name = "utilities-terminal-symbolic"
        };

        var cc_label = new Gtk.Label (_("Custom command:"));

        var cc_grid = new Gtk.Grid ();
        cc_grid.column_spacing = 12;
        cc_grid.margin_bottom = 12;
        cc_grid.add (cc_label);
        cc_grid.add (custom_command);

        custom_command_revealer = new Gtk.Revealer ();
        custom_command_revealer.add (cc_grid);

        var workspaces_label = new Gtk.Label (_("Move windows to a new workspace:")) {
            halign = Gtk.Align.END,
            margin_top = 12,
            margin_bottom = 12
        };

        var fullscreen_checkbutton = new Gtk.CheckButton.with_label (_("When entering fullscreen"));
        var maximize_checkbutton = new Gtk.CheckButton.with_label (_("When maximizing"));

        var checkbutton_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 12,
            margin_bottom = 12
        };
        checkbutton_grid.add (fullscreen_checkbutton);
        checkbutton_grid.add (maximize_checkbutton);

        var animations_label = new Gtk.Label (_("Window animations:")) {
            halign = Gtk.Align.END
        };

        var animations_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            halign = Gtk.Align.CENTER,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        grid.attach (hotcorner_title, 0, 0, 2);
        grid.attach (topleft, 0, 1, 2);
        grid.attach (topright, 0, 2, 2);
        grid.attach (bottomleft, 0, 3, 2);
        grid.attach (bottomright, 0, 4, 2);
        grid.attach (custom_command_revealer, 0, 5, 2);
        grid.attach (workspaces_label, 0, 6);
        grid.attach (checkbutton_grid, 1, 6);
        grid.attach (animations_label, 0, 7);
        grid.attach (animations_switch, 1, 7);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        scrolled.add (grid);

        add (scrolled);

        var animations_settings = new GLib.Settings (ANIMATIONS_SCHEMA);
        animations_settings.bind (ANIMATIONS_KEY, animations_switch, "active", SettingsBindFlags.DEFAULT);

        behavior_settings = new GLib.Settings ("org.pantheon.desktop.gala.behavior");
        behavior_settings.bind ("hotcorner-custom-command", custom_command, "text", GLib.SettingsBindFlags.DEFAULT);
        behavior_settings.bind ("move-fullscreened-workspace", fullscreen_checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);
        behavior_settings.bind ("move-maximized-workspace", maximize_checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);

        hotcorner_changed ();
        behavior_settings.changed.connect (() => {
            hotcorner_changed ();
        });
    }

    private void hotcorner_changed () {
        string[] hotcorner_keys = {"hotcorner-topleft", "hotcorner-topright", "hotcorner-bottomleft", "hotcorner-bottomright"};
        foreach (unowned var key in hotcorner_keys) {
            if (behavior_settings.get_enum (key) == 5) { //Custom Command
                keys_using_custom_command.add (key);
            } else {
                keys_using_custom_command.remove (key);
            }

            custom_command_revealer.reveal_child = keys_using_custom_command.size > 0;
        }
    }

    private class HotcornerControl : Gtk.Box {
        public string label { get; construct; }
        public string position { get; construct; }

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
                valign = Gtk.Align.CENTER
            };
            combo.append ("none", _("Do nothing"));
            combo.append ("show-workspace-view", _("Multitasking View"));
            combo.append ("maximize-current", _("Maximize current window"));
            combo.append ("open-launcher", _("Show Applications Menu"));
            combo.append ("window-overview-all", _("Show all windows"));
            combo.append ("switch-to-workspace-last", _("Switch to new workspace"));
            combo.append ("custom-command", _("Execute custom command"));

            margin_bottom = 12;
            spacing = 12;
            add (label);
            add (combo);

            size_group.add_widget (label);

            settings.bind ("hotcorner-" + position, combo, "active-id", SettingsBindFlags.DEFAULT);
        }
    }
}
