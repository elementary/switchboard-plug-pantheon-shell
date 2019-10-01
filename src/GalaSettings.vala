/*
* Copyright (c) 2018 elementary LLC. (https://elementary.io)
*               2012 GardenGnome, Rico Tzschichholz, Tom Beckmann
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
*/

const string SCHEMA = "org.pantheon.desktop.gala";

public class BehaviorSettings : Granite.Services.Settings {
    public string hotcorner_custom_command { get; set; }

    static BehaviorSettings? instance = null;

    private BehaviorSettings () {
        base (SCHEMA + ".behavior");
    }

    public static BehaviorSettings get_default () {
        if (instance == null) {
            instance = new BehaviorSettings ();
        }

        return instance;
    }
}
