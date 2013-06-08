using Gtk;

/*
stolen from old wallpaper plug
*/

// Helper class for the file IO functions we'll need
// Not needed at all, but helpful for organization
public class IOHelper : GLib.Object {

	// Check if the filename has a picture file extension.
	public static bool is_valid_file_type (GLib.FileInfo file_info) {
		
		// Check for correct file type, don't try to load directories and such
		if (file_info.get_file_type () != GLib.FileType.REGULAR)
			return false;

		// Now check if it is an accepted content type
		string[] accepted_types = {
			"image/jpeg",
			"image/png",
			"image/tiff",
			"image/gif"
		};

		foreach (var type in accepted_types) {
			if (GLib.ContentType.equals (file_info.get_content_type (), type))
				return true;
		}

		return false;
	}

	// Quickly count up all of the valid wallpapers in the wallpaper folder.
	public static int count_wallpapers (GLib.File wallpaper_folder) {
		
		GLib.FileInfo file_info = null;
		int count = 0;
		try {
			// Get an enumerator for all of the plain old files in the wallpaper folder.
			var enumerator = wallpaper_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
			// While there's still files left to count
			while ((file_info = enumerator.next_file ()) != null) {
				// If it's a picture file
				if (is_valid_file_type(file_info)) {
					count++;
				}
			}
		} catch(GLib.Error err) {
			if (!(err is IOError.NOT_FOUND)) {
				warning ("Could not pre-scan wallpaper folder. Progress percentage may be off: %s", err.message);
			}
		}
		return count;
	}
	
}

public enum ColumnType
{
  ICON,
  NAME
}

class Wallpaper : EventBox {
	
	string WALLPAPER_DIR = "/usr/share/backgrounds";
	
	GLib.Settings settings;
	
	ListStore store;
	GLib.List <TreeIter?> iters = new GLib.List <TreeIter?> ();
	Gtk.TreeIter selected_plug;
	IconView wallpaper_view;
	ComboBoxText combo;
	ComboBoxText folder_combo;
	ColorButton color;
	string current_wallpaper_path;
	
	Pantheon.Switchboard.Plug plug;
	
	//shows that we got or wallpapers together
	public bool finished;
	
	//name of the default-wallpaper-link that we can prevent loading it again
	//(assumes that the defaultwallpaper is also in the system wallpaper directory)
	static string default_link = "/usr/share/backgrounds/elementaryos-default";

	public Wallpaper (Pantheon.Switchboard.Plug _plug) {
		
		plug = _plug;
		
		settings = new GLib.Settings ("org.gnome.desktop.background");
		
		store = new Gtk.ListStore (2, typeof (Gdk.Pixbuf), typeof (string));
		
		var vbox = new Box (Orientation.VERTICAL, 4);
		
		string icon_style = """
			.wallpaper-view {
				background-color: @background_color;
			}
			.wallpaper-view:selected {
				background-color: #FFFFFF;
				border-color: shade (mix (rgb (34, 255, 120), #fff, 0.5), 0.9);
			}
		""";
		var icon_view_style = new Gtk.CssProvider ();
		try {
			icon_view_style.load_from_data (icon_style, -1);
		} catch (Error e) { warning (e.message); }
		
		wallpaper_view = new IconView ();
		wallpaper_view.set_selection_mode (Gtk.SelectionMode.SINGLE);
		wallpaper_view.set_pixbuf_column (0);
		wallpaper_view.set_model (this.store);
		wallpaper_view.selection_changed.connect (update_wallpaper);
		wallpaper_view.get_style_context ().add_class ("wallpaper-view");
		wallpaper_view.get_style_context ().add_provider (icon_view_style, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		wallpaper_view.item_padding = 5;

		wallpaper_view.size_allocate.connect ( () => {
			int width = wallpaper_view.get_allocated_width ();
			int columns = (int) GLib.Math.floor(width/200);
			wallpaper_view.set_columns (columns);
		});
		
		TargetEntry e = {"text/uri-list", 0, 0};
		wallpaper_view.drag_data_received.connect (on_drag_data_received);
		drag_dest_set (wallpaper_view, DestDefaults.ALL, {e}, Gdk.DragAction.COPY);
		
		var scrolled = new ScrolledWindow (null, null);
		scrolled.set_size_request (250, 250);
		scrolled.set_margin_left (12);
		scrolled.set_margin_right (12);
		scrolled.add (wallpaper_view);
		
		vbox.pack_start (scrolled, true, true, 5);
		
		folder_combo = new ComboBoxText ();
		folder_combo.append ("pic", _("Pictures folder"));
		folder_combo.append ("sys", _("Backgrounds folder"));
		folder_combo.append ("cus", _("Custom folder"));
		folder_combo.changed.connect (update_wallpaper_folder);
		folder_combo.set_active (1);
		
		combo = new ComboBoxText ();
		combo.append ("none", _("Solid Color"));
		combo.append ("centered", _("Centered"));
		combo.append ("scaled", _("Scaled"));
		combo.append ("stretched", _("Stretched"));
		combo.append ("zoom", _("Zoom"));
		combo.append ("spanned", _("Spanned"));
		combo.changed.connect (update_mode);
		
		color = new ColorButton ();
		color.color_set.connect (update_color);
		
		load_settings ();
		
		var hbox = new Box (Orientation.HORIZONTAL, 0);
		
		var bbox = new ButtonBox (Orientation.HORIZONTAL);
		bbox.set_margin_left (10);
		bbox.set_spacing (5);
		bbox.set_margin_top (8);
		bbox.set_margin_bottom (8);
		bbox.set_layout (ButtonBoxStyle.START);
		bbox.add (folder_combo);
		
		hbox.pack_start (bbox, false, false);
		
		//Spacer
		
		bbox = new ButtonBox (Orientation.HORIZONTAL);
		bbox.set_margin_right (10);
		bbox.set_spacing (5);
		bbox.set_margin_top (8);
		bbox.set_margin_bottom (8);
		bbox.set_layout (ButtonBoxStyle.END);
		bbox.add (combo);
		bbox.add (color);
		
		hbox.pack_end (bbox, false, false);
		
		vbox.pack_start (new Separator (Orientation.HORIZONTAL), false, true);
		vbox.pack_start (hbox, false, false);
		
		add (vbox);
		
	}
	
	void load_settings () {
		combo.set_active_id (settings.get_string ("picture-options"));
		
		Gdk.Color c;
		Gdk.Color.parse (settings.get_string ("primary-color"), out c);
		color.set_color (c);
		
		current_wallpaper_path = settings.get_string ("picture-uri");
	}
	
	void update_wallpaper () {
		var selected = wallpaper_view.get_selected_items ();
		if (selected.length() == 1) {
			GLib.Value filename;
			// Get the filename of the selected wallpaper.
			var item = selected.nth_data(0);
			this.store.get_iter(out this.selected_plug, item);
			this.store.get_value(this.selected_plug, 1, out filename);
			
			current_wallpaper_path = filename.get_string();
			
			settings.set_string ("picture-uri", "file://" + filename.get_string ());
		
		}
	}
	
	void update_color () {
		Gdk.Color c;
		color.get_color (out c);
		settings.set_string ("primary-color", c.to_string ());
	}
	
	void update_mode () {
		settings.set_string ("picture-options", combo.get_active_id ());
	}
	
	void update_wallpaper_folder () {
		if (folder_combo.get_active () == 0) {
			clean_wallpapers ();
			WALLPAPER_DIR = GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES);
			load_wallpapers ();
		}
		else if (folder_combo.get_active () == 1) {
			clean_wallpapers ();
			WALLPAPER_DIR = "/usr/share/backgrounds";
			load_wallpapers.begin (() => {
				WALLPAPER_DIR = Environment.get_user_data_dir () + "/backgrounds";
				load_wallpapers ();
			});
		}
		else if (folder_combo.get_active () == 2) {
			
			var dialog = new Gtk.FileChooserDialog (_("Select a folder"), null, FileChooserAction.SELECT_FOLDER);
			dialog.add_button (Stock.CANCEL, ResponseType.CANCEL);
			dialog.add_button (Stock.OPEN, ResponseType.ACCEPT);
			dialog.set_default_response (ResponseType.ACCEPT);
			
			if (dialog.run () == ResponseType.ACCEPT) {
				clean_wallpapers ();
				WALLPAPER_DIR = dialog.get_filename ();
				load_wallpapers ();
				dialog.destroy ();
			} else dialog.destroy ();
		
		}
	}
	
	async void load_wallpapers () {
		
		folder_combo.set_sensitive (false);
		
		// Make the progress bar visible, since we're gonna be using it.
		try {
			plug.switchboard_controller.progress_bar_set_text(_("Importing wallpapers from %s").printf(WALLPAPER_DIR));
		} catch (Error e) { warning (e.message); }
		
		var directory = File.new_for_path (WALLPAPER_DIR);
		// The number of wallpapers we've added so far
		double done = 0.0;
		
		try {
			// Count the # of wallpapers
			int count = IOHelper.count_wallpapers(directory);
			if (count == 0)
				folder_combo.set_sensitive (true);
			
			// Enumerator object that will let us read through the wallpapers asynchronously
			var e = yield directory.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0, Priority.DEFAULT);
			
			while (true) {
				// Grab a batch of 10 wallpapers
				var files = yield e.next_files_async (10, Priority.DEFAULT);
				// Stop the loop if we've run out of wallpapers
				if (files == null) {
					break;
				}
				// Loop through and add each wallpaper in the batch
				foreach (var info in files) {
					// We're going to add another wallpaper
					done++;
					// Skip the file if it's not a picture
					if (!IOHelper.is_valid_file_type(info)) {
						continue;
					}
					string filename = WALLPAPER_DIR + "/" + info.get_name ();
					// Skip the default_wallpaper as seen in the description of the
					// default_link variable
					if (filename == default_link) {
						continue;
					}
					
					try {
						// Create a thumbnail of the image and load it into the IconView
						var image = new Gdk.Pixbuf.from_file_at_scale(filename, 180, 120, false);
						// Add the wallpaper name and thumbnail to the IconView
						Gtk.TreeIter root;
						this.store.append(out root);
						this.store.set(root, 0, image, -1);
						this.store.set(root, 1, filename, -1);
					
						// Select the wallpaper if it is the current wallpaper
						if (filename == current_wallpaper_path) {
							this.wallpaper_view.select_path (this.store.get_path (root));
						}
					
						this.iters.append (root);
						// Update the progress bar
						plug.switchboard_controller.progress_bar_set_fraction(done/count);
						// Have GTK update the UI even while we're busy
						// working on file IO.
						while(Gtk.events_pending ()) {
							Gtk.main_iteration();
						}
					} catch (Error e) { warning (e.message); }
				}
			}
			// Hide the progress bar since we're done with it.
			plug.switchboard_controller.progress_bar_set_visible(false);
			finished = true;
			
			folder_combo.set_sensitive (true);
		} catch (Error err) {
			if (!(err is IOError.NOT_FOUND)) {
				warning (err.message);
			}
		}
	}
	
	void clean_wallpapers () {
		store.clear ();
	}
	
	void on_drag_data_received (Widget widget, Gdk.DragContext ctx, 
		int x, int y, SelectionData sel, uint information, uint timestamp) {
		if (sel.get_length () > 0){
			File file = File.new_for_uri (sel.get_uris ()[0]);
			
			string display_name = Filename.display_basename (file.get_path ());
			
			var dest_folder = File.new_for_path (Environment.get_user_data_dir ()+"/backgrounds");
			var dest = File.new_for_path (Environment.get_user_data_dir ()+"/backgrounds/"+display_name);
			if (!dest_folder.query_exists ()) {
				try {
					dest_folder.make_directory ();
				} catch (Error e) { warning (e.message); }
			}
			
			try {
				file.copy (dest, 0);
			} catch (Error e) { warning (e.message); }
			
			string filename = dest.get_path ();
			
			string extension = display_name.split(".")[display_name.split(".").length - 1];
			
			if (extension != "jpg" && extension != "png" && extension != "jpeg" && extension != "gif") {
				Gtk.drag_finish (ctx, false, false, timestamp);
				return;
			}
			
			// Create a thumbnail of the image and load it into the IconView
			Gdk.Pixbuf image = null;
			try {
				image = new Gdk.Pixbuf.from_file_at_scale(filename, 180, 120, false);
			} catch (Error e) { warning (e.message); }
			// Add the wallpaper name and thumbnail to the IconView
			Gtk.TreeIter root;
			this.store.append(out root);
			this.store.set(root, 0, image, -1);
			this.store.set(root, 1, filename, -1);
			
			Gtk.drag_finish (ctx, true, false, timestamp);
			return;
		}
		Gtk.drag_finish (ctx, false, false, timestamp);
		return;
	}
	
}
