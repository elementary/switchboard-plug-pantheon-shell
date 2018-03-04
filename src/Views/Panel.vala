/*
* Copyright (c) 2018 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

public class Panel : Gtk.Grid {
    public Panel () {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var transparency_switch = new Gtk.Switch ();
        transparency_switch.halign = Gtk.Align.START;
        transparency_switch.valign = Gtk.Align.CENTER;

        var transparency_label = new Gtk.Label (_("Transparency:"));
        transparency_label.halign = Gtk.Align.END;

        attach (transparency_label,  0, 0, 1, 1);
        attach (transparency_switch, 1, 0, 1, 1);
    }
}
