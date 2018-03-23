/*-
 * Copyright (c) 2011-2017 elementary LLC. (https://github.com/elementary/switchboard-plug-pantheon-shell/)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Fernando da Silva Sousa
 *
 */

public class UnsplashProvider : GLib.Object, IProvider {
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

    public async RemoteWallpaperContainer[]? get_containers () {
        debug ("Getting images");
        RemoteWallpaperContainer[] wallpapers = null;
        // var json = get_random_photo ();
        var json = yield list_photos (OrderBy.LASTEST, 20);

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

    private Json.Node parse_json (string data) {
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (data);
        } catch (Error e) {
            print (_("Unable to parse the string: ")+e.message+"\n");
        }
        return parser.get_root ();
    }

    async Json.Node make_call (Rest.ProxyCall call) {
        string payload = "";

        try {
            var loop = new MainLoop ();
            call.run_async (() => {
                payload = call.get_payload ();
                loop.quit ();
            });

            loop.run ();
        } catch (Error e) {
            warning (e.message);
        }
        print (payload+"\n");

        return parse_json (payload);
    }

    async Json.Node get_random_photo () {
        Rest.Proxy proxy = new Rest.Proxy (BASE_URL+"/photos/random", false);
        Rest.ProxyCall call = proxy.new_call ();

        call.add_params (
            "client_id", APP_ID
        );

        return yield make_call (call);
    }

    // TODO enable order_by
    async Json.Node list_photos (OrderBy order_by, int max_itens = 10, int page = 1, string url = BASE_URL+"/photos") {
        Rest.Proxy proxy = new Rest.Proxy (url, false);
        Rest.ProxyCall call = proxy.new_call ();
        call.add_params (
            // "order_by", order_by,
            "page", page.to_string (),
            "per_page", max_itens.to_string (),
            "client_id", APP_ID
        );

        return yield make_call (call);
    }

    async Json.Node list_curated_photos (OrderBy order_by, int max_itens = 10, int page = 1) {
        return yield list_photos (order_by, max_itens, page, BASE_URL+"/photos/curated");
    }
}
