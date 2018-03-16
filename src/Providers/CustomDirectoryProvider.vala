
/**
*
*/
public class CustomDirectoryProvider : DirectoryRepository {

    // private GLib.Settings plug_settings;
    /**
    *
    */
    public SelectableDirectoryProvider () {
        // var plug_settings = new GLib.Settings ("io.elementary.switchboard.plug.desktop");
        base ({ null });
    }

    // current_custom_directory_path = plug_settings.get_string ("current-custom-path");
    //
    // if (saved_id == CUSTOM_DIR_COMBO_ID) {
    //     if (!check_custom_dir_valid (current_custom_directory_path)) {
    //         saved_id = plug_settings.get_default_value ("current-wallpaper-source").get_string ();
    //         current_custom_directory_path = null;
    //     }
    // }

    // var custom_folder_open = new Gtk.Button.from_icon_name ("document-open");
    // custom_folder_open.valign = Gtk.Align.CENTER;
    // custom_folder_open.clicked.connect (() => show_custom_dir_chooser ());
    // custom_folder_button_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
    // custom_folder_button_revealer.add (custom_folder_open);


    //     plug_settings.set_string ("current-custom-path", current_custom_directory_path);

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


}
