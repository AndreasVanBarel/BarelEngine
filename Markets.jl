module Markets

export Market, price, tradecost, trade
import Base.show

struct MarketFunction
    f::Function # f(x,y) = 0 gives all (x,y) that the market state can be in
    x::Function # Provides x as a function of y
    y::Function # Provides y as a function of x
    dfdx::Function # Provides ∂f/∂x(x,y)
    dfdy::Function # Provides ∂f/∂y(x,y)
end

# Constructs a standard MarketFun
function constructMarketFun(r::Float64)
    rsq = r^2
    f(x,y) = xy-rsq
    y(x) = rsq/x
    x(y) = rsq/y
    dfdx(x,y) = y
    dfdy(x,y) = x
    #dydx(x) = -rsq/x^2 # -y(x)/x
    #dydx(x,y) = -y/x
    MarketFunction(f,x,y,dfdx,dfdy)
end

mutable struct Market
    name::String
    state::Tuple{Float64,Float64} # (x,y) value of the MarketFunction below
    mf::MarketFunction # Detailes the state space of the market
    fee::Float64 # Percentage of sold goods that go to the market itself.
    xwealth::Float64 # Additional x in the market due to paid fees.
    ywealth::Float64 # Additional y in the market due to paid fees.
end
Market(name,size,fee) = Market(name,(size,size),constructMarketFun(size),fee,0.0,0.0)
#show(io::IO,::MIME"text/plain",m::Market) = println("Market "*m.name*" (state=$(m.state), price=$(price(m)))")

price(m::Market) = m.mf.dfdy(m.state...)/m.mf.dfdx(m.state...)

# Base tradecost without the fee
function tradecost(m::Market, amount) # amount>0: buying on the market, amount<0: selling on the market
    Δy = -amount # Δy>0: selling on the market, Δy<0: buying on the market
    x,y = m.state
    ynew = y+Δy
    xnew = m.mf.x(ynew)
    mf = m.mf
    if y+Δy <= 0
        net = Inf
    else
        net = xnew - x
    end
    net > 0 ? fee = net*m.fee : fee = -net*m.fee
    return net, fee, (xnew,ynew)
end

# trades on the market, returns the price paid (negative for receiving)
function trade(m::Market, amount)
    net,fee,state = tradecost(m, amount)
    m.state = state
    m.xwealth += fee
    return net + fee
end

end
