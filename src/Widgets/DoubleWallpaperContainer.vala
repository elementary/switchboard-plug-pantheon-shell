/*-
 * Copyright 2023 elementary, Inc.
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
 */

public class PantheonShell.DoubleWallpaperContainer : WallpaperContainer {
    public string picture_path { get; construct; }
    public string picture_dark_path { get; construct; }

    public DoubleWallpaperContainer (string picture_path, string picture_dark_path) {
        Object (
            picture_path: picture_path,
            picture_dark_path: picture_dark_path
        );
    }

    construct {
        var picture_pixbuf = new Gdk.Pixbuf.from_file_at_scale (picture_path, THUMB_WIDTH, THUMB_HEIGHT, false);
        var picture_dark_pixbuf = new Gdk.Pixbuf.from_file_at_scale (picture_dark_path, THUMB_WIDTH, THUMB_HEIGHT, false);

        picture_dark_pixbuf.copy_area (THUMB_WIDTH / 2, 0, THUMB_WIDTH / 2, THUMB_HEIGHT, picture_pixbuf, THUMB_WIDTH / 2, 0);

        image.gicon = picture_pixbuf;
    }
}
