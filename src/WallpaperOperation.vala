/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 */

namespace PantheonShell.WallpaperOperation {
    public static string get_local_bg_directory () {
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

    public static string[] get_bg_directories () {
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

    private static File ensure_local_bg_exists () {
        var folder = File.new_for_path (get_local_bg_directory ());
        if (!folder.query_exists ()) {
            try {
                folder.make_directory_with_parents ();
            } catch (Error e) {
                warning (e.message);
            }
        }

        return folder;
    }

    public static File? copy_for_library (File source) {
        File? dest = null;

        try {
            var timestamp = new DateTime.now_local ().format ("%Y-%m-%d-%H-%M-%S");
            var filename = "%s-%s".printf (timestamp, source.get_basename ());
            dest = ensure_local_bg_exists ().get_child (filename);
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning (e.message);
        }

        return dest;
    }
}
