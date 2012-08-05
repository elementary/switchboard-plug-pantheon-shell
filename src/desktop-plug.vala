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
		
		/*appearance*/
		var app_grid = new Gtk.Grid ();
		var themes = new Gtk.ComboBoxText ();
		
		app_grid.row_spacing = 6;
		app_grid.column_spacing = 12;
		app_grid.margin_top = 24;
		
		try {
			var enumerator = File.new_for_path ("/usr/share/themes/").enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) {
				var name = file_info.get_name ();
				if (name == "elementary")
					name = "elementary ("+_("default")+")";
				themes.append (file_info.get_name (), name);
			}
		} catch (Error e) { warning (e.message); }
		themes.active_id = AppearanceSettings.get_default ().theme;
		themes.changed.connect (() => AppearanceSettings.get_default ().theme = themes.active_id );
		themes.halign = Gtk.Align.START;
		
		var shadow_lbl = new LLabel.markup ("<b>"+_("Shadows:")+"</b>");
		shadow_lbl.width_request = 300;
		
		var shadow_exp = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		shadow_exp.homogeneous = true;
		shadow_exp.pack_start (new LLabel.markup ("<i>"+_("X Offset")+"</i>"));
		shadow_exp.pack_start (new LLabel.markup ("<i>"+_("Y Offset")+"</i>"));
		shadow_exp.pack_start (new LLabel.markup ("<i>"+_("Radius")+"</i>"));
		shadow_exp.pack_start (new LLabel.markup ("<i>"+_("Opacity")+"</i>"));
		
		app_grid.attach (new LLabel.right (_("Window Decoration Theme:")), 0, 0, 1, 1);
		app_grid.attach (themes, 1, 0, 1, 1);
		app_grid.attach (shadow_lbl, 0, 1, 1, 1);
		app_grid.attach (shadow_exp, 1, 2, 1, 1);
		app_grid.attach (new LLabel.right (_("Normal:")), 0, 3, 1, 1);
		app_grid.attach (get_shadow_box (true), 1, 3, 1, 1);
		app_grid.attach (new LLabel.right (_("Unfocused:")), 0, 4, 1, 1);
		app_grid.attach (get_shadow_box (false), 1, 4, 1, 1);
		
		notebook.append_page (app_grid, new Gtk.Label (_("Appearance")));
		
		/*hot corners*/
		var hotc_grid = new Gtk.Grid ();
		hotc_grid.column_spacing = 12;
		hotc_grid.margin = 24;
		hotc_grid.margin_top = hotc_grid.margin_bottom = 6;
		
		var expl = new LLabel (_("Select the actions to be executed when your mouse enters a screen corner."));
		expl.margin_bottom = 10;
		
		var topleft = create_hotcorner ();
		topleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topleft").to_string ();
		topleft.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-topleft", int.parse (topleft.active_id)));
		var topright = create_hotcorner ();
		topright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topright").to_string ();
		topright.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-topright", int.parse (topright.active_id)));
		var bottomleft = create_hotcorner ();
		bottomleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomleft").to_string ();
		bottomleft.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-bottomleft", int.parse (bottomleft.active_id)));
		var bottomright = create_hotcorner ();
		bottomright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomright").to_string ();
		bottomright.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-bottomright", int.parse (bottomright.active_id)));
		
		var icon = new Gtk.Image.from_pixbuf (Gtk.IconTheme.get_default ().load_icon ("display", 256, 0));
		var custom_command = new Gtk.Entry ();
		custom_command.text = BehaviorSettings.get_default ().hotcorner_custom_command;
		custom_command.changed.connect (() => BehaviorSettings.get_default ().hotcorner_custom_command = custom_command.text );
		
		var cc_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		cc_box.margin_top = 10;
		cc_box.pack_start (new LLabel (_("Custom Command:")), false);
		cc_box.pack_start (custom_command, false);
		
		hotc_grid.attach (expl, 0, 0, 3, 1);
		hotc_grid.attach (icon, 1, 2, 1, 1);
		hotc_grid.attach (topleft, 0, 1, 1, 1);
		hotc_grid.attach (topright, 2, 1, 1, 1);
		hotc_grid.attach (bottomleft, 0, 3, 1, 1);
		hotc_grid.attach (bottomright, 2, 3, 1, 1);
		hotc_grid.attach (cc_box, 0, 4, 2, 1);
		
		notebook.append_page (hotc_grid, new Gtk.Label (_("Hot Corners")));
		
		/*slingshot*/
		var launch_grid = new Gtk.Grid ();
		launch_grid.margin = 24;
		launch_grid.column_homogeneous = true;
		launch_grid.column_spacing = 12;
		launch_grid.row_spacing = 6;
		
		var icon_size_s = new Gtk.SpinButton.with_range (16, 96, 1);
		icon_size_s.value = SlingshotSettings.get_default ().icon_size;
		icon_size_s.value_changed.connect (() => SlingshotSettings.get_default ().icon_size = (int)icon_size_s.value);
		icon_size_s.halign = Gtk.Align.START;
		
		var cols = new Gtk.SpinButton.with_range (1, 20, 1);
		var rows = new Gtk.SpinButton.with_range (1, 20, 1);
		var x = new Gtk.Label ("x");
		cols.halign = Gtk.Align.START;
		rows.halign = Gtk.Align.START;
		x.halign = Gtk.Align.START;
		cols.value = SlingshotSettings.get_default ().columns;
		cols.value_changed.connect (() => SlingshotSettings.get_default ().columns = (int)cols.value);
		rows.value = SlingshotSettings.get_default ().rows;
		rows.value_changed.connect (() => SlingshotSettings.get_default ().rows = (int)rows.value);
		
		var grid_size_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		grid_size_box.pack_start (rows, false);
		grid_size_box.pack_start (x, false);
		grid_size_box.pack_start (cols, false);
		
		var open_at_mouse = new Gtk.Switch ();
		open_at_mouse.halign = Gtk.Align.START;
		open_at_mouse.active = SlingshotSettings.get_default ().open_on_mouse;
		open_at_mouse.notify["active"].connect (() => SlingshotSettings.get_default ().open_on_mouse = open_at_mouse.active);
		var category_switch = new Gtk.Switch ();
		category_switch.halign = Gtk.Align.START;
		category_switch.active = SlingshotSettings.get_default ().show_category_filter;
		category_switch.notify["active"].connect (() => SlingshotSettings.get_default ().show_category_filter = category_switch.active);
		
		launch_grid.attach (new LLabel.right (_("Icon Grid Size:")), 0, 0, 1, 1);
		launch_grid.attach (grid_size_box, 1, 0, 1, 1);
		launch_grid.attach (new LLabel.right (_("Open at Mouse:")), 0, 1, 1, 1);
		launch_grid.attach (open_at_mouse, 1, 1, 1, 1);
		launch_grid.attach (new LLabel.right (_("Category Switch:")), 0, 2, 1, 1);
		launch_grid.attach (category_switch, 1, 2, 1, 1);
		launch_grid.attach (new LLabel.right (_("Icon Size:")), 0, 3, 1, 1);
		launch_grid.attach (icon_size_s, 1, 3, 1, 1);
		
		notebook.append_page (launch_grid, new Gtk.Label (_("Launcher")));
		
		
		add (notebook);
	}
	
	Gtk.ComboBoxText create_hotcorner ()
	{
		var box = new Gtk.ComboBoxText ();
		box.append ("0", _("None"));
		box.append ("1", _("Show Workspace View"));
		box.append ("2", _("Maximize Current Window"));
		box.append ("3", _("Minimize Current Window"));
		box.append ("4", _("Open Launcher"));
		box.append ("5", _("Custom Command"));
		
		return box;
	}
	
	Gtk.Box get_shadow_box (bool focused)
	{
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		
		var x = new Gtk.SpinButton.with_range (-200, 200, 1);
		var y = new Gtk.SpinButton.with_range (-200, 200, 1);
		var r = new Gtk.SpinButton.with_range (1, 200, 1);
		var o = new Gtk.SpinButton.with_range (0, 255, 1);
		
		var p = (focused)?ShadowSettings.get_default ().normal_focused:ShadowSettings.get_default ().normal_unfocused;
		
		x.value = int.parse (p[2]);
		y.value = int.parse (p[3]);
		r.value = int.parse (p[0]);
		o.value = int.parse (p[4]);
		
		x.value_changed.connect (() => {
			p[2] = ((int)x.value).to_string ();
			(focused)?ShadowSettings.get_default ().normal_focused = p:
					  ShadowSettings.get_default ().normal_unfocused = p;
		});
		y.value_changed.connect (() => {
			p[3] = ((int)y.value).to_string ();
			(focused)?ShadowSettings.get_default ().normal_focused = p:
					  ShadowSettings.get_default ().normal_unfocused = p;
		});
		r.value_changed.connect (() => {
			p[0] = ((int)r.value).to_string ();
			(focused)?ShadowSettings.get_default ().normal_focused = p:
					  ShadowSettings.get_default ().normal_unfocused = p;
		});
		o.value_changed.connect (() => {
			p[4] = ((int)o.value).to_string ();
			(focused)?ShadowSettings.get_default ().normal_focused = p:
					  ShadowSettings.get_default ().normal_unfocused = p;
		});
		
		var reset = new Gtk.Button ();
		reset.add (new Gtk.Image.from_stock (Gtk.Stock.CLEAR, Gtk.IconSize.BUTTON));
		reset.tooltip_text = _("Reset to default");
		reset.clicked.connect (() => {
			x.value = (focused)?0:0;
			y.value = (focused)?15:6;
			o.value = (focused)?220:150;
			r.value = (focused)?20:8;
		});
		
		box.pack_start (x);
		box.pack_start (y);
		box.pack_start (r);
		box.pack_start (o);
		box.pack_start (reset);
		
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
