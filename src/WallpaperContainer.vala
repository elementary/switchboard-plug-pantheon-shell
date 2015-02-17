// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Erasmo Marín
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 */

public class WallpaperContainer : Gtk.FlowBoxChild {
    
    public string uri { get; construct; }
    private Gdk.Pixbuf thumb;
    private int thumb_margin = 3;
    private static Gdk.Pixbuf checked_icon = null;
    private Gdk.RGBA selected_color;

    private static string style_str = """GtkFlowBoxChild:selected {
                                               background-color: @selected_bg_color;
                                               color: @selected_fg_color;
                                           }""";

    public WallpaperContainer (string uri) {

        Object (uri: uri);

        try {
            if(Cache.is_cached (uri)) {
                this.thumb = Cache.get_cached_image (uri);
            } else {
                this.thumb = new Gdk.Pixbuf.from_file_at_scale (GLib.Filename.from_uri (uri), 150, 100, false);
                Cache.cache_image_pixbuf (thumb, uri);
            }
        } catch (Error e) {
            warning ("Failed to load wallpaper thumbnail: %s", e.message);
        }

        //style
        try {
            var item_style_provider = new Gtk.CssProvider ();
            item_style_provider.load_from_data (style_str, -1);
            get_style_context ().add_provider (item_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (GLib.Error err) {
 	        warning("Loading style failed");
        }


        //load selected color
        selected_color = get_style_context ().get_background_color (Gtk.StateFlags.SELECTED);

        this.height_request = thumb.get_height() + 2*thumb_margin;
        this.width_request = thumb.get_width()+ 2*thumb_margin;

        if (checked_icon == null) {
            try {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
                checked_icon = icon_theme.load_icon ("selection-checked", 32, Gtk.IconLookupFlags.FORCE_SIZE);
            } catch (GLib.Error err) {
     	        warning ("Getting selection-checked icon from theme failed");
            }
        }

        activate.connect (() => {
            set_checked (true);
        });
    }

    public void set_selected (bool is_selected) {
         if (is_selected) {
            set_state_flags ( get_state_flags() | Gtk.StateFlags.SELECTED, false);
         } else {
            unset_state_flags (Gtk.StateFlags.SELECTED);
         }
         queue_draw ();
    }

    public void set_checked (bool is_checked) {
         if (is_checked) {
            set_state_flags ( get_state_flags() | Gtk.StateFlags.CHECKED, false);
         } else {
            unset_state_flags (Gtk.StateFlags.CHECKED);
         }
         queue_draw ();
    }

    public bool get_selected () {
        return ((get_state_flags () & Gtk.StateFlags.SELECTED) == Gtk.StateFlags.SELECTED);
    }

    public bool get_checked () {
        return ((get_state_flags () & Gtk.StateFlags.CHECKED) == Gtk.StateFlags.CHECKED );
    }

    public override bool draw (Cairo.Context cr) {

        int width = (int) (thumb.get_width() + 2*thumb_margin);
        int height = (int) (thumb.get_height() + 2*thumb_margin);

        if ((get_state_flags () & Gtk.StateFlags.SELECTED) == Gtk.StateFlags.SELECTED) {
            //paint selection background
            cr.set_source_rgba (selected_color.red, selected_color.green, selected_color.blue, selected_color.alpha);
            Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, 0, 0, width, height, 3);
            cr.fill ();
        }

        cr.save ();
        Gdk.cairo_set_source_pixbuf (cr, thumb, thumb_margin, thumb_margin);
        cr.paint ();

        if ((get_state_flags () & Gtk.StateFlags.CHECKED) == Gtk.StateFlags.CHECKED) {
            Gdk.cairo_set_source_pixbuf (cr, checked_icon, thumb_margin, thumb_margin);
            cr.paint ();
        }

        cr.restore ();
        return true;
    }

}

