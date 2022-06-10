/*-
 * Copyright (c) 2015-2017 elementary LLC. (https://bugs.launchpad.net/switchboard-plug-pantheon-shell)
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

    private const int THUMB_WIDTH = 162;
    private const int THUMB_HEIGHT = 100;

    private Gtk.Box card_box;
    private Gtk.Popover context_menu;
    private Gtk.GestureClick overlay_event_controller;
    private Gtk.Revealer check_revealer;
    private Gtk.Image image;

    public string? thumb_path { get; construct set; }
    public bool thumb_valid { get; construct; }
    public string uri { get; construct; }
    public Gdk.Pixbuf thumb { get; set; }

    private int scale;

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                card_box.set_state_flags (Gtk.StateFlags.CHECKED, false);
                check_revealer.reveal_child = true;
            } else {
                card_box.unset_state_flags (Gtk.StateFlags.CHECKED);
                check_revealer.reveal_child = false;
            }

            queue_draw ();
        }
    }

    public bool selected {
        get {
            return Gtk.StateFlags.SELECTED in get_state_flags ();
        } set {
            if (value) {
                set_state_flags (Gtk.StateFlags.SELECTED, false);
            } else {
                unset_state_flags (Gtk.StateFlags.SELECTED);
            }

            queue_draw ();
        }
    }

    public WallpaperContainer (string uri, string? thumb_path, bool thumb_valid) {
        Object (uri: uri, thumb_path: thumb_path, thumb_valid: thumb_valid);
    }

    construct {
        add_css_class ("wallpaper-container");

        scale = get_style_context ().get_scale ();

        height_request = THUMB_HEIGHT + 18;
        width_request = THUMB_WIDTH + 18;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/plug.css");
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        image = new Gtk.Image () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        image.get_style_context ().set_scale (1);

        // We need an extra grid to not apply a scale == 1 to the "card" style.
        card_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 9,
            margin_end = 9,
            margin_top = 9,
            margin_bottom = 9
        };
        card_box.add_css_class ("card");
        card_box.append (image);

        var check = new Gtk.Image.from_icon_name ("selection-checked") {
            pixel_size = 24,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };

        check_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = check
        };

        var overlay = new Gtk.Overlay () {
            child = card_box
        };
        overlay.add_overlay (check_revealer);

        overlay_event_controller = new Gtk.GestureClick ();
        overlay.add_controller (overlay_event_controller);

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        margin_start = 6;
        margin_end = 6;
        margin_top = 6;
        margin_bottom = 6;
        child = overlay;

        if (uri != null) {
            var move_to_trash = new Gtk.Button.with_label (_("Remove"));
            move_to_trash.clicked.connect (() => trash ());

            var file = File.new_for_uri (uri);
            file.query_info_async.begin (GLib.FileAttribute.ACCESS_CAN_DELETE, 0, Priority.DEFAULT, null, (obj, res) => {
                try {
                    var info = file.query_info_async.end (res);
                    move_to_trash.sensitive = info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE);
                } catch (Error e) {
                    critical (e.message);
                }
            });

            context_menu = new Gtk.Popover () {
                child = move_to_trash
            };
        }

        activate.connect (() => {
            checked = true;
        });

        overlay_event_controller.pressed.connect (show_context_menu);

        try {
            if (uri != null) {
                if (thumb_path != null && thumb_valid) {
                    update_thumb.begin ();
                } else {
                    generate_and_load_thumb ();
                }
            } else {
                thumb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, THUMB_WIDTH * scale, THUMB_HEIGHT * scale);
                image.gicon = thumb;
            }
        } catch (Error e) {
            critical ("Failed to load wallpaper thumbnail: %s", e.message);
            return;
        }
    }

    private void generate_and_load_thumb () {
        ThumbnailGenerator.get_default ().get_thumbnail (uri, THUMB_WIDTH * scale, () => {
            try {
                var file = File.new_for_uri (uri);
                var info = file.query_info (FileAttribute.THUMBNAIL_PATH + "," + FileAttribute.THUMBNAIL_IS_VALID, 0);
                thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
                update_thumb.begin ();
            } catch (Error e) {
                warning ("Error loading thumbnail for '%s': %s", uri, e.message);
            }
        });
    }

    private void load_artist_tooltip () {
        if (uri != null) {
            string path = "";
            GExiv2.Metadata metadata;
            try {
                path = Filename.from_uri (uri);
                metadata = new GExiv2.Metadata ();
                metadata.open_path (path);
            } catch (Error e) {
                warning ("Error parsing exif metadata of \"%s\": %s", path, e.message);
                return;
            }

            if (metadata.has_exif ()) {
                var artist_name = metadata.get_tag_string ("Exif.Image.Artist");
                if (artist_name != null) {
                    set_tooltip_text (_("Artist: %s").printf (artist_name));
                }
            }
        }
    }

    private void show_context_menu (int n_press, double x, double y) {
        var evt = overlay_event_controller.get_current_event ();
        if (evt.get_event_type () == Gdk.EventType.BUTTON_PRESS && evt.get_modifier_state () == Gdk.ModifierType.BUTTON3_MASK) {
            context_menu.popup ();
            // return Gdk.EVENT_STOP;
        }
        // return Gdk.EVENT_PROPAGATE;
    }

    private async void update_thumb () {
        if (thumb_path == null) {
            return;
        }

        image.set_from_file (thumb_path);
        image.width_request = THUMB_WIDTH;
        image.height_request = THUMB_HEIGHT;

        load_artist_tooltip ();
    }
}
