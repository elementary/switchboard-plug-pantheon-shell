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

public class PantheonShell.UriContainer : GenericContainer {
    public string uri { get; construct; }

    public uint64 creation_date { get; set; default = 0; } // in unix time

    public UriContainer (string uri) {
        Object (uri: uri);
    }

    construct {
        var file = File.new_for_uri (uri);
        try {
            var info = file.query_info (FileAttribute.TIME_CREATED, FileQueryInfoFlags.NONE);
            creation_date = info.get_attribute_uint64 (GLib.FileAttribute.TIME_CREATED);
        } catch (Error e) {
            critical (e.message);
        }
    }
}
