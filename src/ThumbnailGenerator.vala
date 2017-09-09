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
    public abstract void dequeue (uint32 handle) throws IOError;
}

public class ThumbnailGenerator {
    private const string THUMBNAILER_DBUS_ID = "org.freedesktop.thumbnails.Thumbnailer1";
    private const string THUMBNAILER_DBUS_PATH = "/org/freedesktop/thumbnails/Thumbnailer1";

    public delegate void ThumbnailReady ();
    public class ThumbnailReadyWrapper {
        public ThumbnailReady cb;
    }

    private static ThumbnailGenerator? instance = null;
    private Thumbnailer? thumbnailer = null;
    private Gee.HashMap<string, ThumbnailReadyWrapper> queued_delegates = new Gee.HashMap<string, ThumbnailReadyWrapper> ();
    private Gee.ArrayList<uint32> handles = new Gee.ArrayList<uint32> ();

    public static ThumbnailGenerator get_default () {
        if (instance == null) {
            instance = new ThumbnailGenerator ();
        }

        return instance;
    }

    public ThumbnailGenerator () {
        try {
            var to_remove = new Gee.ArrayList<string> ();
            thumbnailer = Bus.get_proxy_sync (BusType.SESSION, THUMBNAILER_DBUS_ID, THUMBNAILER_DBUS_PATH);
            thumbnailer.ready.connect ((handle, uris) => {
                foreach (var uri in uris) {
                    if (queued_delegates.has_key (uri)) {
                        var wrapper = queued_delegates [uri];
                        wrapper.cb ();
                        to_remove.add (uri);
                        handles.remove (handle);
                    }
                }

                foreach (var key in to_remove) {
                    queued_delegates.unset (key);
                }
            });
        } catch (Error e) {
            warning ("Unable to connect to system thumbnailer: %s", e.message);
        }
    }

    public void dequeue_all () {
        foreach (var handle in handles) {
            try {
                thumbnailer.dequeue (handle);
            } catch (IOError e) {
                warning ("Unable to tell thumbnailer to stop creating thumbnails: %s", e.message);
            }
        }
    }

    public void get_thumbnail (string uri, uint size, ThumbnailReady callback) {
        string thumb_size = "normal";

        if (size > 128) {
            thumb_size = "large";
        }

        if (thumbnailer != null) {
            var wrapper = new ThumbnailReadyWrapper ();
            wrapper.cb = callback;

            try {
                var handle = thumbnailer.queue ({ uri }, { get_mime_type (uri) }, thumb_size, "default", 0);
                handles.add (handle);
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
}
