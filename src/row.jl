@Generated 1:32 immutable Row{Names, Types <: Tuple}
    if !isa(Names, Tuple) || eltype(Names) != Symbol || length(Names) != length(unique(Names))
        str = "Row parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
        error(str)
    end
    N = length(Names)
    if length(Types.parameters) != N || reduce((a,b) -> a | !isa(b, DataType), false, Types.parameters)
        str = "Row parameter 2 (Types) is expected to be a Tuple{} of $N DataTypes, got $Types"
        error(str)
    end

    exprs = [:( $(Names[i])::$(Types.parameters[i]) ) for i = 1:N]
    return Expr(:block, exprs...)
end

Base.call{Names,T <: Tuple}(::Type{Row{Names,T}}, data::T) = Row{Names,T}(data...) # Constructed from a tuple (signature must match...)

@generated function Base.call{Names}(::Type{Row{Names}}, data...)
    if !isa(Names, Tuple) || eltype(Names) != Symbol || length(Names) != length(unique(Names))
        str = "Row parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
        return :(error($str))
    end

    if length(Names) == length(data)
        return quote
            $(Expr(:meta,:inline))
            Row{Names, $(Expr(:curly, :Tuple, data...))}(data...)
        end
    elseif length(data) == 1 && data[1] <: Tuple && length(Names) == length(data[1].parameters)  # Constructed from a tuple (with correct length)
        return :(Row{Names, $(data[1])}(data[1]...))
    else
        return :(error("Can't construct Row with $(length(Names)) columns with input $data"))
    end
end


@inline Base.names{Names}(::Row{Names}) = Names
@inline Base.names{Names, Types}(::Type{Row{Names,Types}}) = Names
@inline Base.names{R <: Row}(::Type{R}) = names(super(R))
@inline eltypes{Names, Types}(::Row{Names,Types}) = Types
@inline eltypes{Names, Types}(::Type{Row{Names,Types}}) = Types
@inline eltypes{R <: Row}(::Type{R}) = eltypes(super(R))
