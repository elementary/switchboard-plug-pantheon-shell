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

[DBus (name = "org.freedesktop.DisplayManager.AccountsService")]
interface PantheonShell.AccountsServiceUser : Object {
    [DBus (name = "BackgroundFile")]
    public abstract string background_file { owned get; set; }
}

public class PantheonShell.Wallpaper : Gtk.Grid {
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
        FileAttribute.STANDARD_IS_SYMLINK,
        FileAttribute.THUMBNAIL_PATH,
        FileAttribute.THUMBNAIL_IS_VALID
    };

    public Switchboard.Plug plug { get; construct set; }

    private static GLib.Settings gnome_background_settings;
    private static GLib.Settings gala_background_settings;

    //Instance of the AccountsServices-Interface for this user
    private AccountsServiceUser? accountsservice = null;

    private Gtk.ScrolledWindow wallpaper_scrolled_window;
    private Gtk.FlowBox wallpaper_view;
    private Gtk.Overlay view_overlay;
    private Gtk.Switch dim_switch;
    private Gtk.ComboBoxText combo;
    private Gtk.ColorButton color_button;

    private WallpaperContainer active_wallpaper = null;
    private SolidColorContainer solid_color = null;
    private WallpaperContainer wallpaper_for_removal = null;

    private Cancellable last_cancellable;

    private string current_wallpaper_path;
    private bool prevent_update_mode = false; // When restoring the combo state, don't trigger the update.
    private bool finished; // Shows that we got or wallpapers together

    public Wallpaper (Switchboard.Plug _plug) {
        Object (plug: _plug);
    }

    static construct {
        gnome_background_settings = new GLib.Settings ("org.gnome.desktop.background");
        gala_background_settings = new GLib.Settings ("io.elementary.desktop.background");
    }

    construct {
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
        wallpaper_view.set_sort_func (wallpapers_sort_function);

        var color = gnome_background_settings.get_string ("primary-color");
        create_solid_color_container (color);

        Gtk.TargetEntry e = {"text/uri-list", 0, 0};
        wallpaper_view.drag_data_received.connect (on_drag_data_received);
        Gtk.drag_dest_set (wallpaper_view, Gtk.DestDefaults.ALL, {e}, Gdk.DragAction.COPY);

        wallpaper_scrolled_window = new Gtk.ScrolledWindow (null, null);
        wallpaper_scrolled_window.expand = true;
        wallpaper_scrolled_window.add (wallpaper_view);

        view_overlay = new Gtk.Overlay ();
        view_overlay.add (wallpaper_scrolled_window);

        var add_wallpaper_button = new Gtk.Button.with_label (_("Import Photo…"));
        add_wallpaper_button.margin = 12;

        var dim_label = new Gtk.Label (_("Dim with dark style:"));

        dim_switch = new Gtk.Switch () {
            margin_end = 6,
            valign = Gtk.Align.CENTER
        };

        combo = new Gtk.ComboBoxText () {
            margin_end = 6,
            valign = Gtk.Align.CENTER
        };
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
        color_button.margin_start = 0;
        color_button.rgba = rgba_color;
        color_button.color_set.connect (update_color);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (add_wallpaper_button);
        size_group.add_widget (combo);
        size_group.add_widget (color_button);

        load_settings ();

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        actionbar.pack_start (add_wallpaper_button);
        actionbar.pack_end (color_button);
        actionbar.pack_end (combo);
        actionbar.pack_end (dim_switch);
        actionbar.pack_end (dim_label);

        attach (separator, 0, 0, 1, 1);
        attach (view_overlay, 0, 1, 1, 1);
        attach (actionbar, 0, 2, 1, 1);

        add_wallpaper_button.clicked.connect (show_wallpaper_chooser);
    }

    private void show_wallpaper_chooser () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/*");

        var preview_area = new Granite.AsyncImage (false);
        preview_area.pixel_size = 256;
        preview_area.margin_end = 12;

        var chooser = new Gtk.FileChooserNative (
            _("Import Photo"), null, Gtk.FileChooserAction.OPEN,
            _("Import"),
            _("Cancel")
        );
        chooser.filter = filter;
        chooser.select_multiple = true;
        chooser.set_preview_widget (preview_area);

        chooser.update_preview.connect (() => {
            string uri = chooser.get_preview_uri ();

            if (uri != null && uri.has_prefix ("file://") == true) {
                var file = GLib.File.new_for_uri (uri);
                preview_area.set_from_gicon_async.begin (new FileIcon (file), 256);
                preview_area.show ();
            } else {
                preview_area.hide ();
            }
        });

        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            SList<string> uris = chooser.get_uris ();
            foreach (unowned string uri in uris) {
                var file = GLib.File.new_for_uri (uri);
                string local_uri = uri;
                var dest = copy_for_library (file);
                if (dest != null) {
                    local_uri = dest.get_uri ();
                }

                add_wallpaper_from_file (file, local_uri);
            }
        }

        chooser.destroy ();
    }

    private void load_settings () {
        gala_background_settings.bind ("dim-wallpaper-in-dark-style", dim_switch, "active", SettingsBindFlags.DEFAULT);

        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.
        string picture_options = gnome_background_settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.set_sensitive (false);
            picture_options = "zoom";
        }

        prevent_update_mode = true;
        combo.set_active_id (picture_options);

        current_wallpaper_path = gnome_background_settings.get_string ("picture-uri");
    }

    /*
     * This integrates with LightDM
     */
    private void update_accountsservice () {
        var file = File.new_for_uri (current_wallpaper_path);
        string uri = file.get_uri ();
        string path = file.get_path ();

        bool path_has_prefix_bg_dir = false;
        foreach (unowned string directory in get_bg_directories ()) {
            if (path.has_prefix (directory)) {
                path_has_prefix_bg_dir = true;
                break;
            }
        }

        if (!path_has_prefix_bg_dir) {
            var local_file = copy_for_library (file);
            if (local_file != null) {
                uri = local_file.get_uri ();
            }
        }

        var greeter_file = copy_for_greeter (file);
        if (greeter_file != null) {
            path = greeter_file.get_path ();
        }

        gnome_background_settings.set_string ("picture-uri", uri);
        accountsservice.background_file = path;
    }

    private void update_checked_wallpaper (Gtk.FlowBox box, Gtk.FlowBoxChild child) {
        var children = (WallpaperContainer) wallpaper_view.get_selected_children ().data;

        if (!(children is SolidColorContainer)) {
            current_wallpaper_path = children.uri;
            update_accountsservice ();

            if (active_wallpaper == solid_color) {
                combo.set_sensitive (true);
                gnome_background_settings.set_string ("picture-options", combo.get_active_id ());
            }

        } else {
            set_combo_disabled_if_necessary ();
            gnome_background_settings.set_string ("primary-color", solid_color.color);
        }

        // We don't do gradient backgrounds, reset the key that might interfere
        gnome_background_settings.reset ("color-shading-type");

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
            gnome_background_settings.set_string ("primary-color", solid_color.color);
        }
    }

    private void update_mode () {
        if (!prevent_update_mode) {
            gnome_background_settings.set_string ("picture-options", combo.get_active_id ());

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
            gnome_background_settings.set_string ("picture-options", "none");
        }
    }

    public void update_wallpaper_folder () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;

        clean_wallpapers ();

        foreach (unowned string directory in get_bg_directories ()) {
            load_wallpapers.begin (directory, cancellable);
        }
    }

    private async void load_wallpapers (string basefolder, Cancellable cancellable, bool toplevel_folder = true) {
        if (cancellable.is_cancelled ()) {
            return;
        }

        var directory = File.new_for_path (basefolder);

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

                if (file_info.get_is_hidden () || file_info.get_is_backup () || file_info.get_is_symlink ()) {
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

                add_wallpaper_from_file (file, uri);
            }

            if (toplevel_folder) {
                create_solid_color_container (color_button.rgba.to_string ());
                wallpaper_view.add (solid_color);
                finished = true;

                if (gnome_background_settings.get_string ("picture-options") == "none") {
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

    private static string get_local_bg_directory () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds") + "/";
    }

    private static string[] get_system_bg_directories () {
        string[] directories = {};
        foreach (unowned string data_dir in Environment.get_system_data_dirs ()) {
            var system_background_dir = Path.build_filename (data_dir, "backgrounds") + "/";
            if (FileUtils.test (system_background_dir, FileTest.EXISTS)) {
                debug ("Found system background directory: %s", system_background_dir);
                directories += system_background_dir;
            }
        }

        return directories;
    }

    private string[] get_bg_directories () {
        string[] background_directories = {};

        // Add user background directory first
        background_directories += get_local_bg_directory ();

        foreach (var bg_dir in get_system_bg_directories ()) {
            background_directories += bg_dir;
        }

        if (background_directories.length == 0) {
            warning ("No background directories found");
        }

        return background_directories;
    }

    private static File? copy_for_library (File source) {
        File? dest = null;

        string local_bg_directory = get_local_bg_directory ();
        try {
            File folder = File.new_for_path (local_bg_directory);
            folder.make_directory_with_parents ();
        } catch (Error e) {
            if (e is GLib.IOError.EXISTS) {
                debug ("Local background directory already exists");
            } else {
                warning (e.message);
            }
        }

        try {
            var timestamp = new DateTime.now_local ().format ("%Y-%m-%d-%H-%M-%S");
            var filename = "%s-%s".printf (timestamp, source.get_basename ());
            string path = Path.build_filename (local_bg_directory, filename);
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
            // Ensure wallpaper is readable by greeter user (owner rw, others r)
            FileUtils.chmod (dest.get_path (), 0604);
        } catch (Error e) {
            warning (e.message);
            return null;
        }

        return dest;
    }

    private void on_drag_data_received (Gtk.Widget widget, Gdk.DragContext ctx, int x, int y, Gtk.SelectionData sel, uint information, uint timestamp) {
        if (sel.get_length () > 0) {
            try {
                var file = File.new_for_uri (sel.get_uris ()[0]);
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

                add_wallpaper_from_file (file, local_uri);

                Gtk.drag_finish (ctx, true, false, timestamp);
            } catch (Error e) {
                warning (e.message);
            }
        }

        Gtk.drag_finish (ctx, false, false, timestamp);
        return;
    }

    private void add_wallpaper_from_file (GLib.File file, string uri) {
        // don't load 'removed' wallpaper on plug reload
        if (wallpaper_for_removal != null && wallpaper_for_removal.uri == uri) {
            return;
        }

        try {
            var info = file.query_info (string.joinv (",", REQUIRED_FILE_ATTRS), 0);
            var thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
            var thumb_valid = info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
            var wallpaper = new WallpaperContainer (uri, thumb_path, thumb_valid);
            wallpaper_view.add (wallpaper);

            wallpaper.show_all ();

            wallpaper.trash.connect (() => {
                send_undo_toast ();
                mark_for_removal (wallpaper);
            });

            // Select the wallpaper if it is the current wallpaper
            if (current_wallpaper_path.has_suffix (uri) && gnome_background_settings.get_string ("picture-options") != "none") {
                this.wallpaper_view.select_child (wallpaper);
                // Set the widget activated without activating it
                wallpaper.checked = true;
                active_wallpaper = wallpaper;
            }
        } catch (Error e) {
            critical ("Unable to add wallpaper: %s", e.message);
        }

        wallpaper_view.invalidate_sort ();
    }

    public void cancel_thumbnail_generation () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }
    }

    private int wallpapers_sort_function (Gtk.FlowBoxChild _child1, Gtk.FlowBoxChild _child2) {
        var child1 = (WallpaperContainer) _child1;
        var child2 = (WallpaperContainer) _child2;
        var uri1 = child1.uri;
        var uri2 = child2.uri;

        if (uri1 == null || uri2 == null) {
            return 0;
        }

        var uri1_is_system = false;
        var uri2_is_system = false;
        foreach (var bg_dir in get_system_bg_directories ()) {
            bg_dir = "file://" + bg_dir;
            uri1_is_system = uri1.has_prefix (bg_dir) || uri1_is_system;
            uri2_is_system = uri2.has_prefix (bg_dir) || uri2_is_system;
        }

        // Sort system wallpapers last
        if (uri1_is_system && !uri2_is_system) {
            return 1;
        } else if (!uri1_is_system && uri2_is_system) {
            return -1;
        }

        var child1_date = child1.creation_date;
        var child2_date = child2.creation_date;

        // sort by filename if creation dates are equal
        if (child1_date == child2_date) {
            return uri1.collate (uri2);
        }

        // sort recently added first
        if (child1_date >= child2_date) {
            return -1;
        } else {
            return 1;
        }
    }

    private void send_undo_toast () {
        foreach (weak Gtk.Widget child in view_overlay.get_children ()) {
            if (child is Granite.Widgets.Toast) {
                child.destroy ();
            }
        }

        if (wallpaper_for_removal != null) {
            confirm_removal ();
        }

        var toast = new Granite.Widgets.Toast (_("Wallpaper Deleted"));
        toast.set_default_action (_("Undo"));
        toast.show_all ();

        toast.default_action.connect (() => {
            undo_removal ();
        });

        toast.notify["child-revealed"].connect (() => {
            if (!toast.child_revealed && wallpaper_for_removal != null) {
                confirm_removal ();
            }
        });

        view_overlay.add_overlay (toast);
        toast.send_notification ();
    }

    private void mark_for_removal (WallpaperContainer wallpaper) {
        wallpaper_view.remove (wallpaper);
        wallpaper_for_removal = wallpaper;
    }

    private void confirm_removal () {
        var wallpaper_file = File.new_for_uri (wallpaper_for_removal.uri);
        wallpaper_file.trash_async.begin ();
        wallpaper_for_removal.destroy ();
        wallpaper_for_removal = null;
    }

    private void undo_removal () {
        wallpaper_view.add (wallpaper_for_removal);
        wallpaper_for_removal = null;
    }
}
