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
 * Authored by: Erasmo Marín
 *
 */

public class PantheonShell.GenericContainer : Gtk.FlowBoxChild {
    public signal void trash ();

    protected const int THUMB_WIDTH = 162;
    protected const int THUMB_HEIGHT = 100;

    private static Gtk.CssProvider check_css_provider;
    private static Gtk.CssProvider move_to_trash_provider;
    private static Gtk.CheckButton check_group; // used for turning CheckButtons into RadioButtons

    protected Gtk.Box card_box;
    protected Gtk.Picture image;
    private Gtk.Revealer check_revealer;
    protected Gtk.Overlay overlay;
    protected Gtk.Box context_menu_box;
    protected Gtk.Popover context_menu;
    protected Gtk.Button move_to_trash_button;

    public bool checked {
        get {
            return check_revealer.reveal_child;
        }
        set {
            check_revealer.reveal_child = value;
            if (value) {
                card_box.set_state_flags (Gtk.StateFlags.CHECKED, false);
            } else {
                card_box.unset_state_flags (Gtk.StateFlags.CHECKED);
            }
        }
    }

    static construct {
        check_css_provider = new Gtk.CssProvider ();
        check_css_provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/Check.css");

        move_to_trash_provider = new Gtk.CssProvider ();
        move_to_trash_provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/RemoveButton.css");

        check_group = new Gtk.CheckButton ();
    }

    construct {
        image = new Gtk.Picture () {
            can_shrink = true,
            keep_aspect_ratio = false
        };

        card_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        card_box.append (image);
        card_box.add_css_class (Granite.STYLE_CLASS_CARD);
        card_box.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var check = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            focusable = false,
            active = true,
            group = check_group
        };
        check.get_style_context ().add_provider (check_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        check_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = check
        };

        overlay = new Gtk.Overlay () {
            child = card_box,
            halign = Gtk.Align.CENTER
        };
        overlay.add_overlay (check_revealer);

        var overlay_event_controller = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY
        };
        overlay.add_controller (overlay_event_controller);

        add_css_class ("wallpaper-container");
        child = overlay;

        // Context menu
        move_to_trash_button = new Gtk.Button () {
            child = new Granite.AccelLabel (_("Remove")),
            sensitive = false
        };
        move_to_trash_button.get_style_context ().add_provider (move_to_trash_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        move_to_trash_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);
        // remove background-color transition so it looks identical to menu item
        move_to_trash_button.add_css_class ("remove-button");

        context_menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 3,
            margin_bottom = 3
        };
        context_menu_box.append (move_to_trash_button);

        context_menu = new Gtk.Popover () {
            child = context_menu_box,
            autohide = true
        };
        context_menu.set_parent (overlay);

        // signals
        check.notify["active"].connect (() => {
            check.active = true;
        });

        overlay_event_controller.pressed.connect ((n_press, x, y) => {
            var rect = Gdk.Rectangle ();
            rect = {(int) x, (int) y, 1, 1};

            context_menu.pointing_to = rect;
            context_menu.popup ();
        });

        move_to_trash_button.clicked.connect (() => trash ());
    }
}
