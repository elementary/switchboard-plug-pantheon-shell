/*-
 * Copyright (c) 2015-2016 elementary LLC.
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
 */

[DBus (name = "org.freedesktop.Accounts.User")]
interface AccountsServiceUser : Object {
    public abstract void set_background_file (string filename) throws IOError;
}

public class Wallpaper : Gtk.Grid {
    public enum ColumnType {
        ICON,
        NAME
    }

    private const string [] REQUIRED_FILE_ATTRS = {
        FileAttribute.STANDARD_NAME,
        FileAttribute.STANDARD_TYPE,
        FileAttribute.STANDARD_CONTENT_TYPE,
        FileAttribute.STANDARD_IS_HIDDEN,
        FileAttribute.STANDARD_IS_BACKUP,
        FileAttribute.THUMBNAIL_PATH,
        FileAttribute.THUMBNAIL_IS_VALID
    };

    // name of the default-wallpaper-link that we can prevent loading it again
    // (assumes that the defaultwallpaper is also in the system wallpaper directory)
    static string DEFAULT_LINK = "file://%s/elementaryos-default".printf (SYSTEM_BACKGROUNDS_PATH);
    const string SYSTEM_BACKGROUNDS_PATH = "/usr/share/backgrounds";

    public Switchboard.Plug plug { get; construct set; }
    private GLib.Settings settings;
    private GLib.Settings plug_settings;

    //Instance of the AccountsServices-Interface for this user
    private AccountsServiceUser? accountsservice = null;

    private Gtk.ScrolledWindow wallpaper_scrolled_window;
    private Gtk.FlowBox wallpaper_view;
    private Gtk.ComboBoxText combo;
    private Gtk.ComboBoxText folder_combo;
    private Gtk.ColorButton color_button;
    private Gtk.Revealer custom_folder_button_revealer;

    private WallpaperContainer active_wallpaper = null;
    private SolidColorContainer solid_color = null;

    private Cancellable last_cancellable;

    private string current_wallpaper_path;
    private string? current_custom_directory_path = null;
    private bool prevent_update_mode = false; // When restoring the combo state, don't trigger the update.
    private bool finished; // Shows that we got or wallpapers together

    private const string PICTURES_DIR_COMBO_ID = "pic";
    private const string SYSTEM_DIR_COMBO_ID = "sys";
    private const string CUSTOM_DIR_COMBO_ID = "cus";

    public Wallpaper (Switchboard.Plug _plug) {
        Object (plug: _plug);
    }

    construct {
        settings = new GLib.Settings ("org.gnome.desktop.background");
        plug_settings = new GLib.Settings ("io.elementary.switchboard.plug.desktop");

        custom_folder_button_revealer = new Gtk.Revealer ();

        // DBus connection needed in update_wallpaper for
        // passing the wallpaper-information to accountsservice.
         try {
            int uid = (int)Posix.getuid ();
            accountsservice = Bus.get_proxy_sync (BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    "/org/freedesktop/Accounts/User%i".printf (uid));
        } catch (Error e) {
            warning (e.message);
        }

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        wallpaper_view = new Gtk.FlowBox ();
        wallpaper_view.activate_on_single_click = true;
        wallpaper_view.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        wallpaper_view.homogeneous = true;
        wallpaper_view.selection_mode = Gtk.SelectionMode.SINGLE;
        wallpaper_view.child_activated.connect (update_checked_wallpaper);

        var color = settings.get_string ("primary-color");
        create_solid_color_container (color);

        Gtk.TargetEntry e = {"text/uri-list", 0, 0};
        wallpaper_view.drag_data_received.connect (on_drag_data_received);
        Gtk.drag_dest_set (wallpaper_view, Gtk.DestDefaults.ALL, {e}, Gdk.DragAction.COPY);

        wallpaper_scrolled_window = new Gtk.ScrolledWindow (null, null);
        wallpaper_scrolled_window.expand = true;
        wallpaper_scrolled_window.add (wallpaper_view);

        folder_combo = new Gtk.ComboBoxText ();
        folder_combo.margin = 12;
        folder_combo.append (PICTURES_DIR_COMBO_ID, _("Pictures"));
        folder_combo.append (SYSTEM_DIR_COMBO_ID, _("Backgrounds"));
        folder_combo.append (CUSTOM_DIR_COMBO_ID, _("Custom…"));

        var saved_id = plug_settings.get_string ("current-wallpaper-source");
        current_custom_directory_path = plug_settings.get_string ("current-custom-path");

        folder_combo.changed.connect (update_wallpaper_folder);

        if (saved_id == CUSTOM_DIR_COMBO_ID) {
            if (!check_custom_dir_valid (current_custom_directory_path)) {
                saved_id = plug_settings.get_default_value ("current-wallpaper-source").get_string ();
                current_custom_directory_path = null;
            }
        }

        var custom_folder_open = new Gtk.Button.from_icon_name ("document-open");
        custom_folder_open.valign = Gtk.Align.CENTER;
        custom_folder_open.clicked.connect (() => show_custom_dir_chooser ());
        custom_folder_button_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        custom_folder_button_revealer.add (custom_folder_open);

        folder_combo.active_id = saved_id;

        combo = new Gtk.ComboBoxText ();
        combo.valign = Gtk.Align.CENTER;
        combo.append ("centered", _("Centered"));
        combo.append ("zoom", _("Zoom"));
        combo.append ("spanned", _("Spanned"));
        combo.changed.connect (update_mode);

        Gdk.RGBA rgba_color = {};
        if (!rgba_color.parse (color)) {
            rgba_color = { 1, 1, 1, 1 };
        }

        color_button = new Gtk.ColorButton ();
        color_button.margin = 12;
        color_button.margin_left = 0;
        color_button.rgba = rgba_color;
        color_button.color_set.connect (update_color);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (combo);
        size_group.add_widget (color_button);
        size_group.add_widget (folder_combo);

        load_settings ();

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        actionbar.add (folder_combo);
        actionbar.add (custom_folder_button_revealer);
        actionbar.pack_end (color_button);
        actionbar.pack_end (combo);

        attach (separator, 0, 0, 1, 1);
        attach (wallpaper_scrolled_window, 0, 1, 1, 1);
        attach (actionbar, 0, 2, 1, 1);
    }

    private void load_settings () {
        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.
        string picture_options = settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.set_sensitive (false);
            picture_options = "zoom";
        }

        prevent_update_mode = true;
        combo.set_active_id (picture_options);

        current_wallpaper_path = settings.get_string ("picture-uri");
    }

    /*
     * We pass the path to accountsservices that the login-screen can
     * see what background we selected. This is right now just a patched-in functionality of
     * accountsservice, so we expect that it is maybe not there
     * and do nothing if we encounter a unpatched accountsservices-backend.
    */
    private void update_accountsservice () {
        try {
            var file = File.new_for_uri (current_wallpaper_path);
            string uri = file.get_uri ();
            string path = file.get_path ();

            if (!path.has_prefix (SYSTEM_BACKGROUNDS_PATH) && !path.has_prefix (get_local_bg_location ())) {
                var local_file = copy_for_library (file);
                if (local_file != null) {
                    uri = local_file.get_uri ();
                }
            }

            var greeter_file = copy_for_greeter (file);
            if (greeter_file != null) {
                path = greeter_file.get_path ();
            }

            settings.set_string ("picture-uri", uri);
            accountsservice.set_background_file (path);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void update_checked_wallpaper (Gtk.FlowBox box, Gtk.FlowBoxChild child) {
        plug_settings.set_string ("current-wallpaper-source", folder_combo.active_id);
        if (folder_combo.active_id == CUSTOM_DIR_COMBO_ID && current_custom_directory_path != null) {
            plug_settings.set_string ("current-custom-path", current_custom_directory_path);
        }

        var children = (WallpaperContainer) wallpaper_view.get_selected_children ().data;

        if (!(children is SolidColorContainer)) {
            current_wallpaper_path = children.uri;
            update_accountsservice ();

            if (active_wallpaper == solid_color) {
                combo.set_sensitive (true);
                settings.set_string ("picture-options", combo.get_active_id ());
            }

        } else {
            set_combo_disabled_if_necessary ();
            settings.set_string ("primary-color", solid_color.color);
        }

        // We don't do gradient backgrounds, reset the key that might interfere
        settings.reset ("color-shading-type");

        children.checked = true;

        if (active_wallpaper != null && active_wallpaper != children) {
            active_wallpaper.checked = false;
        }

        active_wallpaper = children;
    }

    private void update_color () {
        if (finished) {
            set_combo_disabled_if_necessary ();
            create_solid_color_container (color_button.rgba.to_string ());
            wallpaper_view.add (solid_color);
            wallpaper_view.select_child (solid_color);

            if (active_wallpaper != null) {
                active_wallpaper.checked = false;
            }

            active_wallpaper = solid_color;
            active_wallpaper.checked = true;
            settings.set_string ("primary-color", solid_color.color);
        }
    }

    private void update_mode () {
        if (!prevent_update_mode) {
            settings.set_string ("picture-options", combo.get_active_id ());

            // Changing the mode, while a solid color is selected, change focus to the
            // wallpaper tile.
            if (active_wallpaper == solid_color) {
                active_wallpaper.checked = false;

                foreach (var child in wallpaper_view.get_children ()) {
                    var container = (WallpaperContainer) child;
                    if (container.uri == current_wallpaper_path) {
                        container.checked = true;
                        wallpaper_view.select_child (container);
                        active_wallpaper = container;
                        break;
                    }
                }
            }
        } else {
            prevent_update_mode = false;
        }
    }

    private void set_combo_disabled_if_necessary () {
        if (active_wallpaper != solid_color) {
            combo.set_sensitive (false);
            settings.set_string ("picture-options", "none");
        }
    }

    public void update_wallpaper_folder () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;
        if (folder_combo.active_id == PICTURES_DIR_COMBO_ID) {
            custom_folder_button_revealer.reveal_child = false;
            clean_wallpapers ();
            var picture_dir = GLib.File.new_for_path (GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES));
            load_wallpapers.begin (picture_dir.get_uri (), cancellable);
        } else if (folder_combo.active_id == SYSTEM_DIR_COMBO_ID) {
            custom_folder_button_revealer.reveal_child = false;
            clean_wallpapers ();

            var system_uri = "file://" + SYSTEM_BACKGROUNDS_PATH;
            var user_uri = GLib.File.new_for_path (get_local_bg_location ()).get_uri ();

            load_wallpapers.begin (system_uri, cancellable);
            load_wallpapers.begin (user_uri, cancellable);
        } else if (folder_combo.active_id == CUSTOM_DIR_COMBO_ID) {
            custom_folder_button_revealer.reveal_child = true;
            if (check_custom_dir_valid (current_custom_directory_path)) {
                clean_wallpapers ();
                load_wallpapers.begin (current_custom_directory_path, cancellable);
            } else {
                show_custom_dir_chooser ();
            }
        }
    }

    private static bool check_custom_dir_valid (string? uri) {
        if (uri == null || uri == "") {
            return false;
        }

        var custom_folder_file = File.new_for_uri (uri);
        if (!custom_folder_file.query_exists ()) {
            return false;
        }

        if (custom_folder_file.query_file_type (FileQueryInfoFlags.NONE) != FileType.DIRECTORY) {
            return false;
        }

        return true;
    }

    private void show_custom_dir_chooser () {
        var dialog = new Gtk.FileChooserDialog (_("Select a folder"), null, Gtk.FileChooserAction.SELECT_FOLDER);
        dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        dialog.add_button (_("Open"), Gtk.ResponseType.ACCEPT);
        dialog.set_default_response (Gtk.ResponseType.ACCEPT);

        if (check_custom_dir_valid (current_custom_directory_path)) {
            dialog.set_current_folder_uri (current_custom_directory_path);
        }

        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            if (last_cancellable != null) {
                last_cancellable.cancel ();
            }

            last_cancellable = new Cancellable ();

            var uri = dialog.get_file ().get_uri ();
            current_custom_directory_path = uri;
            clean_wallpapers ();
            load_wallpapers.begin (uri, last_cancellable);
            dialog.destroy ();
        } else {
            dialog.destroy ();
            if (current_custom_directory_path == null) {
                folder_combo.active_id = plug_settings.get_default_value ("current-wallpaper-source").get_string ();
            }
        }
    }

    private async void load_wallpapers (string basefolder, Cancellable cancellable, bool toplevel_folder = true) {
        if (cancellable.is_cancelled ()) {
            return;
        }

        var directory = File.new_for_uri (basefolder);

        try {
            // Enumerator object that will let us read through the wallpapers asynchronously
            var attrs = string.joinv (",", REQUIRED_FILE_ATTRS);
            var e = yield directory.enumerate_children_async (attrs, 0, Priority.DEFAULT);
            FileInfo file_info;

            // Loop through and add each wallpaper in the batch
            while ((file_info = e.next_file ()) != null) {
                if (cancellable.is_cancelled ()) {
                    ThumbnailGenerator.get_default ().dequeue_all ();
                    return;
                }

                if (file_info.get_is_hidden () || file_info.get_is_backup ()) {
                    continue;
                }

                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    // Spawn off another loader for the subdirectory
                    var subdir = directory.resolve_relative_path (file_info.get_name ());
                    yield load_wallpapers (subdir.get_path (), cancellable, false);
                    continue;
                } else if (!IOHelper.is_valid_file_type (file_info)) {
                    // Skip non-picture files
                    continue;
                }

                var file = directory.resolve_relative_path (file_info.get_name ());
                string uri = file.get_uri ();

                // Skip the default_wallpaper as seen in the description of the
                // default_link variable
                if (uri == DEFAULT_LINK) {
                    continue;
                }

                var thumb_path = file_info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
                var thumb_valid = file_info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
                var wallpaper = new WallpaperContainer (uri, thumb_path, thumb_valid);
                wallpaper_view.insert (wallpaper, -1);
                wallpaper.show_all ();

                // Select the wallpaper if it is the current wallpaper
                if (current_wallpaper_path.has_suffix (uri) && settings.get_string ("picture-options") != "none") {
                    this.wallpaper_view.select_child (wallpaper);
                    // Set the widget activated without activating it
                    wallpaper.checked = true;
                    active_wallpaper = wallpaper;
                }
            }

            if (toplevel_folder) {
                create_solid_color_container (color_button.rgba.to_string ());
                wallpaper_view.add (solid_color);
                finished = true;

                if (settings.get_string ("picture-options") == "none") {
                    wallpaper_view.select_child (solid_color);
                    solid_color.checked = true;
                    active_wallpaper = solid_color;
                }

                if (active_wallpaper != null) {
                    Gtk.Allocation alloc;
                    active_wallpaper.get_allocation (out alloc);
                    wallpaper_scrolled_window.get_vadjustment ().value = alloc.y;
                }
            }
        } catch (Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning (err.message);
            }
        }
    }

    private void create_solid_color_container (string color) {
        if (solid_color != null) {
            wallpaper_view.unselect_child (solid_color);
            wallpaper_view.remove (solid_color);
            solid_color.destroy ();
        }

        solid_color = new SolidColorContainer (color);
        solid_color.show_all ();
    }

    private void clean_wallpapers () {
        foreach (var child in wallpaper_view.get_children ()) {
            child.destroy ();
        }

        solid_color = null;
    }

    private static string get_local_bg_location () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds") + "/";
    }

    private static File? copy_for_library (File source) {
        File? dest = null;

        string local_bg_location = get_local_bg_location ();
        try {
            File folder = File.new_for_path (local_bg_location);
            folder.make_directory_with_parents ();
        } catch (Error e) {
            if (e is GLib.IOError.EXISTS) {
                debug ("Local background directory already exists");
            } else {
                warning (e.message);
            }
        }

        try {
            string path = Path.build_filename (local_bg_location, source.get_basename ());
            dest = File.new_for_path (path);
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning (e.message);
        }

        return dest;
    }

    private static File? copy_for_greeter (File source) {
        File? dest = null;
        try {
            string greeter_data_dir = Path.build_filename (Environment.get_variable ("XDG_GREETER_DATA_DIR"), "wallpaper");
            if (greeter_data_dir == "") {
                greeter_data_dir = Path.build_filename ("/var/lib/lightdm-data/", Environment.get_user_name (), "wallpaper");
            }

            var folder = File.new_for_path (greeter_data_dir);
            if (folder.query_exists ()) {
                var enumerator = folder.enumerate_children ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                FileInfo? info = null;
                while ((info = enumerator.next_file ()) != null) {
                    enumerator.get_child (info).@delete ();
                }
            } else {
                folder.make_directory_with_parents ();
            }

            dest = File.new_for_path (Path.build_filename (greeter_data_dir, source.get_basename ()));
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning (e.message);
            return null;
        }

        return dest;
    }

    private void on_drag_data_received (Gtk.Widget widget, Gdk.DragContext ctx, int x, int y, Gtk.SelectionData sel, uint information, uint timestamp) {
        if (sel.get_length () > 0) {
            try {
                File file = File.new_for_uri (sel.get_uris ()[0]);
                var info = file.query_info (string.joinv (",", REQUIRED_FILE_ATTRS), 0);

                if (!IOHelper.is_valid_file_type (info)) {
                    Gtk.drag_finish (ctx, false, false, timestamp);
                    return;
                }

                string local_uri = file.get_uri ();
                var dest = copy_for_library (file);
                if (dest != null) {
                    local_uri = dest.get_uri ();
                }

                // Add the wallpaper name and thumbnail to the IconView
                var thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
                var thumb_valid = info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
                var wallpaper = new WallpaperContainer (local_uri, thumb_path, thumb_valid);
                wallpaper_view.add (wallpaper);
                wallpaper.show_all ();

                Gtk.drag_finish (ctx, true, false, timestamp);
            } catch (Error e) {
                warning (e.message);
            }
        }

        Gtk.drag_finish (ctx, false, false, timestamp);
        return;
    }

    public void cancel_thumbnail_generation () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }
    }
}
