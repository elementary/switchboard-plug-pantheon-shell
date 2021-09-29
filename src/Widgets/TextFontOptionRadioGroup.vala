/*-
 * Copyright (c) 2021 Justin Haygood
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

public class PantheonShell.TextFontOptionRadioGroup : Gtk.Grid {
    public delegate void FontOptionsCallback (Cairo.FontOptions font_options);
    public signal void changed ();

    private Gee.List<Gtk.RadioButton> radio_buttons;

    public TextFontOptionRadioGroup () {
        Object (
            halign: Gtk.Align.START,
            column_spacing: 12
        );

        radio_buttons = new Gee.ArrayList<Gtk.RadioButton> ();
    }

    public void append_option (string label, FontOptionsCallback font_options_callback) {
        Gtk.RadioButton radio_button;

        if (radio_buttons.size == 0) {
            radio_button = new Gtk.RadioButton (null) {
                halign = Gtk.Align.START
            };
        } else {
            radio_button = new Gtk.RadioButton.from_widget (radio_buttons.first ()) {
                halign = Gtk.Align.START
            };
        }

        radio_buttons.add (radio_button);

        var radio_button_label = new Gtk.Label (label);
        radio_button.add (radio_button_label);

        var label_font_options = new Cairo.FontOptions ();

        font_options_callback (label_font_options);

        radio_button_label.set_font_options (label_font_options);

        add (radio_button);

        radio_button.toggled.connect (() => {
            changed ();
        });
    }

    public int selected {
        get {
            for (var i = 0; i < radio_buttons.size; i++) {
                if (radio_buttons[i].active) {
                    return i;
                }
            }

            return -1;
        }

        set {
            set_active (value);
        }
    }

    public void set_active (int new_active_index) {
        radio_buttons[new_active_index].active = true;
    }
}
