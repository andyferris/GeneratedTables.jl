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


@inline colnames{Names}(::Row{Names}) = Names
@inline colnames{Names, Types <: Tuple}(::Type{Row{Names,Types}}) = Names
@inline colnames{Names}(::Type{Row{Names}}) = Names
@inline colnames{R <: Row}(::Type{R}) = colnames(super(R))
@inline eltypes{Names, Types <: Tuple}(::Row{Names,Types}) = Types
@inline eltypes{Names, Types <: Tuple}(::Type{Row{Names,Types}}) = Types
@inline eltypes{R <: Row}(::Type{R}) = eltypes(super(R))

# reordering
@generated function permutecols{Names1,Names2,Types}(r::Row{Names1,Types}, ::Type{Val{Names2}})
    if Names1 == Names2
        return :(r)
    else
        if !(isa(Names2, Tuple)) || eltype(Names2) != Symbol || length(Names2) != length(Names1) || length(Names2) != length(unique(Names2))
            str = "New column names $Names2 do not match existing names $Names1"
            return :(error($str))
        end

        order = permutator(Names1, Names2)

        exprs = [:(r.($(order[j]))) for j = 1:N]
        return Expr(:call, Row{Names1}, exprs...)
    end
end

@generated function getindex{Names}(r::Row{Names})
    exprs = [:(r.($j)) for j = 1:length(Names)]
    return Expr(:tuple, exprs...)
end

# Horizontally concatenate cells and rows into rows
@generated Base.hcat{Name}(c::Cell{Name}) = :(Row{$((Name,))}(c.(1)))
Base.hcat(r::Row) = r

@generated function Base.hcat(r1::Union{Cell,Row}, r2::Union{Cell,Row})
    names1 = (r1 <: Cell ? (colname(r1),) : colnames(r1))
    names2 = (r2 <: Cell ? (colname(r2),) : colnames(r2))

    if length(intersect(names1, names2)) != 0
        str = "Column names are not distinct. Got $names1 and $names2"
        return :(error($str))
    end

    newnames = (names1..., names2...)
    exprs = vcat([:(r1.($j)) for j = 1:length(names1)], [:(r2.($j)) for j = 1:length(names2)])

    return Expr(:call, Row{newnames}, exprs...)
end

Base.hcat(r1::Union{Cell,Row}, r2::Union{Cell,Row}, rs::Union{Cell,Row}...) = hcat(hcat(r1, r2), rs...)
