@Generated 1:32 immutable Table{Names, Types <: Tuple}
    #println(Names)
    #println(Types)
    if !isa(Names, Tuple) || eltype(Names) != Symbol || length(Names) != length(unique(Names)) # Also rules out length-0
        str = "Table parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
        error(str)
    end
    N = length(Names)
    if length(Types.parameters) != N || reduce((a,b) -> a | !isa(b, DataType), false, Types.parameters)
        str = "Table parameter 2 (Types) is expected to be a Tuple{} of $N DataTypes, got $Types"
        error(str)
    end

    # Column containers should have a valid eltype
    for i = 1:N
        if eltype(Types.parameters[i]) == Types.parameters[i] # Probably should be more refined here...
            warn("Column $i storage type $(Types.parameters[i]) appears not to be a container")
        end
    end

    exprs = [:( $(Names[i])::$(Types.parameters[i]) ) for i = 1:N]
    return Expr(:block, exprs...)
end

Base.call{Names,T <: Tuple}(::Type{Table{Names,T}}, data::T) = Table{Names,T}(data...) # Constructed from a tuple (signature must match exactly...)

@generated function Base.call{Names}(::Type{Table{Names}}, data...)
    if !isa(Names, Tuple) || eltype(Names) != Symbol || length(Names) != length(unique(Names))
        str = "Table parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
        return :(error($str))
    end

    if length(Names) == length(data)
        return :(Table{Names, $(Expr(:curly, :Tuple, data...))}(data...))
    elseif length(data) == 1 && data[1] <: Tuple && length(Names) == length(data[1].parameters)  # Constructed from a tuple (with correct length)
        return :(Table{Names, $(data[1])}(data[1]...))
    else
        return :(error("Can't construct Table with $(length(Names)) columns with input $data"))
    end

end

@inline colnames{Names}(::Table{Names}) = Names
@inline colnames{Names, Types <: Tuple}(::Type{Table{Names,Types}}) = Names
@inline colnames{Names}(::Type{Table{Names}}) = Names
@inline colnames{T <: Table}(::Type{T}) = colnames(super(T))
@inline eltypes{Names, Types <: Tuple}(::Table{Names,Types}) = Types
@inline eltypes{Names, Types <: Tuple}(::Type{Table{Names,Types}}) = Types
@inline eltypes{T <: Table}(::Type{T}) = eltypes(super(T))

@inline nrow(t::Table) = length(t.(1))
@inline ncol{Names}(::Table{Names}) = length(Names)

# reordering
@generated function permutecols{Names1,Names2}(t::Table{Names1}, ::Type{Val{Names2}})
    if Names1 == Names2
        return :(t)
    else
        if !(isa(Names2, Tuple)) || eltype(Names2) != Symbol || length(Names2) != length(Names1) || length(Names2) != length(unique(Names2))
            str = "New column names $Names2 do not match existing names $Names1"
            return :(error($str))
        end

        order = permutator(Names1, Names2)

        exprs = [:(t.($(order[j]))) for j = 1:N]
        return Expr(:call, Table{Names2}, exprs...)
    end
end

function permutator{N}(names1::NTuple{N,Symbol}, names2::NTuple{N,Symbol})
    order = zeros(Int, N)
    for i = 1:N
        isfound = false
        for j = 1:N
            if names1[i] == names2[j]
                isfound = true
                order[j] = i
                break
            end
        end

        if !isfound
            str = "New column names $names2 do not match existing names $names1"
            return :(error($str))
        end
    end

    return order
end

# iterating

# TODO don't assume all containers are compatible with each other... (e.g. different implementations of dictionaries).
# Probably should define some kind of table key for this

# TODO very strong assumption about columns being of same length. Probably
# should check in start? And hope the user doesn't change the column sizes
# differently? Or do the safe thing and get the user to wrap it in @inbounds??

Base.start(t::Table) = 1
@generated function Base.next{Names}(t::Table{Names}, state)
    exprs = [:(Base.unsafe_getindex(t.($i),state)) for i = 1:length(Names)]
    return Expr(:tuple, Expr(:call, Row{Names}, exprs...), :(state + 1))
end
Base.done(t::Table, state) = state > nrow(t)

# indexing
Base.endof(t::Table) = nrow(t)
Base.length(t::Table) = nrow(t)
Base.size(t::Table) = (nrow(t),)
Base.size(t::Table, d) = size(t.(1), d)


@generated function getindex{Names}(t::Table{Names}, i::Integer)
    exprs = [:(Base.getindex(t.($c), i)) for c = 1:length(Names)]
    return Expr(:call, Row{Names}, exprs...)
end
@generated function getindex{Names}(t::Table{Names}, inds)
    exprs = [:(getindex(t.($c), inds)) for c = 1:length(Names)]
    return Expr(:call, Table{Names}, exprs...)
end

@generated function setindex!{Names1,Names2}(t::Table{Names1}, v::Row{Names2}, i::Integer)
    if Names1 == Names2
        exprs = [:(setindex!(t.($c), v.$(c), i)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    else
        if length(Names1) != length(Names2)
            str = "Cannot assign $(length(v.parameters)) columns to $(length(Names)) columns"
            return :(error($str))
        end

        order = permutator(Names1, Names2)
        exprs = [:(setindex!(t.($(order[c])), v.$(c), i)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    end
end
@generated function setindex!{Names}(t::Table{Names}, v::Tuple, i)
    if length(v.parameters) != length(Names)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(setindex!(t.($c), v.$(c), i)) for c = 1:length(Names)]
    return Expr(:block, exprs...)
end
@generated function setindex!{Names1,Names2}(t::Table{Names1}, v::Table{Names2}, inds)
    if Names1 == Names2
        exprs = [:(setindex!(t.($c), v.$(c), inds)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    else
        if length(Names1) != length(Names2)
            str = "Cannot assign $(length(v.parameters)) columns to $(length(Names)) columns"
            return :(error($str))
        end

        order = permutator(Names1, Names2)
        exprs = [:(setindex!(t.($(order[c])), v.$(c), inds)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    end
end


@generated function unsafe_getindex{Names}(t::Table{Names}, i::Integer)
    exprs = [:(Base.unsafe_getindex(t.($c), i)) for c = 1:length(Names)]
    return Expr(:call, Row{Names}, exprs...)
end
@generated function unsafe_getindex{Names}(t::Table{Names}, inds)
    exprs = [:(unsafe_getindex(t.($c), inds)) for c = 1:length(Names)]
    return Expr(:call, Table{Names}, exprs...)
end

@generated function unsafe_setindex!{Names1,Names2}(t::Table{Names1}, v::Row{Names2}, i::Integer)
    if Names1 == Names2
        exprs = [:(unsafe_setindex!(t.($c), v.$(c), i)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    else
        if length(Names1) != length(Names2)
            str = "Cannot assign $(length(v.parameters)) columns to $(length(Names)) columns"
            return :(error($str))
        end

        order = permutator(Names1, Names2)
        exprs = [:(unsafe_setindex!(t.($(order[c])), v.$(c), i)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    end
end
@generated function unsafe_setindex!{Names}(t::Table{Names}, v::Tuple, i)
    if length(v.parameters) != length(Names)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(unsafe_setindex!(t.($c), v.$(c), i)) for c = 1:length(Names)]
    return Expr(:block, exprs...)
end
@generated function unsafe_setindex!{Names1,Names2}(t::Table{Names1}, v::Table{Names2}, inds)
    if Names1 == Names2
        exprs = [:(unsafe_setindex!(t.($c), v.$(c), inds)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    else
        if length(Names1) != length(Names2)
            str = "Cannot assign $(length(v.parameters)) columns to $(length(Names)) columns"
            return :(error($str))
        end

        order = permutator(Names1, Names2)
        exprs = [:(unsafe_setindex!(t.($(order[c])), v.$(c), inds)) for c = 1:length(Names1)]
        return Expr(:block, exprs...)
    end
end


# push, pop, etc
@generated function Base.pop!{Names}(t::Table{Names})
    exprs = [:(pop!(t.($c))) for c = 1:length(Names)]
    return Expr(:call, Row{Names}, exprs...)
end

@generated function Base.shift!{Names}(t::Table{Names})
    exprs = [:(shift!(t.($c))) for c = 1:length(Names)]
    return Expr(:call, Row{Names}, exprs...)
end

@generated function Base.push!{Names}(t::Table{Names}, v::Tuple)
    if length(Names) != length(v.parameters)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(push!(t.($c), v.($c))) for c = 1:length(Names)]
    return Expr(:block, exprs..., :t)
end
@generated function Base.push!{Names1,Names2}(t::Table{Names1}, r::Row{Names2})
    order = permutator(Names1, Names2)
    exprs = [:(push!(t.($(order[c])), r.($c))) for c = 1:length(Names1)]
    return Expr(:block, exprs..., :t)
end

@generated function Base.unshift!{Names}(t::Table{Names}, v::Tuple)
    if length(Names) != length(v.parameters)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(unshift!(t.($c), v.($c))) for c = 1:length(Names)]
    return Expr(:block, exprs..., :t)
end
@generated function Base.unshift!{Names1,Names2}(t::Table{Names1}, r::Row{Names2})
    order = permutator(Names1, Names2)
    exprs = [:(unshift!(t.($(order[c])), r.($c))) for c = 1:length(Names1)]
    return Expr(:block, exprs..., :t)
end

@generated function Base.append!{Names}(t::Table{Names}, v::Tuple)
    if length(Names) != length(v.parameters)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(append!(t.($c), v.($c))) for c = 1:length(Names)]
    return Expr(:block, exprs..., :t)
end
@generated function Base.append!{Names1,Names2}(t::Table{Names1}, t2::Table{Names2})
    order = permutator(Names1, Names2)
    exprs = [:(append!(t.($(order[c])), t2.($c))) for c = 1:length(Names1)]
    return Expr(:block, exprs..., :t)
end

@generated function Base.prepend!{Names}(t::Table{Names}, v::Tuple)
    if length(Names) != length(v.parameters)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(prepend!(t.($c), v.($c))) for c = 1:length(Names)]
    return Expr(:block, exprs..., :t)
end
@generated function Base.prepend!{Names1,Names2}(t::Table{Names1}, t2::Table{Names2})
    order = permutator(Names1, Names2)
    exprs = [:(prepend!(t.($(order[c])), t2.($c))) for c = 1:length(Names1)]
    return Expr(:block, exprs..., :t)
end

@generated function Base.insert!{Names}(t::Table{Names}, i::Integer, v::Tuple)
    if length(Names) != length(v.parameters)
        str = "Cannot assign a $(length(v.parameters))-tuple to $(length(Names)) columns"
        return :(error($str))
    end
    exprs = [:(insert!(t.($c), i, v.($c))) for c = 1:length(Names)]
    return Expr(:block, exprs..., :t)
end
@generated function Base.insert!{Names1,Names2}(t::Table{Names1}, i::Integer, r::Row{Names2})
    order = permutator(Names1, Names2)
    exprs = [:(insert!(t.($(order[c])), i, r.($c))) for c = 1:length(Names1)]
    return Expr(:block, exprs..., :t)
end

@generated function Base.deleteat!{Names}(t::Table{Names}, i)
    exprs = [:(deleteat!(t.($c), i)) for c = 1:length(Names)]
    return Expr(:block, exprs..., :t)
end

@generated function Base.splice!{Names}(t::Table{Names}, i::Integer)
    exprs = [:(splice!(t.($c), i)) for c = 1:length(Names)]
    return Expr(:call, Row{Names}, exprs...)
end
@generated function Base.splice!{Names}(t::Table{Names}, i::Integer, v::Tuple)
    exprs = [:(splice!(t.($c), i, v.($c))) for c = 1:length(Names)]
    return Expr(:call, Row{Names}, exprs...)
end
@generated function Base.splice!{Names1,Names2}(t::Table{Names1}, i::Integer, v::Union{Row{Names2},Table{Names2}})
    order = permutator(Names2, Names1)
    exprs = [:(splice!(t.($c), i, v.($(order[c])))) for c = 1:length(Names1)]
    return Expr(:call, Row{Names1}, exprs...)
end
@generated function Base.splice!{Names}(t::Table{Names}, i)
    exprs = [:(splice!(t.($c), i)) for c = 1:length(Names)]
    return Expr(:call, Table{Names}, exprs...)
end
@generated function Base.splice!{Names}(t::Table{Names}, i, v::Tuple)
    exprs = [:(splice!(t.($c), i, v.($c))) for c = 1:length(Names)]
    return Expr(:call, Table{Names}, exprs...)
end
@generated function Base.splice!{Names1,Names2}(t::Table{Names1}, i, v::Union{Row{Names2},Table{Names2}})
    order = permutator(Names2, Names1)
    exprs = [:(splice!(t.($c), i, v.($(order[c])))) for c = 1:length(Names1)]
    return Expr(:call, Table{Names1}, exprs...)
end


# Vertically concatenate rows and tables into tables
@generated function Base.vcat{Names}(t1::Union{Row{Names}, Table{Names}})
    exprs = [:(vcat(t1.($c))) for c = 1:length(Names)]
    return Expr(:call, Table{Names}, exprs...)
end

@generated function Base.vcat{Names1, Names2}(t1::Union{Row{Names1}, Table{Names1}}, t2::Union{Row{Names2}, Table{Names2}})
    if Names1 == Names2
        exprs = [:(vcat(t1.($c), t2.($c))) for c = 1:length(Names1)]
        return Expr(:call, Table{Names1}, exprs...)
    else
        if length(Names1) != length(Names2)
            str = "Cannot match $(length(v.parameters)) columns to $(length(Names)) columns"
        end

        order = permutator(Names1, Names2)
        exprs = [:(vcat(t1.($c), t2.($(order[c])))) for c = 1:length(Names1)]
        return Expr(:call, Table{Names1}, exprs...)
    end
end

Base.vcat{Names1, Names2}(t1::Union{Row{Names1}, Table{Names1}}, t2::Union{Row{Names2}, Table{Names2}}, ts::Union{Row, Table}...) = vcat(vcat(t1, t2), ts...)

# Horizontally concatenate columns and tables into tables
@generated Base.hcat{Name}(c::Column{Name}) = :(Table{$((Name,))}(c.(1)))
Base.hcat(t::Table) = t

@generated function Base.hcat(r1::Union{Column,Table}, r2::Union{Column,Table})
    names1 = (r1 <: Column ? (colname(r1),) : colnames(r1))
    names2 = (r2 <: Column ? (colname(r2),) : colnames(r2))

    if length(intersect(names1, names2)) != 0
        str = "Column names are not distinct. Got $names1 and $names2"
        return :(error($str))
    end

    newnames = (names1..., names2...)
    exprs = vcat([:(r1.($j)) for j = 1:length(names1)], [:(r2.($j)) for j = 1:length(names2)])

    return Expr(:call, Table{newnames}, exprs...)
end

Base.hcat(t1::Union{Column,Table}, t2::Union{Column,Table}, ts::Union{Column,Table}...) = hcat(hcat(t1, t2), ts...)

# copy
@generated function Base.copy{Names}(t::Table{Names})
    exprs = [:(copy(t.($j))) for j = 1:length(Names)]
    return Expr(:call, Table{Names}, exprs...)
end
