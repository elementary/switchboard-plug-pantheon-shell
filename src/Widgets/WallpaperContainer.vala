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

    protected const int THUMB_WIDTH = 256;
    protected const int THUMB_HEIGHT = 144;
    protected Gtk.Picture image;

    private Gtk.Box card_box;
    private Gtk.Revealer check_revealer;

    public string? thumb_path { get; construct set; }
    public bool thumb_valid { get; construct; }
    public string uri { get; construct; }
    public uint64 creation_date = 0;

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

        image = new Gtk.Picture () {
            content_fit = COVER,
            height_request = THUMB_HEIGHT
        };
        image.add_css_class (Granite.STYLE_CLASS_CARD);
        image.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var check = new Gtk.CheckButton () {
            active = true,
            halign = START,
            valign = START,
            can_focus = false,
            can_target = false
        };

        check_revealer = new Gtk.Revealer () {
            child = check,
            transition_type = CROSSFADE
        };

        var overlay = new Gtk.Overlay () {
            child = image
        };
        overlay.add_overlay (check_revealer);

        halign = CENTER;
        valign = CENTER;

        child = overlay;

        if (uri != null) {
            var remove_wallpaper_action = new SimpleAction ("trash", null);
            remove_wallpaper_action.activate.connect (() => trash ());

            var action_group = new SimpleActionGroup ();
            action_group.add_action (remove_wallpaper_action);

            insert_action_group ("wallpaper", action_group);

            var file = File.new_for_uri (uri);
            try {
                var info = file.query_info ("*", FileQueryInfoFlags.NONE);
                creation_date = info.get_attribute_uint64 (GLib.FileAttribute.TIME_CREATED);
                remove_wallpaper_action.set_enabled (info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE));
            } catch (Error e) {
                critical (e.message);
            }

            var menu_model = new Menu ();
            menu_model.append (_("Remove"), "wallpaper.trash");

            var context_menu = new Gtk.PopoverMenu.from_model (menu_model) {
                halign = START,
                has_arrow = false
            };
            context_menu.set_parent (this);

            var secondary_click_gesture = new Gtk.GestureClick () {
                button = Gdk.BUTTON_SECONDARY
            };
            secondary_click_gesture.released.connect ((n_press, x, y) => {
                secondary_click_gesture.set_state (CLAIMED);
                context_menu.pointing_to = Gdk.Rectangle () {
                    x = (int) x,
                    y = (int) y
                };
                context_menu.popup ();
            });

            add_controller (secondary_click_gesture);
        }

        activate.connect (() => {
            checked = true;
        });
        try {
            if (uri != null) {
                if (thumb_path != null && thumb_valid) {
                    update_thumb.begin ();
                } else {
                    generate_and_load_thumb ();
                }
            } else {
                image.set_filename (thumb_path);
            }
        } catch (Error e) {
            critical ("Failed to load wallpaper thumbnail: %s", e.message);
            return;
        }
    }

    private void generate_and_load_thumb () {
        ThumbnailGenerator.get_default ().get_thumbnail (uri, THUMB_WIDTH * scale_factor, () => {
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

    private async void update_thumb () {
        if (thumb_path == null) {
            return;
        }

        image.set_filename (thumb_path);

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
                try {
                    var artist_name = metadata.try_get_tag_string ("Exif.Image.Artist");
                    if (artist_name != null) {
                        tooltip_text = _("Artist: %s").printf (artist_name);
                    }
                } catch (Error e) {
                    critical ("Unable to set wallpaper artist name: %s", e.message);
                }
            }
        }
    }
}
