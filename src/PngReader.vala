errordomain PngError {
    READ
}

public class PngReader : GLib.Object {

    private Png.Struc png_ptr;
    private Png.Info info_ptr;

    public Gee.HashMap<string, string> metadata = new Gee.HashMap<string, string> ();

    private static void user_read_data (Png.Struc png_ptr, uint8[] data) {
        void* a = png_ptr.get_io_ptr ();
        try {
            ((FileInputStream) a).read (data);
        }
        catch (IOError e) {
            //
        }
    }

    public PngReader (string pathname) throws Error {
        File file = File.new_for_path (pathname);
        FileInputStream fp;
        try {
            fp = file.read ();
        } catch (Error e) {
            throw new PngError.READ ("%s: error: %s".printf (pathname, e.message));
        }

        uint8[] header = new uint8[8];
        try {
            fp.read (header);
        } catch (Error e) {
            throw new PngError.READ ("%s: error: %s".printf (pathname, e.message));
        }

        if (Png.sig_cmp(header, 0, 8) != 0) {
            throw new PngError.READ ("%s: error: %s".printf (pathname, "not a PNG"));
        }

        png_ptr = new Png.Struc ();
        info_ptr = new Png.Info (png_ptr);
        png_ptr.set_read_fn (fp, user_read_data);
        png_ptr.set_sig_bytes (8);
        png_ptr.read_info (info_ptr);

        for (int i = 0; i < info_ptr.num_text; i++) {
            metadata.set (info_ptr.text[i].key, info_ptr.text[i].text);
        }

        Png.destroy_read_struct (&png_ptr, &info_ptr, null);
        Png.destroy_read_struct (&png_ptr, null, null);
    }
}
