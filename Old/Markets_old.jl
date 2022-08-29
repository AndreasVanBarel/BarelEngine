module Markets

export Market, price, tradecost, trade
import Base.show

struct MarketFunction
    f::Function # f(x,y,p) = 0 gives all (x,y) that the market state can be in, given parameters p
    x::Function # Provides x as a function of y,p
    y::Function # Provides y as a function of x,p
    p::Function # Provides p as a function of x,y
    dfdx::Function # Provides ∂f/∂x(x,y,p)
    dfdy::Function # Provides ∂f/∂y(x,y,p)
end

# Constructs a standard MarketFun
function constructMarketFun()
    f(x,y,p) = x*y-p
    y(x,p) = p/x
    x(y,p) = p/y
    p(x,y) = x*y
    dfdx(x,y,p) = y
    dfdy(x,y,p) = x
    #dydx(x,p) = -p/x^2 # -y(x,p)/x
    #dydx(x,y,p) = -y/x
    MarketFunction(f,x,y,p,dfdx,dfdy)
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
p(m::Market) = m.mf.p(m.x,m.y)
price(m::Market) = m.mf.dfdy(m.x,m.y,p(m))/m.mf.dfdx(m.x,m.y,p(m)) # yields ∂x/∂y, cost of y in x

# Base tradecost without the fee
function tradecost_old(m::Market, Δy) # Δy>0: selling y to the market receiving x, Δy<0: buying y on the market for x
    ynew = m.y+Δy
    xnew = m.mf.x(ynew,p(m))
    mf = m.mf
    if ynew <= 0
        Δx = Inf
    else
        Δx = xnew - m.x
    end
    Δx > 0 ? fee = Δx*m.fee : fee = -Δx*m.fee
    return Δx, fee, xnew, ynew
end

# Base tradecost without the fee
function tradecost_(m::Market, Δy) # Δy>0: selling y to the market receiving x, Δy<0: buying y on the market for x
    ynew = m.y+Δy
    xnew = m.mf.x(ynew,p(m))
    mf = m.mf
    if ynew <= 0
        Δx = Inf
    else
        Δx = xnew - m.x
    end
    return Δx, xnew, ynew
end

function tradecost(m::Market, Δy) # Δy>0: selling y to the market receiving x, Δy<0: buying y on the market for x
    Δx, xnew, ynew = tradecost_(m,Δy)
    Δy < 0 ? fee = tradecost_(m,Δy/(1-m.fee))[1]-Δx : fee = -Δx*m.fee
    return Δx, fee, xnew, ynew
end

# trades on the market, returns the price paid (negative for receiving)
function trade(m::Market, Δy)
    Δx,fee,xnew,ynew = tradecost(m, Δy)
    m.x = xnew + fee
    m.y = ynew
    return Δx + fee
end

end
