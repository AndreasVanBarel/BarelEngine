using Markets
using PyPlot

m = Market("Test",100.0,10.0,0.1)

dfun = demand(m)
sfun = supply(m)

p = price(m)
bid = price_upy(m)
ask = price_upx(m)

dnodes = LinRange(bid/3,bid,100)
snodes = LinRange(ask,3ask,100)

figure(1); clf();
plot(dnodes,dfun.(dnodes))
plot(snodes,sfun.(snodes))


Δy = demand(m,0.5) #quantity Δy to obtain a bid price of 0.5
trade(m,Δy)
price_upy(m)

Δy = supply(m,1.5) #quantity Δy to obtain an ask price of 1.5
trade(m,-Δy)
price_upx(m)

##
# Assume two markets of some good, with some trading ships in between. One small market exists on a remote location, the big market exists in some financial center

remote_market = Market("Remote planet ore",10.0,10.0,0.1) # small market
central_market = Market("Central planet ore",100.0,100.0,0.1) # has equal number of ores and money
miner_market = Market("Miner planet ore",10.0,100.0,0.1) # has 100 ores
markets = [miner_market, central_market, remote_market]

money = 1000.0
goods = 1000.0

function buy(market::Market, amount)
    global money, goods
    cost = trade(market,-amount)
    goods+=amount
    money-=cost
    return cost
end
buy(amount) = buy(remote_market,amount)

function sell(market::Market, amount)
    global money, goods
    cost = trade(market,amount)
    goods-=amount
    money-=cost
    return cost
end
sell(amount) = sell(remote_market,amount)


# ships check markets for profit
# route Miner-Central

# checks profits of buying s at market 1 and selling at market 2
function profit(m1::Market,m2::Market,s)
    -tradecost(m1,-s)[1] -tradecost(m2,s)[1]
end

connections = [(miner_market, central_market), (central_market, miner_market), (central_market, remote_market), (remote_market, central_market)]
trader_profit = 0

function simulate_traders(s)
    global trader_profit
    did_trade = false
    for con in connections
        m1,m2 = con
        if profit(m1,m2,s) > 0
            cost = trade(m1,-s)
            gain = -trade(m2,s)
            p = gain-cost
            trader_profit += p
            println("Traders moved $s goods from $(m1.name) to $(m2.name) for a profit of $p.")
            did_trade = true
        end
    end
    return did_trade
end

function simulate_traders(s,n)
    for i = 1:n
        traded = simulate_traders(s)
        traded || return
    end
end

function infos()
    info(miner_market)
    info()
end

simulate_traders(1,10); info.(markets)
