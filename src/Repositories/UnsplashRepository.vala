
public class UnsplashRepository : GLib.Object, IRepository {
    public Cancellable cancellable {get;set;}
    // TO DO : Insert elementary APP_ID
    const string APP_ID = "0386718809470cb13e17b21c5f5c37ad4bedfe6ea76548e4ea22095a8fc1129b";

    const string BASE_URL = "https://api.unsplash.com";
    const string RANDOM_PHOTO = BASE_URL+"/photos/random";
    const string LIST_PHOTOS = BASE_URL+"/photos/random";

    enum OrderBy {
        LASTEST,
        OLDEST,
        POPULAR
    }

    public async RemoteWallpaperContainer[]? get_images () {
        RemoteWallpaperContainer[] wallpapers = null;
        // var json = get_random_photo ();
        var json = list_photos (OrderBy.LASTEST, 20);

        switch (json.get_node_type ()) {
            case Json.NodeType.OBJECT:
                    wallpapers += build_container (json.get_object ());
                break;
            case Json.NodeType.ARRAY:
                json.dup_array ().foreach_element ((array, index, element) => {
                    wallpapers += build_container (element.get_object ());
                });
                break;
            case Json.NodeType.NULL:
                return null;
        }
        return wallpapers;
    }

    RemoteWallpaperContainer build_container (Json.Object wallpaper) {
        var user = wallpaper.get_object_member ("user");
        var url = wallpaper.get_object_member ("urls");

        return new RemoteWallpaperContainer (url.get_string_member ("full"), url.get_string_member ("thumb"),user.get_string_member ("name"));
    }

    Json.Node parse_json (string data) {
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (data);
        } catch (Error e) {
            print (_("Unable to parse the string: ")+e.message+"\n");
        }
        return parser.get_root ();
    }

    Json.Node get_random_photo () {
        Rest.Proxy proxy = new Rest.Proxy (BASE_URL+"/photos/random", false);
        Rest.ProxyCall call = proxy.new_call ();
        call.add_params (
            "client_id", APP_ID
        );

        try {
            call.run ();
        } catch (Error e) {
            warning (e.message);
        }
        var payload = call.get_payload ();
        print (payload+"\n");

        return parse_json (payload);
    }

    // TODO enable order_by
    Json.Node list_photos (OrderBy order_by, int max_itens = 10, int page = 1, string url = BASE_URL+"/photos") {
        Rest.Proxy proxy = new Rest.Proxy (url, false);
        Rest.ProxyCall call = proxy.new_call ();
        call.add_params (
            // "order_by", order_by,
            "page", page.to_string (),
            "per_page", max_itens.to_string (),
            "client_id", APP_ID
        );

        try {
            call.run ();
        } catch (Error e) {
            warning (e.message);
        }
        var payload = call.get_payload ();
        return parse_json (payload);
    }

    Json.Node list_curated_photos (OrderBy order_by, int max_itens = 10, int page = 1) {
        return list_photos (order_by, max_itens, page, BASE_URL+"/photos/curated");
    }
}
