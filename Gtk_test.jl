module Gtk_test

export test
using Gtk

function test()
    win = GtkWindow("My First Gtk.jl Program", 400, 200)
    b = GtkButton("Click Me")
    push!(win,b)
    showall(win)
    return win
end

end
