module Gui

export GuiInstance, construct, update, close, draw, newwindow
import Base.close

using WebIO
using Interact
using Blink


mutable struct GuiInstance
    window # Window of the Gui
    content # ui displayed in the window
    button_buy
    button_sell
end
draw(gui::GuiInstance) = body!(gui.window,gui.content)
close(gui::GuiInstance) = close(gui.window)
function newwindow(gui)
    close(gui.window)
    gui.window = Window()
    draw(gui)
end

# constructs a new GuiInstance
function construct(f_buy,f_sell)
    button_buy = button("Buy 1")
    button_sell = button("Sell 1")
    h_buy = on(f_buy,button_buy)
    h_sell = on(f_sell,button_sell)
    gui = GuiInstance(Window(),Node(:div),button_buy,button_sell)
    draw(gui)
    return gui
end

function update(gui::GuiInstance, price::Float64, buycost::Float64, sellgain::Float64, money::Float64, goods::Float64)
    gui.content = vbox(
            pad(1em, dom"p"("You have \$$(round(money; digits=2)) and $(round(goods; digits=2)) goods")),
            pad(1em, dom"p"("Price: $(round(price; digits=2))")),
            hbox(pad(1em, gui.button_buy), pad(1em, gui.button_sell)),
            hbox(pad(1em, dom"p"("For: $(round(buycost; digits=2))")),
                 pad(1em, dom"p"("For: $(round(sellgain; digits=2))")) )
         )
    draw(gui)
end


# Browser on port 8001
# using Mux
# WebIO.webio_serve(page("/", req -> ui), 8001)
end
