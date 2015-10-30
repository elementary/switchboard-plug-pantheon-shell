using Gtk;

/*
stolen from old wallpaper plug
*/

// Helper class for the file IO functions we'll need
// Not needed at all, but helpful for organization
public class IOHelper : GLib.Object {
    // Check if the filename has a picture file extension.
    public static bool is_valid_file_type (GLib.FileInfo file_info) {

        // Check for correct file type, don't try to load directories and such
        if (file_info.get_file_type () != GLib.FileType.REGULAR) {
            return false;
        }

        // Now check if it is an accepted content type
        string[] accepted_types = {
            "image/jpeg",
            "image/png",
            "image/tiff",
            "image/svg+xml",
            "image/gif"
        };

        foreach (var type in accepted_types) {
            if (GLib.ContentType.equals (file_info.get_content_type (), type)) {
                return true;
            }
        }

        return false;
    }

    // Quickly count up all of the valid wallpapers in the wallpaper folder.
    public static int count_wallpapers (GLib.File wallpaper_folder) {
        GLib.FileInfo file_info = null;
        int count = 0;

        try {
            // Get an enumerator for all of the plain old files in the wallpaper folder.
            var enumerator = wallpaper_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            // While there's still files left to count
            while ((file_info = enumerator.next_file ()) != null) {
                // If it's a picture file
                if (is_valid_file_type(file_info)) {
                    count++;
                }
            }
        } catch(GLib.Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning ("Could not pre-scan wallpaper folder. Progress percentage may be off: %s", err.message);
            }
        }
        return count;
    }
}

public enum ColumnType {
    ICON,
    NAME
}

[DBus (name = "org.freedesktop.Accounts.User")]
interface AccountsServiceUser : Object {
    public abstract void set_background_file (string filename) throws IOError;
}

class Wallpaper : EventBox {

    GLib.Settings settings;

    //Instance of the AccountsServices-Interface for this user
    AccountsServiceUser accountsservice = null;

    Gtk.FlowBox wallpaper_view;
    WallpaperContainer active_wallpaper = null;
    SolidColorContainer solid_color = null;

    ComboBoxText combo;
    ComboBoxText folder_combo;

    ColorButton color_button;

    string current_wallpaper_path;
    Cancellable last_cancellable;

    Switchboard.Plug plug;

    // When restoring the combo state, don't trigger the update.
    bool prevent_update_mode = false;

    //shows that we got or wallpapers together
    public bool finished;

    //name of the default-wallpaper-link that we can prevent loading it again
    //(assumes that the defaultwallpaper is also in the system wallpaper directory)
    static string default_link = "file:///usr/share/backgrounds/elementaryos-default";

    public Wallpaper (Switchboard.Plug _plug) {
        plug = _plug;
        settings = new GLib.Settings ("org.gnome.desktop.background");

        //DBus connection needed in update_wallpaper for
        //passing the wallpaper-information to accountsservice.
         try {
            string uid = "%d".printf ((int) Posix.getuid ());
            accountsservice = Bus.get_proxy_sync (BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    "/org/freedesktop/Accounts/User" + uid);
        } catch (Error e) {
            warning (e.message);
        }

        var vbox = new Box (Orientation.VERTICAL, 4);

        wallpaper_view = new Gtk.FlowBox ();
        wallpaper_view.activate_on_single_click = true;
        wallpaper_view.column_spacing = wallpaper_view.row_spacing = 6;
        wallpaper_view.margin = 12;
        wallpaper_view.homogeneous = true;
        wallpaper_view.selection_mode = Gtk.SelectionMode.SINGLE;
        wallpaper_view.child_activated.connect (update_checked_wallpaper);

        var color = settings.get_string ("primary-color");
        create_solid_color_container (color);

        TargetEntry e = {"text/uri-list", 0, 0};
        wallpaper_view.drag_data_received.connect (on_drag_data_received);
        drag_dest_set (wallpaper_view, DestDefaults.ALL, {e}, Gdk.DragAction.COPY);

        var scrolled = new ScrolledWindow (null, null);
        scrolled.add (wallpaper_view);

        vbox.pack_start (scrolled, true, true, 5);

        folder_combo = new ComboBoxText ();
        folder_combo.append ("pic", _("Pictures"));
        folder_combo.append ("sys", _("Backgrounds"));
        folder_combo.append ("cus", _("Custom…"));
        folder_combo.changed.connect (update_wallpaper_folder);
        folder_combo.set_active (1);

        combo = new ComboBoxText ();
        combo.append ("centered", _("Centered"));
        combo.append ("scaled", _("Scaled"));
        combo.append ("stretched", _("Stretched"));
        combo.append ("zoom", _("Zoom"));
        combo.append ("spanned", _("Spanned"));
        combo.changed.connect (update_mode);

        Gdk.RGBA rgba_color = {};
        if (!rgba_color.parse (color)) {
            rgba_color = { 1, 1, 1, 1 };
        }
        
        color_button = new ColorButton ();
        color_button.rgba = rgba_color;
        color_button.color_set.connect (update_color);

        load_settings ();

        var hbox = new Box (Orientation.HORIZONTAL, 0);

        var bbox = new ButtonBox (Orientation.HORIZONTAL);
        bbox.set_margin_left (10);
        bbox.set_spacing (5);
        bbox.set_margin_top (8);
        bbox.set_margin_bottom (8);
        bbox.set_layout (ButtonBoxStyle.START);
        bbox.add (folder_combo);

        hbox.pack_start (bbox, false, false);

        //Spacer
        bbox = new ButtonBox (Orientation.HORIZONTAL);
        bbox.set_margin_right (10);
        bbox.set_spacing (5);
        bbox.set_margin_top (8);
        bbox.set_margin_bottom (8);
        bbox.set_layout (ButtonBoxStyle.END);
        bbox.add (combo);
        bbox.add (color_button);

        hbox.pack_end (bbox, false, false);

        vbox.pack_start (new Separator (Orientation.HORIZONTAL), false, true);
        vbox.pack_start (hbox, false, false);

        add (vbox);
    }

    void load_settings () {
        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.
        string picture_options = settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.set_sensitive (false);
            picture_options = "stretched";
        }
        prevent_update_mode = true;
        combo.set_active_id (picture_options);

        current_wallpaper_path = settings.get_string ("picture-uri");
    }

    void update_accountsservice () {
        /*
         * We pass the path to accountsservices that the login-screen can
         * see what background we selected. This is right now just a patched-in functionality of
         * accountsservice, so we expect that it is maybe not there
         * and do nothing if we encounter a unpatched accountsservices-backend.
        */
        try {
            var file = File.new_for_uri (current_wallpaper_path);
            string uri = file.get_uri ();
            string path = file.get_path ();

            var localfile = copy_bg_to_local (file);
            if (localfile != null) {
                uri = localfile.get_uri ();
                path = localfile.get_path ();
            }

            Posix.chmod (path, 0644);
            settings.set_string ("picture-uri", uri);
            accountsservice.set_background_file (path);
        } catch (Error e) {
            warning (e.message);
        }
    }

    void update_checked_wallpaper (Gtk.FlowBox box, Gtk.FlowBoxChild child) {
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

        children.set_checked (true);

        if (active_wallpaper != null) {
            active_wallpaper.set_checked (false);
        }

        active_wallpaper = children;
    }

    void update_color () {
        if (finished) {
            set_combo_disabled_if_necessary ();
            create_solid_color_container (color_button.rgba.to_string ());
            wallpaper_view.add (solid_color);
            wallpaper_view.select_child (solid_color);

            if (active_wallpaper != null) {
                active_wallpaper.set_checked (false);
            }

            active_wallpaper = solid_color;
            active_wallpaper.set_checked (true);
            settings.set_string ("primary-color", solid_color.color);
        }
    }

    void update_mode () {
        if (!prevent_update_mode) {
            settings.set_string ("picture-options", combo.get_active_id ());

            // Changing the mode, while a solid color is selected, change focus to the
            // wallpaper tile.
            if (active_wallpaper == solid_color) {
                active_wallpaper.set_checked (false);

                foreach (var child in wallpaper_view.get_children ()) {
                    var container = (WallpaperContainer) child;
                    if (container.uri == current_wallpaper_path) {
                        container.set_checked (true);
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

    void set_combo_disabled_if_necessary () {
        if (active_wallpaper != solid_color) {
            combo.set_sensitive (false);
            settings.set_string ("picture-options", "none");
        }
    }

    void update_wallpaper_folder () {
        if (last_cancellable != null)
            last_cancellable.cancel ();

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;
        if (folder_combo.get_active () == 0) {
            clean_wallpapers ();
            var picture_dir = GLib.File.new_for_path (GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES));
            load_wallpapers (picture_dir.get_uri (), cancellable);
        } else if (folder_combo.get_active () == 1) {
            clean_wallpapers ();

            var system_uri = "file:///usr/share/backgrounds";
            var user_uri = GLib.File.new_for_path (get_local_bg_location ()).get_uri ();

            load_wallpapers (system_uri, cancellable);
            load_wallpapers (user_uri, cancellable);
        } else if (folder_combo.get_active () == 2) {
            var dialog = new Gtk.FileChooserDialog (_("Select a folder"), null, FileChooserAction.SELECT_FOLDER);
            dialog.add_button (_("Cancel"), ResponseType.CANCEL);
            dialog.add_button (_("Open"), ResponseType.ACCEPT);
            dialog.set_default_response (ResponseType.ACCEPT);

            if (dialog.run () == ResponseType.ACCEPT) {
                clean_wallpapers ();
                load_wallpapers (dialog.get_file ().get_uri (), cancellable);
                dialog.destroy ();
            } else {
                dialog.destroy ();
            }
        }
    }

    async void load_wallpapers (string basefolder, Cancellable cancellable) {
        if (cancellable.is_cancelled () == true) {
            return;
        }

        folder_combo.set_sensitive (false);

        var directory = File.new_for_uri (basefolder);

        // The number of wallpapers we've added so far
        double done = 0.0;

        try {
            // Count the # of wallpapers
            int count = IOHelper.count_wallpapers(directory);
            if (count == 0) {
                folder_combo.set_sensitive (true);
            }

            // Enumerator object that will let us read through the wallpapers asynchronously
            var e = yield directory.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0, Priority.DEFAULT);

            while (true) {
                if (cancellable.is_cancelled () == true) {
                    return;
                }
                // Grab a batch of 10 wallpapers
                var files = yield e.next_files_async (10, Priority.DEFAULT);
                // Stop the loop if we've run out of wallpapers
                if (files == null) {
                    break;
                }
                // Loop through and add each wallpaper in the batch
                foreach (var info in files) {
                    if (cancellable.is_cancelled () == true) {
                        return;
                    }
                    // We're going to add another wallpaper
                    done++;

                    if (info.get_file_type () == FileType.DIRECTORY) {
                        // Spawn off another loader for the subdirectory
                        load_wallpapers (basefolder + "/" + info.get_name (), cancellable);
                        continue;
                    } else if (!IOHelper.is_valid_file_type (info)) {
                        // Skip non-picture files
                        continue;
                    }

                    var file = File.new_for_uri (basefolder + "/" + info.get_name ());
                    string uri = file.get_uri ();

                    // Skip the default_wallpaper as seen in the description of the
                    // default_link variable
                    if (uri == default_link) {
                        continue;
                    }

                    try {
                        var wallpaper = new WallpaperContainer (uri);
                        wallpaper_view.add (wallpaper);
                        wallpaper.show_all ();

                        // Select the wallpaper if it is the current wallpaper
                        if (current_wallpaper_path.has_suffix (uri) && settings.get_string ("picture-options") != "none") {
                            this.wallpaper_view.select_child (wallpaper);
                            //set the widget activated without activating it
                            wallpaper.set_checked (true);
                            active_wallpaper = wallpaper;
                        }

                        // Have GTK update the UI even while we're busy
                        // working on file IO.
                        while(Gtk.events_pending ()) {
                            Gtk.main_iteration();
                        }
                    } catch (Error e) {
                        warning (e.message);
                    }
                }
            }

            finished = true;

            if (solid_color == null) {
                create_solid_color_container (color_button.rgba.to_string ());
            } else {
                // Ugly workaround to keep the solid color last, because currently
                // load_wallpapers is running async, recursively. Just let each of them
                // add / remove the tile until it's settled.
                wallpaper_view.remove (solid_color);
            }
            
            wallpaper_view.add (solid_color);
            if (settings.get_string ("picture-options") == "none") {
                wallpaper_view.select_child (solid_color);
                solid_color.set_checked (true);
                active_wallpaper = solid_color;
            }

            folder_combo.set_sensitive (true);

        } catch (Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning (err.message);
            }
        }
    }

    void create_solid_color_container (string color) {
        if (solid_color != null) {
            wallpaper_view.unselect_child (solid_color);
            wallpaper_view.remove (solid_color);
            solid_color.destroy ();
        }

        solid_color = new SolidColorContainer (color);
        solid_color.show_all ();
    }

    void clean_wallpapers () {
        foreach (var child in wallpaper_view.get_children ()) {
            child.destroy ();
        }

        solid_color = null;
        //reduce memory usage and prevent to load old thumbnail
        Cache.clear ();
    }

    string get_local_bg_location () {
        return Path.build_filename (Environment.get_user_config_dir (), "backgrounds") + "/";
    }

    File? copy_bg_to_local (File source) {
        File? dest = null;
        try {
            var dest_folder = File.new_for_path (get_local_bg_location ());
            if (!dest_folder.query_exists ()) {
                dest_folder.make_directory ();
            }

            dest = File.new_for_path (get_local_bg_location () + source.get_basename ());
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning ("%s\n", e.message);
            return null;
        }

        return dest;        
    }

    void on_drag_data_received (Widget widget, Gdk.DragContext ctx, int x, int y, SelectionData sel, uint information, uint timestamp) {
        if (sel.get_length () > 0) {
            File file = File.new_for_uri (sel.get_uris ()[0]);
            var info = file.query_info (FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);

            if (!IOHelper.is_valid_file_type (info)) {
                Gtk.drag_finish (ctx, false, false, timestamp);
                return;
            }

            string local_uri = file.get_path ();
            var dest = copy_bg_to_local (file);
            if (dest != null) {
                local_uri = dest.get_path ();
            }

            // Add the wallpaper name and thumbnail to the IconView
            var wallpaper = new WallpaperContainer (local_uri);
            wallpaper_view.add (wallpaper);
            wallpaper.show_all ();

            Gtk.drag_finish (ctx, true, false, timestamp);
            return;
        }
        Gtk.drag_finish (ctx, false, false, timestamp);
        return;
    }
}
