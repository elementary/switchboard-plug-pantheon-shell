/*-
 * Copyright (c) 2011-2017 elementary LLC. (https://github.com/elementary/switchboard-plug-pantheon-shell/)
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
 * Authored by: Fernando da Silva Sousa
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
