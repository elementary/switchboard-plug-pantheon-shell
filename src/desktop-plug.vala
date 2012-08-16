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
		notebook.margin = 12;
		
		/*dock*/
		var dock_grid = new Gtk.Grid ();
		
		var icon_size_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		
		Gtk.Scale icon_size_range = null;
		var icon_size = new Gtk.SpinButton.with_range (32, 96, 1);
		icon_size.set_value (PlankSettings.get_default ().icon_size);
		icon_size.value_changed.connect (() => {
			PlankSettings.get_default ().icon_size = (int)icon_size.get_value ();
			icon_size_range.set_value (icon_size.get_value ());
		});
		icon_size.halign = Gtk.Align.START;
		
		icon_size_range = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 32, 96, 1);
		icon_size_range.set_value (PlankSettings.get_default ().icon_size);
		icon_size_range.button_release_event.connect (() => {icon_size.value = icon_size_range.get_value (); return false;});
		icon_size_range.draw_value = false;
		
		icon_size_box.pack_start (icon_size_range, true);
		icon_size_box.pack_start (icon_size, false);
		
		var hide_mode = new Gtk.ComboBoxText ();
		hide_mode.append ("0", _("Don't hide"));
		hide_mode.append ("1", _("Intelligent hide"));
		hide_mode.append ("2", _("Auto hide"));
		hide_mode.append ("3", _("Hide on maximize"));
		hide_mode.active_id = PlankSettings.get_default ().hide_mode.to_string ();
		hide_mode.changed.connect (() => PlankSettings.get_default ().hide_mode = int.parse (hide_mode.active_id));
		hide_mode.halign = Gtk.Align.START;
		hide_mode.width_request = 164;
		
		var monitor = new Gtk.ComboBoxText ();
		int i;
		for (i=0;i<Gdk.Screen.get_default ().get_n_monitors ();i ++)
			monitor.append ((i+1).to_string (), _("Monitor")+" "+(i+1).to_string ());
		monitor.active_id = (PlankSettings.get_default ().monitor+1).to_string ();
		monitor.changed.connect (() => PlankSettings.get_default ().monitor = int.parse (monitor.active_id));
		monitor.halign = Gtk.Align.START;
		monitor.width_request = 164;
		
		dock_grid.column_homogeneous = true;
		dock_grid.column_spacing = 12;
		dock_grid.row_spacing = 6;
		dock_grid.margin = 64;
		dock_grid.margin_top = 24;
		
		dock_grid.attach (new LLabel.right (_("Icon Size:")), 0, 0, 1, 1);
		dock_grid.attach (icon_size_box, 1, 0, 1, 1);
		dock_grid.attach (new LLabel.right (_("Hide Mode:")), 0, 1, 1, 1);
		dock_grid.attach (hide_mode, 1, 1, 1, 1);
		if (i < 1) {
			dock_grid.attach (new LLabel.right (_("Monitor")+":"), 0, 2, 1, 1);
			dock_grid.attach (monitor, 1, 2, 1, 1);
		}
		
		notebook.append_page (dock_grid, new Gtk.Label (_("Dock")));
		
		/*wallpaper*/
		var wallpaper = new Wallpaper (this);
		notebook.append_page (wallpaper, new Gtk.Label (_("Wallpaper")));
		
		/*hot corners*/
		var hotc_grid = new Gtk.Grid ();
		hotc_grid.column_spacing = 12;
		hotc_grid.margin = 32;
		hotc_grid.margin_top = 50;
		
		var expl = new LLabel (_("When the cursor enters the corner of the display:"));
		expl.margin_bottom = 10;
		
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
		
		var cc_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		cc_box.margin_top = 24;
		cc_box.pack_start (new LLabel (_("Custom Command:")), false);
		cc_box.pack_start (custom_command, false);
		
		hotc_grid.attach (expl, 0, 0, 3, 1);
		hotc_grid.attach (icon, 1, 1, 1, 3);
		hotc_grid.attach (topleft, 0, 1, 1, 1);
		hotc_grid.attach (topright, 2, 1, 1, 1);
		hotc_grid.attach (bottomleft, 0, 3, 1, 1);
		hotc_grid.attach (bottomright, 2, 3, 1, 1);
		hotc_grid.attach (cc_box, 0, 4, 2, 1);
		
		notebook.append_page (hotc_grid, new Gtk.Label (_("Hot Corners")));
		
		
		add (notebook);
		
		notebook.page_changed.connect ((page) => {
			if (page == 1 && !wallpaper.finished) {
				switchboard_controller.progress_bar_set_visible (true);
			} else {
				switchboard_controller.progress_bar_set_visible (false);
			}
		});
	}
	
	Gtk.ComboBoxText create_hotcorner ()
	{
		var box = new Gtk.ComboBoxText ();
		box.append ("0", _("Do Nothing"));
		box.append ("1", _("Show Workspace View"));
		box.append ("2", _("Maximize Current Window"));
		box.append ("3", _("Minimize Current Window"));
		box.append ("4", _("Open Launcher"));
		box.append ("6", _("Expose All Windows"));
		box.append ("5", _("Execute Custom Command"));
		
		return box;
	}
}

public static int main (string[] args)
{
	Gtk.init (ref args);
	
	var plug = new GalaPlug ();
	plug.register ("Effects");
	plug.show_all ();
	
	Gtk.main ();
	return 0;
}
