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
    // name of the default-wallpaper-link that we can prevent loading it again
    // (assumes that the defaultwallpaper is also in the system wallpaper directory)
    const string SYSTEM_BACKGROUNDS_PATH = "/usr/share/backgrounds";
    static string DEFAULT_LINK = "file://%s/elementaryos-default".printf (SYSTEM_BACKGROUNDS_PATH);

    private BackgroundSettings bg_settings;

    //Instance of the AccountsServices-Interface for this user
    private AccountsServiceUser? accountsservice = null;

    private Gtk.FlowBox wallpaper_view;
    private Gtk.ComboBoxText combo;
    private Gtk.ComboBoxText folder_combo;
    private Gtk.ColorButton color_button;

    private WallpaperContainer? active_wallpaper = null;

    private Cancellable? last_cancellable;

    private static string get_local_bg_location () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds");
    }

    construct {
        bg_settings = new BackgroundSettings ();

        //DBus connection needed in update_wallpaper for
        //passing the wallpaper-information to accountsservice.
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
        wallpaper_view.child_activated.connect (on_child_activated);

        Gtk.TargetEntry e = {"text/uri-list", 0, 0};
        wallpaper_view.drag_data_received.connect (on_drag_data_received);
        Gtk.drag_dest_set (wallpaper_view, Gtk.DestDefaults.ALL, {e}, Gdk.DragAction.COPY);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (wallpaper_view);

        folder_combo = new Gtk.ComboBoxText ();
        folder_combo.margin = 12;
        folder_combo.append ("pic", _("Pictures"));
        folder_combo.append ("sys", _("Backgrounds"));
        folder_combo.append ("cus", _("Custom…"));
        folder_combo.changed.connect (on_folder_combo_changed);
        folder_combo.set_active (1);

        combo = new Gtk.ComboBoxText ();
        combo.valign = Gtk.Align.CENTER;
        combo.append ("centered", _("Centered"));
        combo.append ("zoom", _("Zoom"));
        combo.append ("spanned", _("Spanned"));
        combo.append ("none", _("Solid Color"));
        combo.changed.connect (on_combo_changed);

        color_button = new Gtk.ColorButton ();
        color_button.margin = 12;
        color_button.margin_left = 0;
        color_button.color_set.connect (on_color_set);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (combo);
        size_group.add_widget (color_button);
        size_group.add_widget (folder_combo);

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        actionbar.add (folder_combo);
        actionbar.pack_end (color_button);
        actionbar.pack_end (combo);

        attach (separator, 0, 0, 1, 1);
        attach (scrolled, 0, 1, 1, 1);
        attach (actionbar, 0, 2, 1, 1);

        bg_settings.notify["picture-uri"].connect (on_picture_uri_changed);
        bg_settings.notify["picture-options"].connect (on_picture_options_changed);
        bg_settings.notify["primary-color"].connect (on_primary_color_changed);
        on_picture_options_changed ();
        on_primary_color_changed ();
    }

    /*
     * We pass the path to accountsservices that the login-screen can
     * see what background we selected. This is right now just a patched-in functionality of
     * accountsservice, so we expect that it is maybe not there
     * and do nothing if we encounter a unpatched accountsservices-backend.
    */
    private void set_wallpaper (WallpaperContainer container) {
        var file = File.new_for_uri (container.uri);
        try {
            string uri = file.get_uri ();
            string path = file.get_path ();

            if (!path.has_prefix (SYSTEM_BACKGROUNDS_PATH) && !path.has_prefix (get_local_bg_location ())) {
                var local_file = copy_for_library (file);
                if (local_file != null) {
                    uri = local_file.get_uri ();
                }
            }

            // Update the container's URI to a new one
            container.uri = uri;

            // If the previous wallpaper was a solid color, switch to a default scaling method
            if (bg_settings.picture_options == "none") {
                bg_settings.picture_options = "centered";
            }

            // Set new picture URI
            bg_settings.picture_uri = uri;

            var greeter_file = copy_for_greeter (file);
            if (greeter_file != null) {
                path = greeter_file.get_path ();
            }

            // Set background file for the greeter
            if (accountsservice != null) {
                accountsservice.set_background_file (path);
            }
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void on_child_activated (Gtk.FlowBoxChild child) {
        var container = child as WallpaperContainer;
        if (container == null) {
            return;
        }

        set_wallpaper (container);
    }

    private void on_picture_options_changed () {
        string option = bg_settings.picture_options;
        bool is_solid_color = option == "none";
        combo.active_id = option;

        if (is_solid_color && active_wallpaper != null) {
            select_container (null);
        }
    }

    private void on_primary_color_changed () {
        Gdk.RGBA color = {};
        if (!color.parse (bg_settings.primary_color)) {
            return;
        }

        color_button.rgba = color;
    }

    private void on_picture_uri_changed () {
        string uri = bg_settings.picture_uri;
        foreach (var child in wallpaper_view.get_children ()) {
            var container = child as WallpaperContainer;
            if (container == null) {
                continue;
            }

            if (container.uri == uri) {
                select_container (container);
                break;
            }
        }
    }

    private void on_color_set () {
        bg_settings.picture_options = "none";
        bg_settings.primary_color = color_button.rgba.to_string ();
    }

    private void on_combo_changed () {
        string? active_id = combo.active_id;
        if (active_id == null) {
            return;
        }

        bg_settings.picture_options = active_id;
        if (active_id != "none") {
            on_picture_uri_changed ();
        }
    }

    private void on_folder_combo_changed () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;

        switch (folder_combo.get_active ()) {
            case 0:
                clean_wallpapers ();

                var picture_dir = GLib.File.new_for_path (GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES));
                load_wallpapers.begin (picture_dir.get_uri (), cancellable, (obj, res) => {
                    load_wallpapers.end (res);
                    on_picture_uri_changed ();
                });

                break;
            case 1:
                clean_wallpapers ();

                try {
                    string system_uri = GLib.Filename.to_uri (SYSTEM_BACKGROUNDS_PATH);
                    string user_uri = GLib.File.new_for_path (get_local_bg_location ()).get_uri ();

                    load_wallpapers.begin (system_uri, cancellable);
                    load_wallpapers.begin (user_uri, cancellable, (obj, res) => {
                        load_wallpapers.end (res);
                        on_picture_uri_changed ();
                    });
                } catch (Error e) {
                    warning (e.message);
                }

                break;
            case 2:
                var dialog = new Gtk.FileChooserDialog (_("Select a folder"), null, Gtk.FileChooserAction.SELECT_FOLDER);
                dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
                dialog.add_button (_("Open"), Gtk.ResponseType.ACCEPT);
                dialog.set_default_response (Gtk.ResponseType.ACCEPT);

                if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                    clean_wallpapers ();
                    load_wallpapers.begin (dialog.get_file ().get_uri (), cancellable, (obj, res) => {
                        load_wallpapers.end (res);
                        on_picture_uri_changed ();
                    });

                    dialog.destroy ();
                } else {
                    dialog.destroy ();
                }  

                break;                        
        }
    }

    private void select_container (WallpaperContainer? container) {
        if (active_wallpaper != null) {
            active_wallpaper.checked = false;
            wallpaper_view.unselect_child (active_wallpaper);
        }

        if (container != null) {
            container.checked = true;
            wallpaper_view.select_child (container);
        }

        active_wallpaper = container;
    }

    private async void load_wallpapers (string basefolder, Cancellable? cancellable) {
        folder_combo.sensitive = false;

        var file = File.new_for_uri (basefolder);

        try {
            // Enumerator object that will let us read through the wallpapers asynchronously
            var enumerator = yield file.enumerate_children_async ("%s,%s".printf (FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_CONTENT_TYPE), 0, Priority.DEFAULT);

            FileInfo? info = null;
            while (!cancellable.is_cancelled () && ((info = enumerator.next_file (cancellable)) != null)) {
                if (info.get_file_type () == FileType.DIRECTORY) {
                    var subdir = file.resolve_relative_path (info.get_name ());
                    load_wallpapers.begin (subdir.get_path (), cancellable);
                    continue;
                }

                if (!Utils.is_valid_wallpaper (info)) {
                    continue;
                }

                var subfile = file.resolve_relative_path (info.get_name ());

                string uri = subfile.get_uri ();
                if (uri == null || uri == DEFAULT_LINK) {
                    continue;
                }

                var wallpaper = new WallpaperContainer (uri);
                wallpaper_view.add (wallpaper);
                wallpaper.show_all ();
            }

            folder_combo.sensitive = true;
        } catch (Error err) {
            warning (err.message);
        }
    }

    private void clean_wallpapers () {
        foreach (var child in wallpaper_view.get_children ()) {
            child.destroy ();
        }

        // reduce memory usage and prevent to load old thumbnail
        Cache.clear ();
    }

    private File? copy_for_library (File source) {
        try {
            var dest = File.new_for_path (Path.build_filename (get_local_bg_location (), source.get_basename ()));
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
            return dest;
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    private File? copy_for_greeter (File source) {
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

            var dest = File.new_for_path (Path.build_filename (greeter_data_dir, source.get_basename ()));
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
            return dest;
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    private void on_drag_data_received (Gtk.Widget widget, Gdk.DragContext ctx, int x, int y, Gtk.SelectionData sel, uint information, uint timestamp) {
        if (sel.get_length () > 0) {
            try {
                File file = File.new_for_uri (sel.get_uris ()[0]);
                var info = file.query_info (FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);

                if (!Utils.is_valid_wallpaper (info)) {
                    Gtk.drag_finish (ctx, false, false, timestamp);
                    return;
                }

                string local_uri = file.get_uri ();
                var dest = copy_for_library (file);
                if (dest != null) {
                    local_uri = dest.get_uri ();
                }

                // Add the wallpaper name and thumbnail to the IconView
                var wallpaper = new WallpaperContainer (local_uri);
                wallpaper_view.add (wallpaper);
                wallpaper.show_all ();

                Gtk.drag_finish (ctx, true, false, timestamp);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        } else {
            Gtk.drag_finish (ctx, false, false, timestamp); 
        }
    }
}
