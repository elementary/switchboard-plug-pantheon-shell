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

class Wallpaper : EventBox {

    class WallpaperContainer : Gtk.FlowBoxChild {
        public string filename { get; construct; }

        Gtk.Image image;

        public WallpaperContainer (string filename) {
            Object (filename: filename);

            try {
                image = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (filename, 150, 100, false));
                add (image);
            } catch (Error e) {
                warning ("Failed to load wallpaper thumbnail: %s", e.message);
            }
        }
    }

    GLib.Settings settings;

    Gtk.FlowBox wallpaper_view;
    ComboBoxText combo;
    ComboBoxText folder_combo;
    ColorButton color;
    string current_wallpaper_path;
    Cancellable last_cancellable;

    Switchboard.Plug plug;

    //shows that we got or wallpapers together
    public bool finished;

    //name of the default-wallpaper-link that we can prevent loading it again
    //(assumes that the defaultwallpaper is also in the system wallpaper directory)
    static string default_link = "file:///usr/share/backgrounds/elementaryos-default";

    public Wallpaper (Switchboard.Plug _plug) {
        plug = _plug;

        settings = new GLib.Settings ("org.gnome.desktop.background");

        var vbox = new Box (Orientation.VERTICAL, 4);

        wallpaper_view = new Gtk.FlowBox ();
        wallpaper_view.activate_on_single_click = true;
        wallpaper_view.column_spacing = wallpaper_view.row_spacing = 6;
        wallpaper_view.margin = 12;
        wallpaper_view.homogeneous = true;
        wallpaper_view.selection_mode = Gtk.SelectionMode.SINGLE;
        wallpaper_view.child_activated.connect (update_wallpaper);

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
        combo.append ("none", _("Solid Color"));
        combo.append ("centered", _("Centered"));
        combo.append ("scaled", _("Scaled"));
        combo.append ("stretched", _("Stretched"));
        combo.append ("zoom", _("Zoom"));
        combo.append ("spanned", _("Spanned"));
        combo.changed.connect (update_mode);

        color = new ColorButton ();
        color.color_set.connect (update_color);

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
        bbox.add (color);

        hbox.pack_end (bbox, false, false);

        vbox.pack_start (new Separator (Orientation.HORIZONTAL), false, true);
        vbox.pack_start (hbox, false, false);

        add (vbox);
    }

    void load_settings () {
        combo.set_active_id (settings.get_string ("picture-options"));

        Gdk.Color c;
        Gdk.Color.parse (settings.get_string ("primary-color"), out c);
        color.set_color (c);

        current_wallpaper_path = settings.get_string ("picture-uri");
    }

    void update_wallpaper (Gtk.FlowBox box, Gtk.FlowBoxChild child) {
        var selected = (WallpaperContainer) wallpaper_view.get_selected_children ().data;
        current_wallpaper_path = selected.filename;
        settings.set_string ("picture-uri", current_wallpaper_path);
    }

    void update_color () {
        Gdk.Color c;
        color.get_color (out c);
        settings.set_string ("primary-color", c.to_string ());
    }

    void update_mode () {
        settings.set_string ("picture-options", combo.get_active_id ());
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
            var user_uri = GLib.File.new_for_path (GLib.Environment.get_user_data_dir () + "/backgrounds").get_uri ();

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
                    string filename = file.get_path ();

                    // Skip the default_wallpaper as seen in the description of the
                    // default_link variable
                    if (filename == default_link) {
                        continue;
                    }

                    try {
                        var wallpaper = new WallpaperContainer (filename);
                        wallpaper_view.add (wallpaper);
                        wallpaper.show_all ();

                        // Select the wallpaper if it is the current wallpaper
                        if (current_wallpaper_path.has_suffix (filename)) {
                            this.wallpaper_view.select_child (wallpaper);
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

            folder_combo.set_sensitive (true);
        } catch (Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning (err.message);
            }
        }
    }

    void clean_wallpapers () {
        foreach (var child in wallpaper_view.get_children ())
            child.destroy ();
    }

    void on_drag_data_received (Widget widget, Gdk.DragContext ctx, int x, int y, SelectionData sel, uint information, uint timestamp) {
        if (sel.get_length () > 0) {
            File file = File.new_for_uri (sel.get_uris ()[0]);
            var info = file.query_info (FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);

            if (!IOHelper.is_valid_file_type (info)) {
                Gtk.drag_finish (ctx, false, false, timestamp);
                return;
            }


            string display_name = Filename.display_basename (file.get_path ());

            var dest_folder = File.new_for_path (Environment.get_user_data_dir () + "/backgrounds");
            var dest = File.new_for_path (Environment.get_user_data_dir () + "/backgrounds/" + display_name);
            if (!dest_folder.query_exists ()) {
                try {
                    dest_folder.make_directory ();
                } catch (Error e) {
                    warning ("Creating local wallpaper directory failed: %s", e.message);
                }
            }

            try {
                file.copy (dest, 0);
            } catch (Error e) {
                warning ("Copying wallpaper to local directory failed: %s", e.message);
            }

            string filename = dest.get_path ();

            // Add the wallpaper name and thumbnail to the IconView
            var wallpaper = new WallpaperContainer (filename);
            wallpaper_view.add (wallpaper);
            wallpaper.show_all ();

            Gtk.drag_finish (ctx, true, false, timestamp);
            return;
        }
        Gtk.drag_finish (ctx, false, false, timestamp);
        return;
    }
}
