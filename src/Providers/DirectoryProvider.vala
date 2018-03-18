
/**
 *
 */
public class DirectoryProvider : GLib.Object, IProvider {
    string[] dirs;
    public Cancellable cancellable {get;set;}

    public DirectoryProvider (string dir) {
        dirs += dir;
    }

    public DirectoryProvider.multiple (string[] _dirs) {
        dirs = _dirs;
    }

    public async WallpaperContainer[]? get_containers () {
        WallpaperContainer[] images = null;
        foreach (var dir in dirs) {
            var img = yield load_wallpapers (dir, cancellable, false);
            foreach (var i in img) {
                images += i;
            }
        }
        return images;
    }

    private async WallpaperContainer[]? load_wallpapers (string basefolder, Cancellable cancellable, bool toplevel_folder = true) {
        WallpaperContainer[] images = null;

        if (cancellable.is_cancelled ()) {
            return null;
        }

        var directory = File.new_for_uri (basefolder);

        try {
            // Enumerator object that will let us read through the wallpapers asynchronously
            var attrs = string.joinv (",", IOHelper.REQUIRED_FILE_ATTRS);
            var e = yield directory.enumerate_children_async (attrs, 0, Priority.DEFAULT);
            FileInfo file_info;

            // Loop through and add each wallpaper in the batch
            while ((file_info = e.next_file ()) != null) {
                if (cancellable.is_cancelled ()) {
                    ThumbnailGenerator.get_default ().dequeue_all ();
                    return null;
                }

                if (file_info.get_is_hidden () || file_info.get_is_backup ()) {
                    continue;
                }

                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    // Spawn off another loader for the subdirectory
                    var subdir = directory.resolve_relative_path (file_info.get_name ());
                    var img = yield load_wallpapers (subdir.get_path (), cancellable, false);
                    foreach (var i in img) {
                        images += i;
                    }
                    continue;
                } else if (!IOHelper.is_valid_file_type (file_info)) {
                    // Skip non-picture files
                    continue;
                }

                var file = directory.resolve_relative_path (file_info.get_name ());
                string uri = file.get_uri ();

                // Skip the default_wallpaper as seen in the description of the
                // default_link variable
                // if (uri == DEFAULT_LINK) {
                //     continue;
                // }

                var thumb_path = file_info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
                var thumb_valid = file_info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
                images += new WallpaperContainer (uri, thumb_path, thumb_valid);
            }
        } catch (Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning (err.message);
            }
        }

        return images;
    }

    public void set_directory (string path) {
        dirs = {path};
    }
}
