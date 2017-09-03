/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */

[CCode (cheader_filename = "png.h")]
namespace Png {

	[CCode (cname = "PNG_LIBPNG_VER_STRING")]
	const string LIBPNG_VER_STRING;

	[CCode (cname = "png_error_ptr", has_target = false, has_type_id = false)]
	public delegate void ErrorFn (Struc struc, 
	                              [CCode (array_length = false, 
	                                      array_null_terminated = true)] 
	                              uint8[] arr);
	[CCode (cname = "png_rw_ptr", has_target = false, has_type_id = false)]
	public delegate void RwFn (Struc struc, [CCode (array_length_type = "size_t")] uint8[] data);
	[CCode (cname = "png_struct", free_function = "")]
	[Compact]
	public class Struc {
		[CCode (cname = "png_create_read_struct")]
		public Struc ([CCode (array_length = false, 
		                      array_null_terminated = true)] 
		              uint8[] user_png_ver = LIBPNG_VER_STRING.data, 
		              void *error_ptr = null, ErrorFn error_fn = (ErrorFn) null, 
		              ErrorFn warn_fn = (ErrorFn) null);
		[CCode (cname = "png_get_io_ptr")]
		public void* get_io_ptr ();
		[CCode (cname = "png_set_read_fn")]
		public void set_read_fn (void *io_ptr, RwFn read_data_fn);
		[CCode (cname = "png_set_sig_bytes")]
		public void set_sig_bytes (int num_bytes);
		[CCode (cname = "png_read_info")]
		public void read_info (Info info);
		[CCode (cname = "png_malloc")]
		public void* malloc (uint32 size);
		[CCode (cname = "png_free")]
		public void free (void *ptr);
		[CCode (cname = "png_read_image")]
		public void read_image ([CCode (array_length = false)] uint8*[] image);
	}

	[CCode (cname = "png_info", free_function = "")]
	[Compact]
	public class Info {
		[CCode (cname = "png_create_info_struct")]
		public Info (Struc png_ptr);

		public uint32 num_text;
		[CCode (array_length = false)] 
		public Text[] text;
	}

	[CCode (cname = "png_text", has_type_id = false, destroy_function = "")]
	public struct Text {
		string key;
		string text;
	}

	public int sig_cmp ([CCode (array_length = false, 
	                            array_null_terminated = true)] uint8[] sig, 
	                    size_t start, size_t num_to_check);

	public void destroy_read_struct (Struc** png_ptr_ptr, 
	                                 Info** info_ptr_ptr = null, 
	                                 Info** end_info_ptr_ptr = null);
}

