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

class LLabel : Gtk.Label {
	public LLabel (string label) {
		this.set_halign (Gtk.Align.START);
		this.label = label;
	}
	public LLabel.indent (string label) {
		this (label);
		this.margin_left = 10;
	}
	public LLabel.markup (string label) {
		this (label);
		this.use_markup = true;
	}
	public LLabel.right (string label) {
		this.set_halign (Gtk.Align.END);
		this.label = label;
	}
	public LLabel.right_with_markup (string label) {
		this.set_halign (Gtk.Align.END);
		this.use_markup = true;
		this.label = label;
	}
}

public class GalaPlug : Pantheon.Switchboard.Plug {
	
	public GalaPlug () {
		
		var notebook = new Granite.Widgets.StaticNotebook ();
		notebook.margin = 12;
		
		/*animations*/
		var anim_grid = new Gtk.Grid ();
		var open_dur = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 1,2000, 10);
		open_dur.set_value (AnimationSettings.get_default ().open_duration);
		open_dur.value_changed.connect (() => AnimationSettings.get_default ().open_duration = (int)open_dur.get_value () );
		
		var close_dur = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 1, 2000, 10);
		close_dur.set_value (AnimationSettings.get_default ().close_duration);
		close_dur.value_changed.connect (() => AnimationSettings.get_default ().close_duration = (int)close_dur.get_value () );
		
		var snap_dur = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 1, 2000, 10);
		snap_dur.set_value (AnimationSettings.get_default ().snap_duration);
		snap_dur.value_changed.connect (() => AnimationSettings.get_default ().snap_duration = (int)snap_dur.get_value () );
		
		var work_dur = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 1, 2000, 10);
		work_dur.set_value (AnimationSettings.get_default ().workspace_switch_duration);
		work_dur.value_changed.connect (() => AnimationSettings.get_default ().workspace_switch_duration = (int)work_dur.get_value () );
		
		var enable_anim = new Gtk.Switch ();
		enable_anim.notify["active"].connect (() => {
			open_dur.sensitive = enable_anim.active;
			close_dur.sensitive = enable_anim.active;
			snap_dur.sensitive = enable_anim.active;
			work_dur.sensitive = enable_anim.active;
			AnimationSettings.get_default ().enable_animations = enable_anim.active;
		});
		
		enable_anim.active = AnimationSettings.get_default ().enable_animations;
		
		anim_grid.column_homogeneous = true;
		anim_grid.column_spacing = 12;
		enable_anim.halign = Gtk.Align.START;
		
		anim_grid.attach (new LLabel.right (_("Animations:")), 0, 0, 1, 1);
		anim_grid.attach (enable_anim, 1, 0, 1, 1);
		anim_grid.attach (new LLabel.right (_("Open Duration:")), 0, 1, 1, 1);
		anim_grid.attach (open_dur, 1, 1, 1, 1);
		anim_grid.attach (new LLabel.right (_("Close Duration:")), 0, 2, 1, 1);
		anim_grid.attach (close_dur, 1, 2, 1, 1);
		anim_grid.attach (new LLabel.right (_("Snap Duration:")), 0, 3, 1, 1);
		anim_grid.attach (snap_dur, 1, 3, 1, 1);
		anim_grid.attach (new LLabel.right (_("Workspace Switch Duration")), 0, 4, 1, 1);
		anim_grid.attach (work_dur, 1, 4, 1, 1);
		
		notebook.append_page (anim_grid, new Gtk.Label (_("Animations")));
		
		/*appearance*/
		var app_grid = new Gtk.Grid ();
		var themes = new Gtk.ComboBoxText ();
		
		app_grid.column_homogeneous = true;
		app_grid.column_spacing = 12;
		
		try {
			var enumerator = File.new_for_path ("/usr/share/themes/").enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) {
				themes.append (file_info.get_name (), file_info.get_name ());
			}
		} catch (Error e) { warning (e.message); }
		themes.active_id = AppearanceSettings.get_default ().theme;
		themes.changed.connect (() => AppearanceSettings.get_default ().theme = themes.active_id );
		
		app_grid.attach (new LLabel.right (_("Window Decoration Theme:")), 0, 0, 1, 1);
		app_grid.attach (themes, 1, 0, 1, 1);
		
		
		notebook.append_page (app_grid, new Gtk.Label (_("Appearance")));
		
		add (notebook);
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
