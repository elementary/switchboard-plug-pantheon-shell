/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2015-2024 elementary, Inc. (https://elementary.io)
 */

public class PantheonShell.Wallpaper : Switchboard.SettingsPage {
    public enum ColumnType {
        ICON,
        NAME
    }

    private const string [] REQUIRED_FILE_ATTRS = {
        FileAttribute.STANDARD_NAME,
        FileAttribute.STANDARD_TYPE,
        FileAttribute.STANDARD_CONTENT_TYPE,
        FileAttribute.STANDARD_IS_HIDDEN,
        FileAttribute.STANDARD_IS_BACKUP,
        FileAttribute.STANDARD_IS_SYMLINK,
        FileAttribute.THUMBNAIL_PATH,
        FileAttribute.THUMBNAIL_IS_VALID
    };

    private static GLib.Settings gnome_background_settings;
    private static GLib.Settings gala_background_settings;

    private Gtk.ScrolledWindow wallpaper_scrolled_window;
    private Gtk.FlowBox wallpaper_view;
    private Gtk.Overlay view_overlay;
    private Gtk.Switch dim_switch;
    private Gtk.ComboBoxText combo;
    private Gtk.ColorButton color_button;

    private WallpaperContainer active_wallpaper = null;
    private SolidColorContainer solid_color = null;
    private WallpaperContainer wallpaper_for_removal = null;

    private Cancellable last_cancellable;

    private string current_wallpaper_path;
    private bool prevent_update_mode = false; // When restoring the combo state, don't trigger the update.
    private bool finished; // Shows that we got or wallpapers together

    public Wallpaper () {
        Object (
            title: _("Wallpaper"),
            icon: new ThemedIcon ("preferences-desktop-wallpaper")
        );
    }

    static construct {
        gnome_background_settings = new GLib.Settings ("org.gnome.desktop.background");
        gala_background_settings = new GLib.Settings ("io.elementary.desktop.background");
    }

    construct {
        var wallpaper_picture = new Gtk.Picture () {
            content_fit = COVER
        };
        wallpaper_picture.add_css_class (Granite.STYLE_CLASS_CARD);
        wallpaper_picture.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var monitor = Gdk.Display.get_default ().get_monitor_at_surface (
            (((Gtk.Application) Application.get_default ()).active_window).get_surface ()
        );

        var monitor_ratio = (float) monitor.geometry.width / monitor.geometry.height;

        var wallpaper_frame = new Gtk.AspectFrame (0.5f, 0.5f, monitor_ratio, false) {
            child = wallpaper_picture
        };

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);

        wallpaper_view = new Gtk.FlowBox () {
            activate_on_single_click = true,
            homogeneous = true,
            selection_mode = SINGLE,
            min_children_per_line = 3,
            max_children_per_line = 5
        };
        wallpaper_view.add_css_class (Granite.STYLE_CLASS_VIEW);
        wallpaper_view.child_activated.connect (update_checked_wallpaper);
        wallpaper_view.set_sort_func (wallpapers_sort_function);
        wallpaper_view.add_controller (drop_target);

        var color = gnome_background_settings.get_string ("primary-color");
        create_solid_color_container (color);

        wallpaper_scrolled_window = new Gtk.ScrolledWindow () {
            child = wallpaper_view,
            hscrollbar_policy = NEVER,
            propagate_natural_height = true
        };

        view_overlay = new Gtk.Overlay () {
            child = wallpaper_scrolled_window
        };

        var add_wallpaper_label = new Gtk.Label (_("Import Photo…"));

        var add_wallpaper_box = new Gtk.Box (HORIZONTAL, 0);
        add_wallpaper_box.append (new Gtk.Image.from_icon_name ("document-open-symbolic"));
        add_wallpaper_box.append (add_wallpaper_label);

        var add_wallpaper_button = new Gtk.Button () {
            child = add_wallpaper_box,
            has_frame = false,
            margin_top = 3,
            margin_bottom= 3
        };

        add_wallpaper_label.mnemonic_widget = add_wallpaper_button;

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (add_wallpaper_button);

        var wallpaper_box = new Gtk.Box (VERTICAL, 0);
        wallpaper_box.append (view_overlay);
        wallpaper_box.append (actionbar);
        wallpaper_box.add_css_class (Granite.STYLE_CLASS_FRAME);

        dim_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var dim_label = new Gtk.Label (_("Dim with dark style:")) {
            mnemonic_widget = dim_switch
        };

        var dim_box = new Gtk.Box (HORIZONTAL, 6);
        dim_box.append (dim_label);
        dim_box.append (dim_switch);

        combo = new Gtk.ComboBoxText ();
        combo.append ("centered", _("Centered"));
        combo.append ("zoom", _("Zoom"));
        combo.append ("spanned", _("Spanned"));
        combo.changed.connect (update_mode);

        Gdk.RGBA rgba_color = {};
        if (!rgba_color.parse (color)) {
            rgba_color = { 1, 1, 1, 1 };
        }

        color_button = new Gtk.ColorButton () {
            rgba = rgba_color
        };
        color_button.color_set.connect (update_color);

        var size_group = new Gtk.SizeGroup (HORIZONTAL);
        size_group.add_widget (add_wallpaper_button);
        size_group.add_widget (combo);
        size_group.add_widget (color_button);

        load_settings ();

        var main_box = new Gtk.Box (VERTICAL, 12);
        main_box.append (wallpaper_frame);
        main_box.append (wallpaper_box);
        main_box.append (color_button);
        main_box.append (combo);
        main_box.append (dim_box);

        child = main_box;

        add_wallpaper_button.clicked.connect (show_wallpaper_chooser);

        drop_target.drop.connect (on_drag_data_received);

        wallpaper_picture.file = File.new_for_uri (
            gnome_background_settings.get_string ("picture-uri")
        );

        gnome_background_settings.changed["picture-uri"].connect (() => {
            wallpaper_picture.file = File.new_for_uri (
                gnome_background_settings.get_string ("picture-uri")
            );
        });
    }

    private void show_wallpaper_chooser () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/*");

        var file_dialog = new Gtk.FileDialog () {
            accept_label = _("Import"),
            default_filter = filter,
            modal = true,
            title = _("Import Photos")
        };

        file_dialog.open_multiple.begin ((Gtk.Window) get_root (), null, (obj, res) => {
            var list_model = file_dialog.open_multiple.end (res);
            if (list_model != null) {
                for (var i = 0; i <= list_model.get_n_items (); i++) {
                    var file = (File) list_model.get_item (i);

                    if (WallpaperOperation.get_is_file_in_bg_dir (file)) {
                        continue;
                    }

                    var local_uri = file.get_uri ();
                    var dest = WallpaperOperation.copy_for_library (file);
                    if (dest != null) {
                        local_uri = dest.get_uri ();
                    }

                    add_wallpaper_from_file (file, local_uri);
                }
            }
        });
    }

    private void load_settings () {
        gala_background_settings.bind ("dim-wallpaper-in-dark-style", dim_switch, "active", SettingsBindFlags.DEFAULT);

        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.
        string picture_options = gnome_background_settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.sensitive = false;
            picture_options = "zoom";
        }

        prevent_update_mode = true;
        combo.set_active_id (picture_options);

        current_wallpaper_path = gnome_background_settings.get_string ("picture-uri");
    }

    /*
     * This integrates with LightDM
     */
    private void update_accountsservice () {
        var file = File.new_for_uri (current_wallpaper_path);
        string uri = file.get_uri ();

        if (!WallpaperOperation.get_is_file_in_bg_dir (file)) {
            var local_file = WallpaperOperation.copy_for_library (file);
            if (local_file != null) {
                uri = local_file.get_uri ();
            }
        }

        gnome_background_settings.set_string ("picture-uri", uri);
        gnome_background_settings.set_string ("picture-uri-dark", "");
    }

    private void update_checked_wallpaper (Gtk.FlowBox box, Gtk.FlowBoxChild child) {
        var children = (WallpaperContainer) wallpaper_view.get_selected_children ().data;

        if (!(children is SolidColorContainer)) {
            current_wallpaper_path = children.uri;
            update_accountsservice ();

            if (active_wallpaper == solid_color) {
                combo.sensitive = true;
                gnome_background_settings.set_string ("picture-options", combo.get_active_id ());
            }

        } else {
            set_combo_disabled_if_necessary ();
            gnome_background_settings.set_string ("primary-color", solid_color.color);
        }

        // We don't do gradient backgrounds, reset the key that might interfere
        gnome_background_settings.reset ("color-shading-type");

        children.checked = true;

        if (active_wallpaper != null && active_wallpaper != children) {
            active_wallpaper.checked = false;
        }

        active_wallpaper = children;
    }

    private void update_color () {
        if (finished) {
            set_combo_disabled_if_necessary ();
            create_solid_color_container (color_button.rgba.to_string ());
            wallpaper_view.append (solid_color);
            wallpaper_view.select_child (solid_color);

            if (active_wallpaper != null) {
                active_wallpaper.checked = false;
            }

            active_wallpaper = solid_color;
            active_wallpaper.checked = true;
            gnome_background_settings.set_string ("primary-color", solid_color.color);
        }
    }

    private void update_mode () {
        if (!prevent_update_mode) {
            gnome_background_settings.set_string ("picture-options", combo.get_active_id ());

            // Changing the mode, while a solid color is selected, change focus to the
            // wallpaper tile.
            if (active_wallpaper == solid_color) {
                active_wallpaper.checked = false;

                var child = wallpaper_view.get_first_child ();
                while (child != null) {
                    var container = (WallpaperContainer) child;
                    if (container.uri == current_wallpaper_path) {
                        container.checked = true;
                        wallpaper_view.select_child (container);
                        active_wallpaper = container;
                        break;
                    }

                    child = child.get_next_sibling ();
                }
            }
        } else {
            prevent_update_mode = false;
        }
    }

    private void set_combo_disabled_if_necessary () {
        if (active_wallpaper != solid_color) {
            combo.sensitive = false;
            gnome_background_settings.set_string ("picture-options", "none");
        }
    }

    public void update_wallpaper_folder () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;

        clean_wallpapers ();

        foreach (unowned string directory in WallpaperOperation.get_bg_directories ()) {
            load_wallpapers.begin (directory, cancellable);
        }
    }

    private async void load_wallpapers (string basefolder, Cancellable cancellable, bool toplevel_folder = true) {
        if (cancellable.is_cancelled ()) {
            return;
        }

        var directory = File.new_for_path (basefolder);

        try {
            // Enumerator object that will let us read through the wallpapers asynchronously
            var attrs = string.joinv (",", REQUIRED_FILE_ATTRS);
            var e = yield directory.enumerate_children_async (attrs, 0, Priority.DEFAULT);
            FileInfo file_info;

            // Loop through and add each wallpaper in the batch
            while ((file_info = e.next_file ()) != null) {
                if (cancellable.is_cancelled ()) {
                    ThumbnailGenerator.get_default ().dequeue_all ();
                    return;
                }

                if (file_info.get_is_hidden () || file_info.get_is_backup () || file_info.get_is_symlink ()) {
                    continue;
                }

                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    // Spawn off another loader for the subdirectory
                    var subdir = directory.resolve_relative_path (file_info.get_name ());
                    yield load_wallpapers (subdir.get_path (), cancellable, false);
                    continue;
                } else if (!IOHelper.is_valid_file_type (file_info)) {
                    // Skip non-picture files
                    continue;
                }

                var file = directory.resolve_relative_path (file_info.get_name ());
                string uri = file.get_uri ();

                add_wallpaper_from_file (file, uri);
            }

            if (toplevel_folder) {
                create_solid_color_container (color_button.rgba.to_string ());
                wallpaper_view.append (solid_color);
                finished = true;

                if (gnome_background_settings.get_string ("picture-options") == "none") {
                    wallpaper_view.select_child (solid_color);
                    solid_color.checked = true;
                    active_wallpaper = solid_color;
                }

                if (active_wallpaper != null) {
                    Gtk.Allocation alloc;
                    active_wallpaper.get_allocation (out alloc);
                    wallpaper_scrolled_window.get_vadjustment ().value = alloc.y;
                }
            }
        } catch (Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning (err.message);
            }
        }
    }

    private void create_solid_color_container (string color) {
        if (solid_color != null) {
            wallpaper_view.unselect_child (solid_color);
            wallpaper_view.remove (solid_color);
            solid_color.destroy ();
        }

        solid_color = new SolidColorContainer (color);
    }

    private void clean_wallpapers () {
        while (wallpaper_view.get_first_child () != null) {
            wallpaper_view.remove (wallpaper_view.get_first_child ());
        }

        solid_color = null;
    }

    private bool on_drag_data_received (Value val, double x, double y) {
        var file_list = (Gdk.FileList) val;
        foreach (var file in file_list.get_files ()) {
            var local_uri = file.get_uri ();

            var dest = WallpaperOperation.copy_for_library (file);
            if (dest != null) {
                local_uri = dest.get_uri ();
            }

            add_wallpaper_from_file (file, local_uri);
        }

        return true;
    }

    private void add_wallpaper_from_file (GLib.File file, string uri) {
        // don't load 'removed' wallpaper on plug reload
        if (wallpaper_for_removal != null && wallpaper_for_removal.uri == uri) {
            return;
        }

        try {
            var info = file.query_info (string.joinv (",", REQUIRED_FILE_ATTRS), 0);
            var thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
            var thumb_valid = info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
            var wallpaper = new WallpaperContainer (uri, thumb_path, thumb_valid);
            wallpaper_view.append (wallpaper);

            wallpaper.trash.connect (() => {
                send_undo_toast ();
                mark_for_removal (wallpaper);
            });

            // Select the wallpaper if it is the current wallpaper
            if (current_wallpaper_path.has_suffix (uri) && gnome_background_settings.get_string ("picture-options") != "none") {
                this.wallpaper_view.select_child (wallpaper);
                // Set the widget activated without activating it
                wallpaper.checked = true;
                active_wallpaper = wallpaper;
            }
        } catch (Error e) {
            critical ("Unable to add wallpaper: %s", e.message);
        }

        wallpaper_view.invalidate_sort ();
    }

    public void cancel_thumbnail_generation () {
        if (last_cancellable != null) {
            last_cancellable.cancel ();
        }
    }

    private int wallpapers_sort_function (Gtk.FlowBoxChild _child1, Gtk.FlowBoxChild _child2) {
        var child1 = (WallpaperContainer) _child1;
        var child2 = (WallpaperContainer) _child2;
        var uri1 = child1.uri;
        var uri2 = child2.uri;

        if (uri1 == null || uri2 == null) {
            return 0;
        }

        var uri1_is_system = false;
        var uri2_is_system = false;
        foreach (var bg_dir in WallpaperOperation.get_system_bg_directories ()) {
            bg_dir = "file://" + bg_dir;
            uri1_is_system = uri1.has_prefix (bg_dir) || uri1_is_system;
            uri2_is_system = uri2.has_prefix (bg_dir) || uri2_is_system;
        }

        // Sort system wallpapers last
        if (uri1_is_system && !uri2_is_system) {
            return 1;
        } else if (!uri1_is_system && uri2_is_system) {
            return -1;
        }

        var child1_date = child1.creation_date;
        var child2_date = child2.creation_date;

        // sort by filename if creation dates are equal
        if (child1_date == child2_date) {
            return uri1.collate (uri2);
        }

        // sort recently added first
        if (child1_date >= child2_date) {
            return -1;
        } else {
            return 1;
        }
    }

    private void send_undo_toast () {
        unowned var child = view_overlay.get_first_child ();
        while (child != null) {
            if (child is Granite.Toast) {
                ((Granite.Toast) child).withdraw ();
            }
            child = child.get_next_sibling ();
        }

        if (wallpaper_for_removal != null) {
            confirm_removal ();
        }

        var toast = new Granite.Toast (_("Wallpaper Deleted"));
        toast.set_default_action (_("Undo"));

        toast.default_action.connect (() => {
            undo_removal ();
        });

        toast.dismissed.connect (confirm_removal);

        view_overlay.add_overlay (toast);
        toast.send_notification ();
    }

    private void mark_for_removal (WallpaperContainer wallpaper) {
        wallpaper_view.remove (wallpaper);
        wallpaper_for_removal = wallpaper;
    }

    public void confirm_removal () {
        if (wallpaper_for_removal == null) {
            return;
        }

        var wallpaper_file = File.new_for_uri (wallpaper_for_removal.uri);
        wallpaper_file.trash_async.begin ();
        wallpaper_for_removal.destroy ();
        wallpaper_for_removal = null;
    }

    private void undo_removal () {
        wallpaper_view.append (wallpaper_for_removal);
        wallpaper_for_removal = null;
    }
}
