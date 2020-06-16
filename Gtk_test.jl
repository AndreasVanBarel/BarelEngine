using Gtk

## Button test
win = GtkWindow("Gtk.jl Window", 400, 200)

hbox = GtkButtonBox(:h)
push!(win, hbox)

button_cancel = GtkButton("Cancel")
button_ok = GtkButton("OK")
button_mouse = GtkButton("Pick a mouse button")
push!(hbox, button_cancel)
push!(hbox, button_ok)
push!(hbox, button_mouse)


function on_button_clicked(w)
  button_text = get_gtk_property(w, :label, String)
  println("The button $button_text was clicked")
end
signal_connect(on_button_clicked, button_cancel, "clicked")
signal_connect(on_button_clicked, button_ok, "clicked")

id = signal_connect(button_mouse, "button-press-event") do widget, event
    println("You pressed button ", event.button)
end

showall(win)


## Canvas test
using Gtk
c = @GtkCanvas()
win = GtkWindow(c,"Canvas")

@guarded draw(c) do widget
    ctx = getgc(c)
    h = Gtk.height(c)
    w = Gtk.width(c)
    # Paint red rectangle
    rectangle(ctx, 0, 0, w, h/2)
    set_source_rgb(ctx, 1, 0, 0)
    fill(ctx)
    # Paint blue rectangle
    rectangle(ctx, 0, 3h/4, w, h/4)
    set_source_rgb(ctx, 0, 0, 1)
    fill(ctx)
end
show(c)

c.mouse.button1press = @guarded (widget, event) -> begin
    ctx = getgc(widget)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, event.x, event.y, 5, 0, 2pi)
    stroke(ctx)
    reveal(widget)
end
