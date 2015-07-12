const int DEFAULT_TRANSITION_DURATION = 1;
const string SLIDESHOW_FILENAME = "slideshow.xml";

const string SLIDESHOW_TEMPLATE = """
<background>
    %s
</background>""";

const string SLIDESHOW_WALLPAPER_TEMPLATE = """
    <static>
        <duration>%i</duration>
        <file>%s</file>
    </static>
    <transition>
        <duration>%i</duration>
        <from>%s</from>
        <to>%s</to>
    </transition>
""";

[DBus (name = "org.freedesktop.Accounts.User")]
interface AccountsServiceUser : Object {
    public abstract void set_background_file (string filename) throws IOError;
}

void update_slideshow (string path, List<File> files, int duration) {
    var wallpapers = "";
    var len = files.length ();
    for (var i = 0; i < len; i++) {
        var slide = files.nth_data (i).get_path ();
        var next_slide = files.nth_data (i - 1 == len ? 0 : i).get_path ();

        wallpapers += SLIDESHOW_WALLPAPER_TEMPLATE.printf (duration, slide,
            DEFAULT_TRANSITION_DURATION, slide, next_slide);
    }

    var slideshow = SLIDESHOW_TEMPLATE.printf (wallpapers);

    try {
        FileUtils.set_contents (path, slideshow);
    } catch (Error e) {
        error (e.message);
    }

    set_settings_key ("file://" + path);
}

void set_settings_key (string uri) {
    var settings = new Settings ("org.gnome.desktop.background");
    settings.set_string ("picture-uri", uri);
    settings.apply ();
    Settings.sync ();
}

int delay_value = 60;

// copied from pantheon-photos/shotwell src/DesktopIntegration.vala
void delay_value_changed (Gtk.Scale duration_scale, Gtk.Label duration_label) {
    double value = duration_scale.adjustment.value;

    // f(x)=x^5 allows to have fine-grained values (seconds) to the left
    // and very coarse-grained values (hours) to the right of the slider.
    // We limit maximum value to 1 day and minimum to 5 seconds.
    delay_value = (int) (Math.pow (value, 5) / Math.pow (90, 5) * 60 * 60 * 24 + 5);

    // convert to text and remove fractions from values > 1 minute
    string text;
    if (delay_value < 60) {
        text = ngettext ("%d second", "%d seconds", delay_value).printf (delay_value);
    } else if (delay_value < 60 * 60) {
        int minutes = delay_value / 60;
        text = ngettext ("%d minute", "%d minutes", minutes).printf (minutes);
        delay_value = minutes * 60;
    } else if (delay_value < 60 * 60 * 24) {
        int hours = delay_value / (60 * 60);
        text = ngettext ("%d hour", "%d hours", hours).printf (hours);
        delay_value = hours * (60 * 60);
    } else {
        text = _ ("1 day");
        delay_value = 60 * 60 * 24;
    }

    duration_label.set_markup (_("Show each photo for") + " <b>" + text + "</b>");
}

string get_local_bg_location () {
    return Path.build_filename (Environment.get_user_data_dir (), "backgrounds") + "/";
}

File ensure_local_bg_exists () {
    var folder = File.new_for_path (get_local_bg_location ());
    if (!folder.query_exists ()) {
        try {
            folder.make_directory_with_parents ();
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    return folder;
}

// copy the file to the local folder
bool copy_to_local_folder (File tmpfile) {
    try {
        var cp_file = File.new_for_path (get_local_bg_location () + tmpfile.get_basename ());
        tmpfile.copy (cp_file, FileCopyFlags.OVERWRITE.NOFOLLOW_SYMLINKS);
    } catch (Error e) {
        warning ("%s\n", e.message);
        return false;
    }

    return true;
}

int main (string[] args) {
    Gtk.init (ref args);

    AccountsServiceUser? accountsservice = null;
    try {
        var uid = "%d".printf ((int) Posix.getuid ());
        accountsservice = Bus.get_proxy_sync (BusType.SYSTEM,
                "org.freedesktop.Accounts",
                "/org/freedesktop/Accounts/User" + uid);
    } catch (Error e) {
        warning ("%s\n", e.message); 
    }

    var folder = ensure_local_bg_exists ();
    var files = new List<File> ();
    for (var i = 1; i < args.length; i++) {
        var file = File.new_for_path (args[i]);
        var localfile = File.new_for_path (get_local_bg_location () + file.get_basename ());

        if (file != null) {
            if (copy_to_local_folder (file)) {
                files.append (localfile);
            } else {
                files.append (file);
            }

            try {
                accountsservice.set_background_file (file.get_path ());
            } catch (Error e) {
                warning ("%s\n", e.message);
            }        
        }
    }

    if (files.length () < 1) {
        critical ("No images specified, aborting.");
        return 1;
    }

    if (files.length () == 1) {
        set_settings_key (files.data.get_uri ());
        return 0;
    }

#if false // alternative: random name so it won't be overriden
    var filename = "slideshow-" + new DateTime.now_utc ().to_unix ().to_string () + "-" + Random.next_int ().to_string () + ".xml";
#else
    var filename = SLIDESHOW_FILENAME;
#endif

    var dialog = new Gtk.Dialog.with_buttons (_("Set As Desktop Slideshow"), null, 0);
    dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
    dialog.add_button (_("Create slideshow"), Gtk.ResponseType.OK);

    var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
    var label = new Gtk.Label ("");
    var duration = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
    duration.draw_value = false;
    duration.value_changed.connect (() => delay_value_changed (duration, label));
    duration.set_value (50);
    box.margin = 12;
    box.pack_start (label);
    box.pack_start (duration);
    dialog.set_default_response (Gtk.ResponseType.OK);
    dialog.get_content_area ().add (box);
    dialog.show_all ();

    if (dialog.run () == Gtk.ResponseType.OK) {
        dialog.destroy ();

        var path = folder.get_child (filename).get_path ();
        update_slideshow (path, files, delay_value);
        return 0;
    }

    return 1;
}