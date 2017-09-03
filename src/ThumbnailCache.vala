/*
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
interface Thumbnailer : Object {
    public signal void ready (uint32 handle, string[] uris);

    public abstract uint32 queue (string[] uris, string [] mime_types, string flavor, string scheduler, uint32 dequeue) throws IOError;
}

public class Cache {

    private const string PNG_MTIME_KEY = "Thumb::MTime";
    private const string PNG_URL_KEY = "Thumb::URI";

    private const string THUMBNAILER_DBUS_ID = "org.freedesktop.thumbnails.Thumbnailer1";
    private const string THUMBNAILER_DBUS_PATH = "/org/freedesktop/thumbnails/Thumbnailer1";

    public delegate void ThumbnailReady (string thumb_uri);
    public class ThumbnailReadyWrapper {
        public string size;
        public ThumbnailReady cb;
    }

    private static Cache? instance = null;
    private Thumbnailer? thumbnailer = null;
    private Gee.HashMap<string, ThumbnailReadyWrapper> queued_delegates = new Gee.HashMap<string, ThumbnailReadyWrapper> ();

    public static Cache get_default () {
        if (instance == null) {
            instance = new Cache ();
        }

        return instance;
    }

    public Cache () {
        try {
            thumbnailer = Bus.get_proxy_sync (BusType.SESSION, THUMBNAILER_DBUS_ID, THUMBNAILER_DBUS_PATH);
            thumbnailer.ready.connect ((handle, uris) => {
                foreach (var uri in uris) {
                    if (queued_delegates.has_key (uri)) {
                        var wrapper = queued_delegates [uri];
                        wrapper.cb (try_get_thumbnail (uri, wrapper.size));
                    }
                }
            });
        } catch (Error e) {
            warning ("Unable to connect to system thumbnailer: %s", e.message);
        }
    }

    public void get_thumbnail (string uri, uint size, ThumbnailReady callback) {
        string thumb_size = "normal";

        if (size > 128) {
            thumb_size = "large";
        }

        var thumb = try_get_thumbnail (uri, thumb_size);
        if (thumb != null) {
            callback (thumb);
        }

        if (thumbnailer != null) {
            var wrapper = new ThumbnailReadyWrapper ();
            wrapper.cb = callback;
            wrapper.size = thumb_size;

            try {
                thumbnailer.queue ({ uri }, { get_mime_type (uri) }, thumb_size, "default", 0);
                queued_delegates.@set (uri, wrapper);
            } catch (IOError e) {
                warning ("Unable to queue thumbnail generation for '%s': %s", uri, e.message);
            }
        }
    }

    private string get_mime_type (string uri) {
        try {
            return ContentType.guess (Filename.from_uri (uri), null, null);
        } catch (ConvertError e) {
            warning ("Error converting filename '%s' while guessing mime type: %s", uri, e.message);
            return "";
        }
    }

    private string? try_get_thumbnail (string uri, string size) {
        var file = File.new_for_uri (uri);
        long mtime = 0;
        try {
            var info = file.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
            mtime = info.get_modification_time ().tv_sec;
        } catch (Error e) {
            warning ("Unable to get modification time of %s to check thumbnail validity: %s", uri, e.message);
            return null;
        }

        var thumb_path = build_thumbnail_path (uri, size);
        var thumb_file = File.new_for_path (thumb_path);
        if (thumb_file.query_exists ()) {
            if (thumb_file.get_uri () == uri) {
                return uri;
            } else if (is_thumbnail_valid (uri, thumb_path, mtime)) {
                return thumb_file.get_uri ();
            }
        }

        return null;
    }

    private bool is_thumbnail_valid (string uri, string thumb_path, long mtime) {
        PngReader png_reader;
        try {
            png_reader = new PngReader (thumb_path);
        } catch (Error e) {
            warning (e.message);
            return false;
        }

        if (png_reader.metadata[PNG_MTIME_KEY] == mtime.to_string () &&
            png_reader.metadata[PNG_URL_KEY] == uri) {
            return true;
        }

        return false;
    }

    private string build_thumbnail_path (string uri, string size) {
        var base_path = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), "thumbnails");
        var prefix = Path.build_path (Path.DIR_SEPARATOR_S, base_path, size);

        var hash = Checksum.compute_for_string (ChecksumType.MD5, uri);
        return Path.build_path (Path.DIR_SEPARATOR_S, prefix, "%s.png".printf (hash));
    }
}
