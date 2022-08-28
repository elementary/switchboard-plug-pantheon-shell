/*-
 * Copyright 2015-2022 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Erasmo Marín
 *
 */

public class PantheonShell.WallpaperContainer : Gtk.FlowBoxChild {
    public signal void trash ();

    protected const int THUMB_WIDTH = 162;
    protected const int THUMB_HEIGHT = 100;

    private static Gtk.CssProvider check_css_provider;
    private static Gtk.CheckButton check_group; // used for turning CheckButtons into RadioButtons

    private Gtk.Popover context_menu;
    private Gtk.Revealer check_revealer;
    protected Gtk.Picture image;

    public string uri { get; construct; }

    private bool thumb_valid { get; set; default = false; }
    private string? thumb_path { get; set; }
    public uint64 creation_date { get; set; default = 0; } // in unix time

    public bool checked {
        get {
            return check_revealer.reveal_child;
        }
        set {
            check_revealer.reveal_child = value;
            if (value) {
                set_state_flags (Gtk.StateFlags.CHECKED, false);
            } else {
                unset_state_flags (Gtk.StateFlags.CHECKED);
            }
        }
    }

    public WallpaperContainer (string uri) {
        Object (uri: uri);
    }

    static construct {
        check_css_provider = new Gtk.CssProvider ();
        check_css_provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/Check.css");

        check_group = new Gtk.CheckButton ();
    }

    construct {
        image = new Gtk.Picture () {
            can_shrink = true,
            keep_aspect_ratio = false
        };
        image.add_css_class (Granite.STYLE_CLASS_CARD);
        image.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var check = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            focusable = false,
            active = true,
            group = check_group
        };
        check.get_style_context ().add_provider (check_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        check_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = check
        };

        var overlay = new Gtk.Overlay () {
            child = image,
            halign = Gtk.Align.CENTER
        };
        overlay.add_overlay (check_revealer);

        var overlay_event_controller = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY
        };
        overlay.add_controller (overlay_event_controller);

        add_css_class ("wallpaper-container");
        child = overlay;

        // Context menu
        var move_to_trash = new Gtk.Button.with_label (_("Remove")) {
            sensitive = false
        };

        var context_menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        context_menu_box.append (move_to_trash);

        context_menu = new Gtk.Popover () {
            child = context_menu_box,
            autohide = true
        };
        context_menu.set_parent (this);

        // load file info
        if (uri != null) {
            var file = File.new_for_uri (uri);
            try {
                var info = file.query_info ("*", FileQueryInfoFlags.NONE);
                load_thumb_info (info);
                creation_date = info.get_attribute_uint64 (GLib.FileAttribute.TIME_CREATED);
                move_to_trash.sensitive = info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE);
            } catch (Error e) {
                critical (e.message);
            }
        }

        // signals
        check.notify["active"].connect (() => {
            check.active = true;
        });

        overlay_event_controller.pressed.connect (() => {
            context_menu.popup ();
        });

        move_to_trash.clicked.connect (() => trash ());

        // load thumb
        var scale = get_style_context ().get_scale ();
        try {
            if (uri != null) {
                if (thumb_path != null && thumb_valid) {
                    update_thumb.begin ();
                } else {
                    generate_and_load_thumb ();
                }
            } else {
                image.set_pixbuf (
                    new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, THUMB_WIDTH * scale, THUMB_HEIGHT * scale)
                );
            }
        } catch (Error e) {
            critical ("Failed to load wallpaper thumbnail: %s", e.message);
            return;
        }
    }

    private void load_thumb_info (FileInfo info) {
        thumb_valid = info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
        thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
    }

    private void generate_and_load_thumb () {
        var scale = get_style_context ().get_scale ();
        ThumbnailGenerator.get_default ().get_thumbnail (uri, THUMB_WIDTH * scale, () => {
            try {
                var file = File.new_for_uri (uri);
                var info = file.query_info (
                    string.join (",", FileAttribute.THUMBNAIL_PATH, FileAttribute.THUMBNAIL_IS_VALID),
                    FileQueryInfoFlags.NONE
                );
                load_thumb_info (info);
                update_thumb.begin ();
            } catch (Error e) {
                warning ("Error loading thumbnail for \"%s\": %s", uri, e.message);
            }
        });
    }

    private async void update_thumb () {
        if (!thumb_valid || thumb_path == null) {
            return;
        }

        image.set_filename (thumb_path);

        load_artist_tooltip ();
    }

    private void load_artist_tooltip () {
        var metadata = new GExiv2.Metadata ();
        try {
            var path = Filename.from_uri (uri);
            metadata.open_path (path);
        } catch (Error e) {
            warning ("Error parsing exif metadata of \"%s\": %s", uri, e.message);
            return;
        }

        if (metadata.has_exif ()) {
            string? artist_name = null;
            try {
                artist_name = metadata.try_get_tag_string ("Exif.Image.Artist");
            } catch (Error e) {
                warning (e.message);
            }

            if (artist_name != null) {
                set_tooltip_text (_("Artist: %s").printf (artist_name));
            }
        }
    }
}
