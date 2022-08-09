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

    private const int THUMB_WIDTH = 162;
    private const int THUMB_HEIGHT = 100;

    private Gtk.Grid card_box;
    private Gtk.Menu context_menu;
    private Gtk.Revealer check_revealer;
    private Granite.AsyncImage image;

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
        var style_context = get_style_context ();
        style_context.add_class ("wallpaper-container");

        scale = style_context.get_scale ();

        height_request = THUMB_HEIGHT + 18;
        width_request = THUMB_WIDTH + 18;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/plug.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        image = new Granite.AsyncImage ();
        image.halign = Gtk.Align.CENTER;
        image.valign = Gtk.Align.CENTER;
        image.get_style_context ().set_scale (1);

        // We need an extra grid to not apply a scale == 1 to the "card" style.
        card_box = new Gtk.Grid ();
        card_box.get_style_context ().add_class ("card");
        card_box.add (image);
        card_box.margin = 9;

        var check = new Gtk.CheckButton () {
            active = true,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            can_focus = false
        };
        check.button_release_event.connect (() => { return Gdk.EVENT_STOP; });

        check_revealer = new Gtk.Revealer ();
        check_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        check_revealer.add (check);

        var overlay = new Gtk.Overlay ();
        overlay.add (card_box);
        overlay.add_overlay (check_revealer);

        var event_box = new Gtk.EventBox ();
        event_box.add (overlay);

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        margin = 6;
        add (event_box);

        if (uri != null) {
            var move_to_trash = new Gtk.MenuItem.with_label (_("Remove"));
            move_to_trash.activate.connect (() => trash ());

            var file = File.new_for_uri (uri);
            file.query_info_async.begin (GLib.FileAttribute.ACCESS_CAN_DELETE, 0, Priority.DEFAULT, null, (obj, res) => {
                try {
                    var info = file.query_info_async.end (res);
                    move_to_trash.sensitive = info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE);
                } catch (Error e) {
                    critical (e.message);
                }
            });

            context_menu = new Gtk.Menu ();
            context_menu.append (move_to_trash);
            context_menu.show_all ();
        }

        activate.connect (() => {
            checked = true;
        });

        event_box.button_press_event.connect (show_context_menu);

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

    private bool show_context_menu (Gtk.Widget sender, Gdk.EventButton evt) {
        if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
            context_menu.popup_at_pointer (null);
            return Gdk.EVENT_STOP;
        }
        return Gdk.EVENT_PROPAGATE;
    }

    private async void update_thumb () {
        if (thumb_path == null) {
            return;
        }

        try {
            yield image.set_from_file_async (File.new_for_path (thumb_path), THUMB_WIDTH, THUMB_HEIGHT, false);
        } catch (Error e) {
            warning (e.message);
        }

        load_artist_tooltip ();
    }
}
