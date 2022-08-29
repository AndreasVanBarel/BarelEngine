module Markets

export Market, price, price_upx, price_upy, tradecost, trade, info, demand, supply, set_fee
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
function symmetricMarketFun()
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

# Constructs a standard MarketFun
function skewedMarketFun(r::Float64)
    r == 0 && return symmetricMarketFun()
    ϕ = 1+r
    μ = 1-r
    f(x,y,p) = x^ϕ*y^μ-p
    y(x,p) = (p/x^ϕ)^(1/μ)
    x(y,p) = (p/y^μ)^(1/ϕ)
    p(x,y) = x^ϕ*y^μ
    dfdx(x,y,p) = ϕ*x^r*y^μ
    dfdy(x,y,p) = μ*x^ϕ*y^-r
    MarketFunction(f,x,y,p,dfdx,dfdy)
end

mutable struct Market
    name::String
    x::Float64 # (x,y) value of the MarketFunction below
    y::Float64
    mf::MarketFunction # Detailes the state space of the market (if no fees are levied)
    upx::MarketFunction # Details the state space of the market when increasing x
    upy::MarketFunction # Details the state space of the market when increasing y
    fee::Float64 # Percentage of sold goods that go to the market itself.
end
Market(name,x,y,fee) = Market(name,x,y,symmetricMarketFun(),skewedMarketFun(-fee/2),skewedMarketFun(fee/2),fee)
#show(io::IO,m::Market) = println("Market "*m.name*" (x=$(m.x), y=$(m.y), price=$(price(m)))")
info(m::Market) = println("Market "*m.name*" (x=$(m.x), y=$(m.y), price=$(price(m)))")
price(m::Market, mf::MarketFunction) = mf.dfdy(m.x,m.y,mf.p(m.x,m.y))/mf.dfdx(m.x,m.y,mf.p(m.x,m.y)) # yields ∂x/∂y (cost of y in x)
price(m::Market) = price(m,m.mf) # yields ∂x/∂y (cost of y in x) in absence of fees
price_upx(m::Market) = price(m,m.upx)
price_upy(m::Market) = price(m,m.upy)

function set_fee(m::Market, fee::Float64)
    m.upx = skewedMarketFun(-fee/2)
    m.upy = skewedMarketFun(fee/2)
    m.fee = fee
end


# Generating supply and demand curves (i.e., orderbook curves)
function demand(m::Market) #upy relevant curve
    r = m.fee/2
    ϕ = 1+r
    μ = 1-r
    a = m.upy.p(m.x,m.y)
    dfun(p::Float64) = (μ/ϕ)^(ϕ/2)*sqrt(a/p^ϕ) - m.y
    return dfun
end
demand(m::Market,p::Float64) = demand(m)(p)

function supply(m::Market) #upx relevant curve
    r = -m.fee/2
    ϕ = 1+r
    μ = 1-r
    a = m.upx.p(m.x,m.y)
    sfun(p::Float64) = -(μ/ϕ)^(ϕ/2)*sqrt(a/p^ϕ) + m.y
    return sfun
end
supply(m::Market,p::Float64) = supply(m)(p)

# Checking whether two markets can make a profit, i.e., whether demand curve of one overlaps supply curve of the other, and if so, where that happens
function equilibrium_price(m1::Market, m2::Market)
    p1 = price(m1)
    p2 = price(m2)
    if p1 < p2
        mlow,mhigh = m1,m2
    else
        mlow,mhigh = m2,m1
    end
    supply(mlow)
    demand(mhigh)
    error("Not yet decently implemented")
end

# Tradecost
function tradecost(m::Market, Δy) # Δy>0: selling y to the market receiving x, Δy<0: buying y on the market for x
    ynew = m.y+Δy
    if Δy >= 0 # Market gains y in return for x
        xnew = m.upy.x(ynew,m.upy.p(m.x,m.y))
    else
        xnew = m.upx.x(ynew,m.upx.p(m.x,m.y))
    end
    if ynew <= 0
        Δx = Inf
    else
        Δx = xnew - m.x
    end
    return Δx, xnew, ynew
end

# trades on the market, returns the price paid (negative for receiving)
function trade(m::Market, Δy)
    Δx,xnew,ynew = tradecost(m, Δy)
    m.x = xnew
    m.y = ynew
    return Δx
end

end
