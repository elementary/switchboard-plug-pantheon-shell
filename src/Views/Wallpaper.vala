/*
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
 */

[DBus (name = "org.freedesktop.DisplayManager.AccountsService")]
interface PantheonShell.AccountsServiceUser : Object {
    [DBus (name = "BackgroundFile")]
    public abstract string background_file { owned get; set; }
}

public class PantheonShell.Wallpaper : Gtk.Box {
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

    private static GLib.Settings settings;

    // Instance of the AccountsServices-Interface for this user
    private AccountsServiceUser? accountsservice = null;

    private Gtk.ScrolledWindow wallpaper_scrolled_window;
    private Gtk.FlowBox wallpaper_view;
    private Gtk.Overlay view_overlay;
    private Gtk.ComboBoxText combo;
    private Gtk.ColorButton color_button;

    private WallpaperContainer _active_wallpaper = null;
    private WallpaperContainer active_wallpaper {
        get {
            return _active_wallpaper;
        }
        set {
            if (_active_wallpaper != null) {
                _active_wallpaper.checked = false;
            }
            _active_wallpaper = value;
            wallpaper_view.select_child (_active_wallpaper);
            _active_wallpaper.checked = true;

            if (_active_wallpaper is SolidColorContainer) {
                combo.sensitive = false;
                settings.set_string ("primary-color", solid_color.color);
                settings.set_string ("picture-options", "none");
            } else {
                combo.sensitive = true;
                settings.set_string ("picture-options", combo.active_id);
            }
        }
    }

    private SolidColorContainer solid_color = null;
    private WallpaperContainer wallpaper_for_removal = null;

    private Cancellable last_cancellable;

    private string current_wallpaper_path;
    private bool prevent_update_mode = false; // When restoring the combo state, don't trigger the update.
    private bool finished; // Shows that we got or wallpapers together

    static construct {
        settings = new GLib.Settings ("org.gnome.desktop.background");
    }

    construct {
        // DBus connection needed in update_wallpaper for
        // passing the wallpaper-information to accountsservice.
        try {
            int uid = (int) Posix.getuid ();
            accountsservice = Bus.get_proxy_sync (BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    "/org/freedesktop/Accounts/User%i".printf (uid));
        } catch (Error e) {
            warning (e.message);
        }

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        wallpaper_view = new Gtk.FlowBox () {
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            homogeneous = true,
            row_spacing = 18,
            column_spacing = 18
        };
        wallpaper_view.add_css_class (Granite.STYLE_CLASS_VIEW);
        wallpaper_view.set_sort_func (wallpapers_sort_function);
        wallpaper_view.child_activated.connect (update_checked_wallpaper);

        var color = settings.get_string ("primary-color");
        create_solid_color_container (color);

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);
        wallpaper_view.add_controller (drop_target);
        drop_target.on_drop.connect (on_drag_data_received);

        wallpaper_scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            child = wallpaper_view
        };

        view_overlay = new Gtk.Overlay () {
            child = wallpaper_scrolled_window
        };

        var add_wallpaper_button = new Gtk.Button.with_label (_("Import Photo…")) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12
        };

        combo = new Gtk.ComboBoxText () {
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

        color_button = new Gtk.ColorButton () {
            margin_start = 6,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12,
            rgba = rgba_color
        };
        color_button.color_set.connect (update_color);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (add_wallpaper_button);
        size_group.add_widget (combo);
        size_group.add_widget (color_button);

        load_settings ();

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class ("inline-toolbar");
        actionbar.pack_start (add_wallpaper_button);
        actionbar.pack_end (color_button);
        actionbar.pack_end (combo);

        orientation = Gtk.Orientation.VERTICAL;
        append (separator);
        append (view_overlay);
        append (actionbar);

        add_wallpaper_button.clicked.connect (show_wallpaper_chooser);
    }

    private void show_wallpaper_chooser () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/*");

        var chooser = new Gtk.FileChooserNative (
            _("Import Photo !"),
            (Gtk.Window) get_root (),
            Gtk.FileChooserAction.OPEN,
            _("Import"),
            _("Cancel")
        ) {
            filter = filter,
            select_multiple = true,
            modal = true
        };

        chooser.response.connect ((id) => {
            chooser.destroy ();
            if (id == Gtk.ResponseType.ACCEPT) {
                ListModel files = chooser.get_files ();
                for (var iter = 0; iter < files.get_n_items (); iter++) {
                    var file = (File) files.get_item (iter);
                    string local_uri = file.get_uri ();
                    var dest = copy_for_library (file);
                    if (dest != null) {
                        local_uri = dest.get_uri ();
                    }

                    add_wallpaper_from_file (local_uri);
                }
            }
        });

        chooser.show ();
    }

    private void load_settings () {
        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.
        string picture_options = settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.sensitive = false;
            picture_options = "zoom";
        }

        prevent_update_mode = true;
        combo.active_id = picture_options;

        current_wallpaper_path = settings.get_string ("picture-uri");
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

        settings.set_string ("picture-uri", uri);
        accountsservice.background_file = path;
    }

    private void update_checked_wallpaper () {
        var selected_child = (WallpaperContainer) wallpaper_view.get_selected_children ().data;

        if (!(selected_child is SolidColorContainer)) {
            current_wallpaper_path = selected_child.uri;
            update_accountsservice ();
        }

        // We don't do gradient backgrounds, reset the key that might interfere
        settings.reset ("color-shading-type");

        active_wallpaper = selected_child;
    }

    private void update_color () {
        if (finished) {
            if (active_wallpaper != solid_color) {
                combo.sensitive = false;
            }

            create_solid_color_container (color_button.rgba.to_string ());
            wallpaper_view.prepend (solid_color);

            active_wallpaper = solid_color;
        }
    }

    private void update_mode () {
        if (!prevent_update_mode) {
            settings.set_string ("picture-options", combo.get_active_id ());

            // Changing the mode, while a solid color is selected, change focus to the
            // wallpaper tile.
            if (active_wallpaper == solid_color) {
                active_wallpaper.checked = false;

                var children = wallpaper_view.observe_children ();
                for (var iter = 0; iter < children.get_n_items (); iter++) {
                    var container = (WallpaperContainer) children.get_item (iter);
                    if (container.uri == current_wallpaper_path) {
                        active_wallpaper = container;
                        break;
                    }
                }
            }
        } else {
            prevent_update_mode = false;
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

                add_wallpaper_from_file (uri);
            }

            if (toplevel_folder) {
                create_solid_color_container (color_button.rgba.to_string ());
                wallpaper_view.prepend (solid_color);
                finished = true;

                if (settings.get_string ("picture-options") == "none") {
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
            wallpaper_view.remove (solid_color);
            solid_color.destroy ();
        }

        solid_color = new SolidColorContainer (color);
    }

    private void clean_wallpapers () {
        var child = wallpaper_view.get_first_child ();
        while (child != null) {
            wallpaper_view.remove (child);
            child.destroy ();
            child = wallpaper_view.get_first_child ();
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

    private bool on_drag_data_received (Gtk.DropTarget controller, Value val, double x, double y) {
        var file_list = (Gdk.FileList) val;
        foreach (var file in file_list.get_files ()) {
            try {
                var info = file.query_info (string.joinv (",", REQUIRED_FILE_ATTRS), FileQueryInfoFlags.NONE);

                if (!IOHelper.is_valid_file_type (info)) {
                    continue;
                }

                string local_uri = file.get_uri ();
                var dest = copy_for_library (file);
                if (dest != null) {
                    local_uri = dest.get_uri ();
                }

                add_wallpaper_from_file (local_uri);
            } catch (Error e) {
                warning (e.message);
            }
        }

        return true;
    }

    private void add_wallpaper_from_file (string uri) {
        // don't load 'removed' wallpaper on plug reload
        if (wallpaper_for_removal != null && wallpaper_for_removal.uri == uri) {
            return;
        }

        var wallpaper = new WallpaperContainer (uri);
        wallpaper_view.prepend (wallpaper);

        wallpaper.trash.connect (() => {
            send_undo_toast ();
            mark_for_removal (wallpaper);
        });

        // Select the wallpaper if it is the current wallpaper
        if (current_wallpaper_path == uri && settings.get_string ("picture-options") != "none") {
            active_wallpaper = wallpaper;
        }
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
        var children = view_overlay.observe_children ();
        for (int i = 0; i < children.get_n_items (); i++) {
            var child = (Gtk.Widget) children.get_item (i);
            if (child is Granite.Toast) {
                view_overlay.remove_overlay (child);
                child.destroy ();
            }
        }

        if (wallpaper_for_removal != null) {
            confirm_removal ();
        }

        var toast = new Granite.Toast (_("Wallpaper Deleted"));
        toast.set_default_action (_("Undo"));

        toast.default_action.connect (() => {
            undo_removal ();
        });

        var toast_revealer = (Gtk.Revealer) toast.get_first_child ();
        toast_revealer.notify["reveal-child"].connect (() => {
            if (!toast_revealer.reveal_child && wallpaper_for_removal != null) {
                confirm_removal ();
            }
        });

        view_overlay.add_overlay (toast);
        view_overlay.set_measure_overlay (toast, true);
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
        wallpaper_view.prepend (wallpaper_for_removal);
        wallpaper_for_removal = null;
    }
}
