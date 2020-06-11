module Markets

export Market, price, tradecost, trade
import Base.show

struct MarketFunction
    f::Function # f must be a positive and non-decreasing function within domain
    int::Function
    domain::Tuple{Float64,Float64}
end
(mf::MarketFunction)(Δ) = mf.f(Δ)
# Constructs a standard MarketFun
function constructMarketFun(r::Float64)
    f(x) = (r+x)/(r-x)
    If(x) = -x-2*r*log(r-x)
    dom_f = (-r,r)
    MarketFunction(f,If,dom_f)
end

mutable struct Market
    name::String
    state::Float64 # Net quantity bought from the market
    mf::MarketFunction # Gives price given Δ
    fee::Float64 # Percentage of sold goods that go to the market itself.
    money::Float64 # Money in the market due to paid fees.
end
Market(name,size,fee) = Market(name,0.0,constructMarketFun(size),fee,0.0)
#show(io::IO,::MIME"text/plain",m::Market) = println("Market "*m.name*" (state=$(m.state), price=$(price(m)))")

price(m::Market) = m.mf(m.state)

# Base tradecost without the fee
function tradecost(m::Market, Δ) # Δ>0: buying on the market, Δ<0: selling on the market
    if Δ>0 #buying
        if m.state+Δ >= m.mf.domain[2]
            net = Inf
        else
            net = (m.mf.int(m.state+Δ)-m.mf.int(m.state))
        end
    else #selling
        if m.state+Δ <= m.mf.domain[1]
            net = (m.mf.int(m.mf.domain[1])-m.mf.int(m.state))
        else
            net = (m.mf.int(m.state+Δ)-m.mf.int(m.state))
        end
    end
    net > 0 ? fee = net*m.fee : fee = -net*m.fee
    return net, fee
end

# trades on the market, returns the price paid (negative for receiving)
function trade(m::Market, Δ)
    net,fee = tradecost(m, Δ)
    m.state+=Δ
    m.money+=fee
    return net + fee
end

end
