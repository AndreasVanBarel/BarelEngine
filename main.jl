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
    return cost
end

function sell(amount::Int)
    global money, goods
    cost = trade(market,-amount)
    goods-=amount
    money-=cost
    gui_update(gui,market)
    return cost
end

gui = Gui.construct(buy,sell)
draw(gui)

function gui_update(gui::GuiInstance, market::Market)
    p = price(market)
    buycost1 = sum(tradecost(market,1)[1:2])
    sellgain1 = -sum(tradecost(market,-1)[1:2])
    buycost10 = sum(tradecost(market,10)[1:2])
    sellgain10 = -sum(tradecost(market,-10)[1:2])
    update(gui,p,buycost1,sellgain1,buycost10,sellgain10,money,goods)
end

gui_update(gui,market)

#close(gui)
#newwindow(gui)
