//  
//  Copyright (C) 2011 Tom Beckmann
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 

class LLabel : Gtk.Label
{
    public LLabel (string label)
    {
        this.set_halign (Gtk.Align.START);
        this.label = label;
    }
    public LLabel.indent (string label) 
    {
        this (label);
        this.margin_left = 10;
    }
    public LLabel.markup (string label) 
    {
        this (label);
        this.use_markup = true;
    }
    public LLabel.right (string label) 
    {
        this.set_halign (Gtk.Align.END);
        this.label = label;
    }
    public LLabel.right_with_markup (string label)
    {
        this.set_halign (Gtk.Align.END);
        this.use_markup = true;
        this.label = label;
    }
}

public class GalaPlug : Pantheon.Switchboard.Plug
{
    
    public GalaPlug ()
    {
        
        var notebook = new Granite.Widgets.StaticNotebook (false);
        notebook.set_margin_top (12);
        
        /*wallpaper*/
        var wallpaper = new Wallpaper (this);
        notebook.append_page (wallpaper, new Gtk.Label (_("Wallpaper")));
        switchboard_controller.progress_bar_set_visible (true);
        
        /*dock*/
        var dock_grid = new Gtk.Grid ();
        dock_grid.column_spacing = 12;
        dock_grid.row_spacing = 6;
        dock_grid.margin = 24;
        dock_grid.column_homogeneous = true;

        var icon_size = new Gtk.ComboBoxText ();
        icon_size.append ("32", _("Small"));
        icon_size.append ("48", _("Medium"));
        icon_size.append ("64", _("Large"));
        icon_size.append ("128", _("Extra Large"));
        
        var current = PlankSettings.get_default ().icon_size;
        
        if (current != 32 && current != 48 && current != 64 && current != 128)
            icon_size.append (current.to_string (), _(@"Custom ($(current)px)" ));
        
        icon_size.active_id = current.to_string ();
        icon_size.changed.connect (() => PlankSettings.get_default ().icon_size = int.parse (icon_size.active_id));
        icon_size.halign = Gtk.Align.START;
        icon_size.width_request = 164;

        var hide_mode = new Gtk.ComboBoxText ();
        hide_mode.append ("0", _("Don't hide"));
        hide_mode.append ("1", _("Intelligent hide"));
        hide_mode.append ("2", _("Auto hide"));
        hide_mode.append ("3", _("Hide on maximize"));
        hide_mode.active_id = PlankSettings.get_default ().hide_mode.to_string ();
        hide_mode.changed.connect (() => PlankSettings.get_default ().hide_mode = int.parse (hide_mode.active_id));
        hide_mode.halign = Gtk.Align.START;
        hide_mode.width_request = 164;
        
        
        var theme = new Gtk.ComboBoxText ();

        int theme_index = 0;
        try {
            
            string name;
            var dirs = Environment.get_system_data_dirs ();
            dirs += Environment.get_user_data_dir ();

            foreach (string dir in dirs) {
                if (FileUtils.test (dir + "/plank/themes", FileTest.EXISTS)) {
                    var d = Dir.open(dir + "/plank/themes");
                    while ((name = d.read_name()) != null) {
                        theme.append(theme_index.to_string (), _(name));
                        if (PlankSettings.get_default ().theme.to_string () == name)
                            theme.active = theme_index;
                        theme_index++;
                    }
                }
            }
        } catch (GLib.FileError e){
            warning (e.message);
        }

        theme.changed.connect (() => PlankSettings.get_default ().theme = theme.get_active_text ());
        theme.halign = Gtk.Align.START;
        theme.width_request = 164;
        
        var monitor = new Gtk.ComboBoxText ();
        monitor.append ("-1", _("Primary Monitor"));
        int i = 0;
        for (i = 0; i < Gdk.Screen.get_default ().get_n_monitors () ; i ++) {
            monitor.append ( (i).to_string (), _("Monitor %d").printf (i+1) );
        }
        monitor.active_id = PlankSettings.get_default ().monitor.to_string ();
        monitor.changed.connect (() => PlankSettings.get_default ().monitor = int.parse (monitor.active_id));
        monitor.halign = Gtk.Align.START;
        monitor.width_request = 164;
        
        dock_grid.attach (new LLabel.right (_("Icon Size:")), 0, 0, 2, 1);
        dock_grid.attach (icon_size, 2, 0, 1, 1);
        dock_grid.attach (new LLabel.right (_("Hide Mode:")), 0, 1, 2, 1);
        dock_grid.attach (hide_mode, 2, 1, 2, 1);

        if (theme_index > 1) {
            dock_grid.attach (new LLabel.right (_("Theme:")), 0, 2, 2, 1);
            dock_grid.attach (theme, 2, 2, 1, 1);
        }
        if (i > 1) {
            dock_grid.attach (new LLabel.right (_("Monitor:")), 0, 3, 2, 1);
            dock_grid.attach (monitor, 2, 3, 1, 1);
        }
        
        notebook.append_page (dock_grid, new Gtk.Label (_("Dock")));
        
        /*hot corners*/
        var hotc_grid = new Gtk.Grid ();
        hotc_grid.column_spacing = 12;
        hotc_grid.margin = 32;
        hotc_grid.margin_top = 50;
        
        var expl = new LLabel (_("When the cursor enters the corner of the display:"));
        expl.margin_bottom = 10;
        expl.set_hexpand (true);
        
        var topleft = create_hotcorner ();
        topleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topleft").to_string ();
        topleft.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-topleft", int.parse (topleft.active_id)));
        topleft.valign = Gtk.Align.START;
        var topright = create_hotcorner ();
        topright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topright").to_string ();
        topright.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-topright", int.parse (topright.active_id)));
        topright.valign = Gtk.Align.START;
        var bottomleft = create_hotcorner ();
        bottomleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomleft").to_string ();
        bottomleft.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-bottomleft", int.parse (bottomleft.active_id)));
        bottomleft.valign = Gtk.Align.END;
        var bottomright = create_hotcorner ();
        bottomright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomright").to_string ();
        bottomright.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-bottomright", int.parse (bottomright.active_id)));
        bottomright.valign = Gtk.Align.END;
        
        var icon = new Gtk.Image.from_file (Constants.PKGDATADIR + "/hotcornerdisplay.png");
        var custom_command = new Gtk.Entry ();
        custom_command.text = BehaviorSettings.get_default ().hotcorner_custom_command;
        custom_command.changed.connect (() => BehaviorSettings.get_default ().hotcorner_custom_command = custom_command.text );
        
        var cc_grid = new Gtk.Grid ();
        cc_grid.set_column_spacing (12);
        cc_grid.set_margin_top (6);
        cc_grid.attach (new LLabel (_("Custom Command:")), 0, 0, 1, 1);
        cc_grid.attach (custom_command, 1, 0, 1, 1);
        
        
        hotc_grid.attach (expl, 0, 0, 3, 1);
        hotc_grid.attach (icon, 1, 1, 1, 3);
        hotc_grid.attach (topleft, 0, 1, 1, 1);
        hotc_grid.attach (topright, 2, 1, 1, 1);
        hotc_grid.attach (bottomleft, 0, 3, 1, 1);
        hotc_grid.attach (bottomright, 2, 3, 1, 1);
        hotc_grid.attach (cc_grid, 0, 4, 2, 1);
        
        notebook.append_page (hotc_grid, new Gtk.Label (_("Hot Corners")));
        
        
        add (notebook);
        
        notebook.page_changed.connect ((page) => {
            if (page == 0 && !wallpaper.finished) {
                switchboard_controller.progress_bar_set_visible (true);
            } else {
                switchboard_controller.progress_bar_set_visible (false);
            }
        });
    }
    
    Gtk.ComboBoxText create_hotcorner () {
        var box = new Gtk.ComboBoxText ();
        box.append ("0", _("Do Nothing"));
        box.append ("1", _("Workspace Overview"));
        box.append ("2", _("Maximize Current Window"));
        box.append ("3", _("Minimize Current Window"));
        box.append ("4", _("Show Apps"));
        box.append ("6", _("Window Overview"));
        box.append ("7", _("Show All Windows"));
        box.append ("5", _("Execute Custom Command"));
        
        return box;
    }
}

public static int main (string[] args) {

    Gtk.init (ref args);
    
    var plug = new GalaPlug ();
    plug.register ("Effects");
    plug.show_all ();
    
    Gtk.main ();
    return 0;
}

public static void translations () {
    string desktop_name = _("Desktop");
}
