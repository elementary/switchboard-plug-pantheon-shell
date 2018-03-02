
public interface IRepository : GLib.Object {
    public abstract Cancellable cancellable {get;set;}
    public abstract async Gtk.FlowBoxChild[]? get_images ();
}
