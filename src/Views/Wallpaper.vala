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

    private const string [] ALLOWED_MIMETYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    private static GLib.Settings gnome_background_settings;
    private static GLib.Settings gala_background_settings;

    // Instance of the AccountsServices-Interface for this user
    private static AccountsServiceUser? accountsservice = null;

    private Gtk.ScrolledWindow wallpaper_scrolled_window;
    private Gtk.FlowBox wallpaper_view;
    private Gtk.Overlay view_overlay;
    private Gtk.Switch dim_switch;
    private Gtk.ComboBoxText combo;
    private Gtk.ColorButton color_button;

    private GenericContainer? previous_wallpaper { get; set; default = null; }

    private SolidColorContainer solid_color = null;
    private UriContainer? wallpaper_for_removal = null;

    private Cancellable last_cancellable;

    static construct {
        gnome_background_settings = new GLib.Settings ("org.gnome.desktop.background");
        gala_background_settings = new Settings ("io.elementary.desktop.background");

        // DBus connection needed in update_wallpaper for
        // passing the wallpaper-information to accountsservice.
        try {
            int uid = (int) Posix.getuid ();
            accountsservice = Bus.get_proxy_sync (
                BusType.SYSTEM,
                "org.freedesktop.Accounts",
                "/org/freedesktop/Accounts/User%i".printf (uid)
            );
        } catch (IOError e) {
            warning (e.message);
        }
    }

    construct {
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);

        wallpaper_view = new Gtk.FlowBox () {
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            homogeneous = true,
            row_spacing = 18,
            column_spacing = 18
        };
        wallpaper_view.add_css_class (Granite.STYLE_CLASS_VIEW);
        wallpaper_view.set_sort_func (wallpapers_sort_function);
        wallpaper_view.add_controller (drop_target);

        wallpaper_scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            child = wallpaper_view
        };

        view_overlay = new Gtk.Overlay () {
            child = wallpaper_scrolled_window
        };

        var import_button = new Gtk.Button.with_label (_("Import Photo…")) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12
        };

        var dim_label = new Gtk.Label ("Dim wallpaper in dark style:") {
            margin_end = 12
        };

        dim_switch = new Gtk.Switch () {
            vexpand = false,
            valign = Gtk.Align.CENTER
        };

        combo = new Gtk.ComboBoxText () {
            valign = Gtk.Align.CENTER
        };
        combo.append ("centered", _("Centered"));
        combo.append ("zoom", _("Zoom"));
        combo.append ("spanned", _("Spanned"));

        color_button = new Gtk.ColorButton () {
            margin_start = 6,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 12
        };

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (import_button);
        size_group.add_widget (combo);
        size_group.add_widget (color_button);

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class ("inline-toolbar");
        actionbar.pack_start (import_button);
        actionbar.pack_start (dim_label);
        actionbar.pack_start (dim_switch);
        actionbar.pack_end (color_button);
        actionbar.pack_end (combo);

        orientation = Gtk.Orientation.VERTICAL;
        append (separator);
        append (view_overlay);
        append (actionbar);

        load_settings ();

        // connect signals
        drop_target.on_drop.connect (on_drag_data_received);
        wallpaper_view.child_activated.connect (update_checked_wallpaper);
        import_button.clicked.connect (show_wallpaper_chooser);
        combo.changed.connect (() => {
            gnome_background_settings.set_string ("picture-options", combo.get_active_id ());
        });
        color_button.color_set.connect (() => {
            gnome_background_settings.set_string ("primary-color", color_button.rgba.to_string ());
            wallpaper_view.child_activated (solid_color);
        });
    }

    private void load_settings () {
        gala_background_settings.bind ("dim-wallpaper-in-dark-style", dim_switch, "active", SettingsBindFlags.DEFAULT);

        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.

        var picture_options = gnome_background_settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.sensitive = false;
            picture_options = "zoom";
        }

        combo.active_id = picture_options;

        // load color button
        var color = gnome_background_settings.get_string ("primary-color");
        Gdk.RGBA rgba_color = {};
        if (!rgba_color.parse (color)) {
            rgba_color = { 1, 1, 1, 1 };
        }
        color_button.rgba = rgba_color;
    }

    private void show_wallpaper_chooser () {
        var filter = new Gtk.FileFilter ();
        foreach (var type in ALLOWED_MIMETYPES) {
            filter.add_mime_type (type);
        }

        var chooser = new Gtk.FileChooserNative (
            _("Import Photo"),
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
                var files = chooser.get_files ();
                for (var iter = 0; iter < files.get_n_items (); iter++) {
                    var file = (File) files.get_item (iter);
                    var local_uri = file.get_uri ();
                    var dest = copy_for_library (file);
                    if (dest != null) {
                        local_uri = dest.get_uri ();
                    }

                    add_wallpaper_from_uri (local_uri);
                }
            }
        });

        chooser.show ();
    }

    private void update_checked_wallpaper (Gtk.FlowBoxChild _selected_child) {
        // We don't do gradient backgrounds, reset the key that might interfere
        gnome_background_settings.reset ("color-shading-type");

        if (previous_wallpaper != null) {
            previous_wallpaper.checked = false;
        }

        var selected_child = (GenericContainer) _selected_child;
        previous_wallpaper = selected_child;

        selected_child.checked = true;

        if (selected_child is SolidColorContainer) {
            combo.sensitive = false;

            gnome_background_settings.set_string ("picture-options", "none");
        } else if (selected_child is UriContainer) {
            combo.sensitive = true;

            gnome_background_settings.set_string ("picture-uri", ((UriContainer) selected_child).uri);
            gnome_background_settings.set_string ("picture-options", combo.active_id);
            update_accountsservice ();
        }
    }

    /*
     * This integrates with LightDM
     */
     private void update_accountsservice () {
        var file = File.new_for_uri (gnome_background_settings.get_string ("picture-uri"));
        var path = file.get_path ();

        var greeter_file = copy_for_greeter (file);
        if (greeter_file != null) {
            path = greeter_file.get_path ();
        }

        accountsservice.background_file = path;
    }

    public void load_wallpapers () {
        clean_wallpapers ();

        load_wallpapers_from_folders.begin ((obj, res) => {
            solid_color = new SolidColorContainer ();
            wallpaper_view.append (solid_color);

            // Select current wallpaper
            if (gnome_background_settings.get_string ("picture-options") == "none") {
                wallpaper_view.child_activated (solid_color);
            } else {
                var children = wallpaper_view.observe_children ();
                for (var i = 0; i < children.get_n_items (); i++) {
                    var child = (GenericContainer) children.get_item (i);
                    if (child is UriContainer && gnome_background_settings.get_string ("picture-uri") == ((UriContainer) child).uri) {
                        wallpaper_view.child_activated (child);
                    }
                }
            }
        });
    }

    private void clean_wallpapers () {
        var child = wallpaper_view.get_first_child ();
        while (child != null) {
            wallpaper_view.remove (child);
            child.destroy ();
            child = wallpaper_view.get_first_child ();
        }
    }

    private async void load_wallpapers_from_folders () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;

        foreach (unowned string directory in get_bg_directories ()) {
            yield load_wallpapers_from_folder (directory);
        }
    }

    private async void load_wallpapers_from_folder (string folder) {
        if (last_cancellable.is_cancelled ()) {
            return;
        }

        var directory = File.new_for_path (folder);
        try {
            // Enumerator object that will let us read through the wallpapers asynchronously
            var attrs = string.joinv (",", REQUIRED_FILE_ATTRS);
            var e = yield directory.enumerate_children_async (attrs, FileQueryInfoFlags.NONE, Priority.DEFAULT);

            FileInfo? file_info = null;
            // Loop through and add each wallpaper in the batch
            while ((file_info = e.next_file ()) != null) {
                if (last_cancellable.is_cancelled ()) {
                    ThumbnailGenerator.get_default ().dequeue_all ();
                    return;
                }

                if (file_info.get_is_hidden () || file_info.get_is_backup () || file_info.get_is_symlink ()) {
                    continue;
                }

                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    // Spawn off another loader for the subdirectory
                    var subdir = directory.resolve_relative_path (file_info.get_name ());
                    yield load_wallpapers_from_folder (subdir.get_path ());
                    continue;
                }

                var file = directory.resolve_relative_path (file_info.get_name ());
                var uri = file.get_uri ();

                add_wallpaper_from_uri (uri);
            }
        } catch (Error e) {
            if (!(e is IOError.NOT_FOUND)) {
                warning (e.message);
            }
        }
    }

    private static string get_local_bg_directory () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds");
    }

    private static string[] get_system_bg_directories () {
        string[] directories = {};
        foreach (unowned string data_dir in Environment.get_system_data_dirs ()) {
            var system_background_dir = Path.build_filename (data_dir, "backgrounds");
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

        var local_bg_directory = get_local_bg_directory ();
        try {
            File.new_for_path (local_bg_directory).make_directory_with_parents ();
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

    private bool on_drag_data_received (Value val, double x, double y) {
        var file_list = (Gdk.FileList) val;
        foreach (var file in file_list.get_files ()) {
            var local_uri = file.get_uri ();
            var dest = copy_for_library (file);
            if (dest != null) {
                local_uri = dest.get_uri ();
            }

            add_wallpaper_from_uri (local_uri);
        }

        return true;
    }

    private void add_wallpaper_from_uri (string uri) {
        var file = File.new_for_uri (uri);

        string? mime_type;
        try {
            var file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE, null);
            mime_type = file_info.get_content_type ().to_ascii ();
        } catch (Error e) {
            warning ("Could not get mime type for file \"%s\": %s", uri, e.message);
            return;
        }

        if (!(mime_type in ALLOWED_MIMETYPES)) {
            warning ("File with not allowed mimetype: %s, %s", uri, mime_type);
            return;
        }

        // don't load 'removed' wallpaper on plug reload
        if (wallpaper_for_removal != null && wallpaper_for_removal.uri == uri) {
            return;
        }

        UriContainer wallpaper;
        if (mime_type.has_prefix ("image/")) {
            wallpaper = new ImageContainer (uri);

        //  TODO: https://github.com/elementary/switchboard-plug-pantheon-shell/issues/296
        //  } else if (mime_type == "application/xml") {
        //      wallpaper = new XMLContainer (uri);
        //      ...

        } else {
            // Fixes Use of possibly unassigned local variable `wallpaper'
            // However, the file should never get here since it's been filtered before
            warning ("Filtered file %s of unknown type %s", uri, mime_type);
            return;
        }

        wallpaper_view.append (wallpaper);

        wallpaper.trash.connect (() => {
            send_undo_toast ();
            mark_for_removal (wallpaper);
        });
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

    private void mark_for_removal (UriContainer wallpaper) {
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
        wallpaper_view.append (wallpaper_for_removal);
        wallpaper_for_removal = null;
    }

    private int wallpapers_sort_function (Gtk.FlowBoxChild _child1, Gtk.FlowBoxChild _child2) {
        var child1 = (GenericContainer) _child1;
        var child2 = (GenericContainer) _child2;

        if (child1 is SolidColorContainer) {
            return 1;
        } else if (child2 is SolidColorContainer) {
            return -1;
        }

        var uri1 = ((UriContainer) child1).uri;
        var uri2 = ((UriContainer) child2).uri;

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

        var child1_date = ((UriContainer) child1).creation_date;
        var child2_date = ((UriContainer) child2).creation_date;

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

    public void cancel_thumbnail_generation () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }
    }
}
