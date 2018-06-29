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

public class RemoteWallpaperContainer : AbstractWallpaperContainer {
    private Gtk.Label download_label;
    private Gtk.Stack stack;
    private Gtk.Widget ready;
    private Gtk.Box in_progress;
    private Gtk.Revealer revealer;

    private string remote_uri;
    private File remote_file;
    private File local_file;

    private string _uri;
    private DownloadStatus _status;

    private enum DownloadStatus {
        READY,
        IN_PROGRESS,
        DONE,
    }

    private DownloadStatus status {
        get {
            return _status;
        }
        set {
            _status = value;
            update ();
        }
    }

    public override string? uri {
        get {
            if (_uri == null) {
                _uri = download_file ().get_uri ();
            }
            return _uri;
        }
        construct {
            remote_uri = value;
        }
    }

    public string? artist_name {get;construct set;}

    public RemoteWallpaperContainer (string uri, string? thumb_path, string? artist_name) {
        Object (uri: uri, thumb_path: thumb_path, artist_name: artist_name);
    }

    construct {
        ready = new Gtk.Image.from_icon_name ("go-bottom", Gtk.IconSize.LARGE_TOOLBAR);
        ready.halign = Gtk.Align.END;
        ready.valign = Gtk.Align.START;

        var spinner = new Gtk.Spinner ();
        spinner.start ();

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        layout.expand = layout.vexpand = true;
        layout.halign = layout.valign = Gtk.Align.CENTER;
        layout.add (spinner);

        in_progress = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        in_progress.get_style_context ().add_class ("background");
        in_progress.opacity = 0.7;
        in_progress.add (layout);

        stack = new Gtk.Stack ();
        stack.add_named (ready, DownloadStatus.READY.to_string ());
        stack.add_named (in_progress, DownloadStatus.IN_PROGRESS.to_string ());

        revealer = new Gtk.Revealer ();
        revealer.add (stack);

        overlay.add_overlay (revealer);

        remote_file = File.new_for_uri (remote_uri);
        local_file = File.new_for_path (Environment.get_tmp_dir ()+"/"+remote_file.get_basename ());
        status = local_file.query_exists () ? DownloadStatus.DONE : DownloadStatus.READY;

        load_thumb ();
        load_artist_tooltip ();
    }

    // TODO: Make download_file async
    File download_file () {
        var loop = new MainLoop();

        if (!local_file.query_exists ()) {
            status = DownloadStatus.IN_PROGRESS;
            remote_file.copy_async.begin (local_file, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA, 1, null, (current, total) => {
                debug (@"Downloading $(current.to_string ()) of $(total.to_string ())");
            }, (obj, res) => {
                try {
                    status = remote_file.copy_async.end (res) ? DownloadStatus.DONE : DownloadStatus.READY;
                } catch (Error e) {
                    warning ("Error: "+e.message);
                }

                loop.quit ();
            });
            loop.run();
        }

        return local_file;
    }

    void update () {
        revealer.reveal_child = !status == DownloadStatus.DONE;

        if (status != DownloadStatus.DONE) {
            stack.visible_child_name = status.to_string ();
        }
    }

    private void load_artist_tooltip () {
        if (artist_name != null) {
            set_tooltip_text (_("Artist: %s").printf (artist_name));
        }
    }

    private async void load_thumb () {
        if (thumb_path == null && remote_file == null) {
            return;
        }

        try {
            var file = status == DownloadStatus.DONE ? local_file : File.new_for_uri (thumb_path);
            yield image.set_from_file_async (file, THUMB_WIDTH, THUMB_HEIGHT, false);
        } catch (Error e) {
            warning (e.message);
        }
    }
}
