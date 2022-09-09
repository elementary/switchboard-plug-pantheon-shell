/*-
 * Copyright 2022 elementary, Inc. (https://elementary.io)
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

public class PantheonShell.XMLContainer : UriContainer {
    public XMLContainer (string uri) {
        Object (uri: uri);
    }

    construct {
        // FIXME: https://github.com/elementary/switchboard-plug-pantheon-shell/issues/296
        // parse_file ();
        // create_collage ();
        // create_overlay_icon ();
        // add_tooltip ();
        // ...
    }
}
