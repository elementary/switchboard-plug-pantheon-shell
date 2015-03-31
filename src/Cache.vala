// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2014 Foto Developers (http://launchpad.net/foto)
 * Copyright (c) 2015 Erasmo Marín
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 */

public class Cache {

    static string cache_folder = null;
    static Gee.HashMap<string, Gdk.Pixbuf> images = null;
    static bool cache_folder_exists = false;

    /*
     * Static init of parameters
     */
    public async static void init () {
        if (cache_folder == null)
            cache_folder = Environment.get_user_cache_dir () + "/wallpapers-plug-thumbs/";
        if (images == null) {
            images = new Gee.HashMap<string, Gdk.Pixbuf>();
        }
        if(!cache_folder_exists) {
            create_cache_path (cache_folder);
        }
    }

    /*
     *create a new cache file for the original image path
     */
    public static bool cache_image (string uri, int width, int height) {
        try {
            Cache.init.begin();
            var pixbuf = new Gdk.Pixbuf.from_file_at_scale (uri, width, height, true);
            debug ("Image cached: " + get_cache_path () + compute_key (uri));
            pixbuf.save (get_cache_path () + compute_key (uri) , "png");
            images.set(compute_key (uri), pixbuf);
        } catch (GLib.Error err) {
 	        warning("cache_image failed");
            return false;
        }
        return true;
    }

    /*
     *create a new cache file for the image pixbuf at the same size
     */
    public static bool cache_image_pixbuf (Gdk.Pixbuf pixbuf, string uri) {
        try {
            Cache.init.begin();
            pixbuf.save (get_cache_path () + compute_key (uri) , "png");
            images.set(compute_key (uri), pixbuf);
        } catch (GLib.Error err) {
            print(err.message);
 	        warning("cache_image_pixbuf failed");
            return false;
        }
        return true;
    }


    /*
     *Determine if a image is cached
     */
    public static bool is_cached (string uri) {
        Cache.init.begin();
        File file = File.new_for_path (get_cache_path () + compute_key (uri));
        if (!file.query_exists ())
            return false;
        return true;
    }

    /*
     *returns the cached thumbnail
     */
    public static Gdk.Pixbuf? get_cached_image (string uri) {
        Cache.init.begin();
        string computed_key = compute_key (uri);
        if (images.has_key(computed_key))
            return images.get(computed_key);

        Gdk.Pixbuf pixbuf = null;
        try {
            pixbuf = new Gdk.Pixbuf.from_file (get_cache_path () + computed_key);
        } catch (GLib.Error err) {
 	        warning("get_cached_image failed");
            return null;
        }
        images.set(computed_key, pixbuf);
        return pixbuf;
    }

    public static void clear () {
        images.clear();
    }

    private static void create_cache_path (string cache_path) {
        var dir = GLib.File.new_for_path (cache_path);

        if (!dir.query_exists (null)) {
            try {
                dir.make_directory_with_parents (null);
                GLib.debug ("Directory '%s' created", dir.get_path ());
            } catch (Error e) {
                GLib.error ("Could not create caching directory.");
            }
        }
    }

    /*
     * Compute the key from the uri and the modification date in this format:
     * [uri key]_[mod_key]
     */
    private static string compute_key (string uri) {
        string key = compute_key_uri (uri) + "_" + compute_key_mod (uri);
        return key;
    }

    /*
     *compute a key with the uri
     */
    private static string compute_key_uri (string uri) {
        string key_uri = GLib.Checksum.compute_for_string (ChecksumType.MD5, uri);
        return key_uri;
    }

    /*
     *compute a key with the modification date
     */
    private static string compute_key_mod (string uri) {
        GLib.File file = GLib.File.new_for_uri (uri);
        FileInfo info = file.query_info (GLib.FileAttribute.TIME_MODIFIED, 0);
        string key_mod = GLib.Checksum.compute_for_string (GLib.ChecksumType.MD5, 
                                                      info.get_modification_time().tv_sec.to_string());
        return key_mod;
    }

    private static string get_cache_path () {
        Cache.init.begin ();
        return cache_folder;
    }
}
