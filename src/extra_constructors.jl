# These are a workaround for splatting penalty on 0.4.5

for i = 1:32
    sig = [Symbol("_x_$j") for j = 1:i]

    expr =  Expr(:stagedfunction, Expr(:call, :(Base.call{Names}), :(::Type{Row{Names}}), sig...),
        Expr(:block,
            :(if !isa(Names, Tuple)
                str = "Row parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
                return :(error($str))
            end),
            :(newtype = Row{Names, $(Expr(:curly, :Tuple, sig...))}),
            Expr(:return, Expr(:quote, Expr(:block, Expr(:meta, :inline), Expr(:call, Expr(:$,:newtype), sig...))))))

    eval(expr)

    expr =  Expr(:stagedfunction, Expr(:call, :(Base.call{Names}), :(::Type{Table{Names}}), sig...),
        Expr(:block,
            :(if !isa(Names, Tuple)
                str = "Table parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
                return :(error($str))
            end),
            :(newtype = Table{Names, $(Expr(:curly, :Tuple, sig...))}),
            Expr(:return, Expr(:quote, Expr(:block, Expr(:meta, :inline), Expr(:call, Expr(:$,:newtype), sig...))))))

    eval(expr)
end
