module Gui

export GuiInstance, construct, update, close, draw, newwindow
import Base.close

using WebIO
using Interact
using Blink


mutable struct GuiInstance
    window # Window of the Gui
    content # ui displayed in the window
    button_buy1
    button_sell1
    button_buy10
    button_sell10
end
draw(gui::GuiInstance) = body!(gui.window,gui.content)
close(gui::GuiInstance) = close(gui.window)
function newwindow(gui)
    close(gui.window)
    gui.window = Window()
    draw(gui)
end

# constructs a new GuiInstance
function construct(buy,sell)
    f_buy1 = (::Int)->buy(1)
    f_sell1 = (::Int)->sell(1)
    button_buy1 = button("Buy 1")
    button_sell1 = button("Sell 1")
    h_buy1 = on(f_buy1,button_buy1)
    h_sell1 = on(f_sell1,button_sell1)
    f_buy10 = (::Int)->buy(10)
    f_sell10 = (::Int)->sell(10)
    button_buy10 = button("Buy 10")
    button_sell10 = button("Sell 10")
    h_buy10 = on(f_buy10,button_buy10)
    h_sell10 = on(f_sell10,button_sell10)
    gui = GuiInstance(Window(),Node(:div),button_buy1,button_sell1,button_buy10,button_sell10)
    draw(gui)
    return gui
end

function update(gui::GuiInstance, price::Float64, buycost1::Float64, sellgain1::Float64, buycost10::Float64, sellgain10::Float64, money::Float64, goods::Float64)
    gui.content = vbox(
            pad(1em, dom"p"("You have \$$(round(money; digits=2)) and $(round(goods; digits=2)) goods")),
            pad(1em, dom"p"("Price: $(round(price; digits=2))")),
            hbox(pad(1em, gui.button_buy1), pad(1em, gui.button_sell1)),
            hbox(pad(1em, dom"p"("For: $(round(buycost1; digits=5))")),
                 pad(1em, dom"p"("For: $(round(sellgain1; digits=5))"))),
            hbox(pad(1em, gui.button_buy10), pad(1em, gui.button_sell10)),
            hbox(pad(1em, dom"p"("For: $(round(buycost10; digits=5))")),
                 pad(1em, dom"p"("For: $(round(sellgain10; digits=5))")))
         )
    draw(gui)
end


# Browser on port 8001
# using Mux
# WebIO.webio_serve(page("/", req -> ui), 8001)
end
