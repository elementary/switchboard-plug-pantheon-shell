using Gdk;
using Gtk;

public class ImageWidget : Gtk.DrawingArea {

    public signal void clicked();
    
    private bool selected = false;
    private bool activated = false;
    private Pixbuf thumb;
    private int thumb_margin = 4;
    private static Pixbuf activated_icon = null;
    private RGBA selected_color;
    private RGBA active_color;

    private static string style= """
                                    *:selected {
                                      background-color: @selected_bg_color;
                                      color: @selected_fg_color;
                                    }

                                    *:active {
                                      background-color: @active_bg_color;;
                                    }""";


    public ImageWidget (Pixbuf thumb) {
        this.thumb = thumb;

        //style
        var item_style_provider = new Gtk.CssProvider ();
        item_style_provider.load_from_data (style, -1);
        get_style_context ().add_provider (item_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);


        //load colors into structs
        selected_color = get_style_context ().get_background_color (StateFlags.SELECTED);
        active_color = get_style_context ().get_background_color (StateFlags.ACTIVE);

        //events
        add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
        this.height_request = thumb.get_height() + 2*thumb_margin;
        this.width_request = thumb.get_width()+ 2*thumb_margin;

        if (activated_icon == null) {
            try {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
                activated_icon = icon_theme.load_icon ("selection-checked", 32, IconLookupFlags.FORCE_SIZE);
            } catch (GLib.Error err) {
     	        warning("Getting selection-checked icon from theme failed");
            }
        }

        button_release_event.connect(on_button_press);
    }

    public bool on_button_press(Gdk.EventButton event) {

        if ( event.button == 1) {
            clicked();
        }
        return false;
    }

    public void set_selected (bool is_selected) {
        this.selected = is_selected;
        queue_draw();
    }

    public void set_activated (bool is_activated) {
         this.activated = is_activated;
         queue_draw();
    }

    public bool get_selected () {
        return selected;
    }

    public bool get_activated () {
        return activated;
    }

    public override bool draw (Cairo.Context cr) {

        int width = (int) (thumb.get_width() + 2*thumb_margin);
        int height = (int) (thumb.get_height() + 2*thumb_margin);

        if (selected) {
            //paint selection background
            cr.set_source_rgba (selected_color.red,selected_color.green,selected_color.blue,1);
            //cr.set_source_rgba (60.0/255,146.0/255,202.0/255,1);
            Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, 0, 0, width, height, 3);
            cr.fill ();
        }

        cr.save ();
        cairo_set_source_pixbuf (cr, thumb, thumb_margin, thumb_margin);
        cr.paint ();

        if (activated) {
            int x = width/2 - activated_icon.get_width()/2;
            int y = height/2 - activated_icon.get_height()/2;
            cairo_set_source_pixbuf (cr, activated_icon, x, y);
            cr.paint ();
        }
        cr.restore ();
        return false;
    }

}
