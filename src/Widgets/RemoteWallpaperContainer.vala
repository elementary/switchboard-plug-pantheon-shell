/*-
 * Copyright (c) 2015-2017 elementary LLC. (https://bugs.launchpad.net/switchboard-plug-pantheon-shell)
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
    private Gtk.Revealer download_revealer;
    private DownloadStatus status;
    private string remote_uri;
    private string _uri;
    private File remote_file;
    private File local_file;

    enum DownloadStatus {
        READY,
        IN_PROGRESS,
        DONE,
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
        // TODO: Change icon
        // var download = new Gtk.Image.from_icon_name ("folder-remote", Gtk.IconSize.LARGE_TOOLBAR);
        download_label = new Gtk.Label ("0%");
        download_label.halign = Gtk.Align.END;
        download_label.valign = Gtk.Align.START;

        download_revealer = new Gtk.Revealer ();
        download_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        download_revealer.add (download_label);
        download_revealer.reveal_child = true;

        overlay.add_overlay (download_revealer);

        remote_file = File.new_for_uri (remote_uri);
        local_file = File.new_for_path (Environment.get_tmp_dir ()+"/"+remote_file.get_basename ());

        status = local_file.query_exists () ? DownloadStatus.DONE : DownloadStatus.READY;

        load_thumb ();
        load_artist_tooltip ();
    }

    File download_file () {
        var loop = new MainLoop();

        if (!local_file.query_exists ()) {
            status = DownloadStatus.IN_PROGRESS;
            remote_file.copy_async.begin (local_file, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA, 1, null, (current, total) => {
                update_download_status ((float) current/(total+1)*100);
                debug ("Downloading "+current.to_string ()+" of "+total.to_string ());
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

    void update_download_status (float percentage) {
        download_label.label = percentage.to_string ()+"%";
    }

    private void load_artist_tooltip () {
        if (artist_name != null) {
            set_tooltip_text (_("Artist: %s").printf (artist_name));
        }
    }

    private async void load_thumb () {
        if (thumb_path == null) {
            return;
        }

        try {
            yield image.set_from_file_async (File.new_for_uri (thumb_path), THUMB_WIDTH, THUMB_HEIGHT, false);
        } catch (Error e) {
            warning (e.message);
        }
    }
}
