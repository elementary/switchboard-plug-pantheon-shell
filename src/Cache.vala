// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2014 Foto Developers (http://launchpad.net/foto)
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Erasmo Marín <erasmo.marin@gmail.com>
 */

using Gdk;
using Gdk;
using GLib;
using Gee;

//TODO: Find if the file is older than the cache image (last edition date). If not, refresh thumbnail.

public class Cache {

    static string cache_folder = null;
    static HashMap<string,Pixbuf> images = null;
    static bool cache_folder_exists = false;

    /*
     * Static init of parameters
     */
    public async static void init () {
        if (cache_folder == null)
            cache_folder = Environment.get_user_cache_dir () + "/wallpapers-plug-thumbs/";
        if (images == null) {
            images = new HashMap<string, Pixbuf>();
            GLib.FileInfo file_info = null;
            var image_folder = File.new_for_path (cache_folder);
        }
        if(!cache_folder_exists) {
            create_cache_path (cache_folder);
        }
    }

    /*
     *create a new cache file for the original image path
     */
    public static bool cache_image (string image_path, int width, int height) {
        try {
            Cache.init.begin();
            var pixbuf = new Pixbuf.from_file_at_scale (image_path, width, height, true);
            debug ("Image cached: " + get_cache_path () + compute_key (image_path));
            pixbuf.save (get_cache_path () + compute_key (image_path) , "png");
            images.set(compute_key (image_path), pixbuf);
        } catch (GLib.Error err) {
 	        warning("cache_image failed");
            return false;
        }
        return true;
    }

    /*
     *create a new cache file for the image pixbuf at the same size
     */
    public static bool cache_image_pixbuf (Pixbuf pixbuf, string image_path) {
        try {
            Cache.init.begin();
            pixbuf.save (get_cache_path () + compute_key (image_path) , "png");
            images.set(compute_key (image_path), pixbuf);
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
    public static bool is_cached (string image_path) {
        Cache.init.begin();
        File file = File.new_for_path (get_cache_path () + compute_key (image_path));
        if (!file.query_exists ())
            return false;
        return true;
    }

    /*
     *returns the cached thumbnail
     */
    public static Pixbuf? get_cached_image (string image_path) {
        Cache.init.begin();
        string computed_key = compute_key (image_path);
        if (images.has_key(computed_key))
            return images.get(computed_key);

        Pixbuf pixbuf = null;
        try {
            pixbuf = new Pixbuf.from_file (get_cache_path () + computed_key);
        } catch (GLib.Error err) {
 	        warning("get_cached_image failed");
            return null;
        }
        images.set(computed_key, pixbuf);
        return pixbuf;
    }

    public async static Pixbuf? get_cached_image_async (string image_path) {
        Cache.init.begin();
        string computed_key = compute_key (image_path);
        if (images.has_key(computed_key))
            return images.get(computed_key);
        
        Pixbuf image;
        GLib.File file = GLib.File.new_for_commandline_arg (get_cache_path () + computed_key);
        try {
            GLib.InputStream stream = yield file.read_async ();
            image = yield new Pixbuf.from_stream_async (stream, null);
            images.set(computed_key, image);
            return image;
        } catch (GLib.Error err) {
 	        warning("get_cached_image_async failed with file %s", image_path);
            return null;
        }
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
    * Compute the key from an image path
    */
    private static string compute_key (string image_path) {
        return Checksum.compute_for_string (ChecksumType.MD5, image_path);
    }

    private static string get_cache_path () {
        Cache.init.begin ();
        return cache_folder;
    }
}
