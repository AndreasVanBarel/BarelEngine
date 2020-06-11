# creation of the market
using Markets
using Gui

# creation of the market
market = Market("Test",100.0,0.1)

money = 1000.0
goods = 0.0

function buy(amount::Int)
    global money, goods
    cost = trade(market,amount)
    goods+=amount
    money-=cost
    gui_update(gui,market)
end

function sell(amount::Int)
    global money, goods
    cost = trade(market,-amount)
    goods-=amount
    money-=cost
    gui_update(gui,market)
end

gui = Gui.construct((::Int)->buy(1),(::Int)->sell(1))
draw(gui)

function gui_update(gui::GuiInstance, market::Market)
    p = price(market)
    buycost = sum(tradecost(market,1))
    sellgain = -sum(tradecost(market,-1))
    update(gui,p,buycost,sellgain,money,goods)
end

#gui_update(gui,market)

#close(gui)
#newwindow(gui)
