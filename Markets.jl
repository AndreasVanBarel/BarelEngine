module Markets

export Market, price, tradecost, trade
import Base.show

struct MarketFunction
    f::Function # f(x,y,p) = 0 gives all (x,y) that the market state can be in, given parameters p
    x::Function # Provides x as a function of y,p
    y::Function # Provides y as a function of x,p
    dfdx::Function # Provides ∂f/∂x(x,y,p)
    dfdy::Function # Provides ∂f/∂y(x,y,p)
end

# Constructs a standard MarketFun
function constructMarketFun()
    f(x,y,p) = xy-p
    y(x,p) = p/x
    x(y,p) = p/y
    dfdx(x,y,p) = y
    dfdy(x,y,p) = x
    #dydx(x,p) = -p/x^2 # -y(x,p)/x
    #dydx(x,y,p) = -y/x
    MarketFunction(f,x,y,dfdx,dfdy)
end

mutable struct Market
    name::String
    x::Float64 # (x,y) value of the MarketFunction below
    y::Float64
    mf::MarketFunction # Detailes the state space of the market
    fee::Float64 # Percentage of sold goods that go to the market itself.
end
Market(name,x,y,fee) = Market(name,x,y,constructMarketFun(),fee)
#show(io::IO,::MIME"text/plain",m::Market) = println("Market "*m.name*" (state=$(m.state), price=$(price(m)))")
@inline p(m::Market) = m.x*m.y
price(m::Market) = m.mf.dfdy(m.x,m.y,p(m))/m.mf.dfdx(m.x,m.y,p(m))

# Base tradecost without the fee
function tradecost(m::Market, amount) # amount>0: buying on the market, amount<0: selling on the market
    Δy = -amount # Δy>0: selling on the market, Δy<0: buying on the market
    ynew = m.y+Δy
    xnew = m.mf.x(ynew,p(m))
    mf = m.mf
    if m.y+Δy <= 0
        net = Inf
    else
        net = xnew - m.x
    end
    net > 0 ? fee = net*m.fee : fee = -net*m.fee
    return net, fee, xnew, ynew
end

# trades on the market, returns the price paid (negative for receiving)
function trade(m::Market, amount)
    net,fee,xnew,ynew = tradecost(m, amount)
    m.x = xnew + fee
    m.y = ynew
    return net + fee
end

end
