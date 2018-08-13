/*-
 * Copyright (c) 2018 elementary, Inc.
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



public class Appearance : Gtk.Grid {
    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var accent_label = new Gtk.Label (_("Accent Color:"));
        accent_label.halign = Gtk.Align.END;

        var transparency_label = new Gtk.Label (_("Transparency:"));
        transparency_label.halign = Gtk.Align.END;

        var animations_label = new Gtk.Label (_("Animations:"));
        animations_label.halign = Gtk.Align.END;

        attach (accent_label,       0, 0);
        attach (transparency_label, 0, 1);
        attach (animations_label,   0, 2);
    }
}
