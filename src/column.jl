@Generated 1 immutable Column{Name, T}
    if !isa(Name, Symbol)
        str = "Column parameter 1 (Name) is expected to be a symbol, got $Name"
        return :(error(str))
    end

    if !isa(T, DataType)
        str = "Column parameter 2 (T) is expected to be a DataType, got $T"
        return :(error(str))
    end

    if eltype(T) == T # Probably should be more refined here...
        warn("Column storage type $T appears not to be a container")
    end

    :($Name::$T)
end

function Base.call{Name, T}(::Type{Column{Name}}, data::T)
    Column{Name,T}(data)
end

@inline colname{Name}(::Column{Name}) = Name
@inline colname{Name, T}(::Type{Column{Name,T}}) = Name
@inline colname{C <: Column}(::Type{C}) = colname(super(C))
@inline Base.eltype{Name, T}(::Column{Name,T}) = eltype(T)
@inline Base.eltype{Name, T}(::Type{Column{Name,T}}) = eltype(T)
@inline Base.eltype{C <: Column}(::Type{C}) = eltype(super(C))

# iterating
Base.start(col::Column) = start(col.(1))
Base.next(col::Column, state) = next(col.(1), state)
Base.done(col::Column, state) = done(col.(1), state)

# indexing
Base.endof(col::Column) = endof(col.(1))
Base.length(col::Column) = length(col.(1))
Base.size(col::Column) = size(col.(1))
Base.size(col::Column, d) = size(col.(1), d)


Base.getindex(col::Column, i::Integer) = col.(1)[i]
Base.getindex{Name}(col::Column{Name}, inds) = Column{Name}(col.(1)[inds])

Base.setindex!{Name}(col::Column{Name}, v, i::Integer) = setindex!(col.(1), v, i)
Base.setindex!{Name}(col::Column{Name}, cell::Cell{Name}, i::Integer) = setindex!(col.(1), cell.(1), i)
Base.setindex!{Name}(col::Column{Name}, cell::Cell, i::Integer) = error("Column with name $Name don't match cell with name $(name(cell))")
Base.setindex!{Name}(col::Column{Name}, v, inds) = setindex!(col.(1), v, i)
Base.setindex!{Name}(col::Column{Name}, col2::Column, inds::Integer) = error("Attempted scalar setindex! with a non-scalar value") # ambiguity
Base.setindex!{Name}(col::Column{Name}, col2::Column{Name}, inds::Integer) = error("Attempted scalar setindex! with a non-scalar value") # ambiguity
Base.setindex!{Name}(col::Column{Name}, col2::Column{Name}, inds)  = setindex!(col.(1), col2.(1), i)
Base.setindex!{Name}(col::Column{Name}, col2::Column, inds) = error("Column with name $Name don't match column with name $(name(col2))")


Base.unsafe_getindex(col::Column, i::Integer) = Base.unsafe_getindex(col.(1), i)
Base.unsafe_getindex{Name}(col::Column{Name}, inds) = Column{Name}(Base.unsafe_getindex(col.(1), inds))

Base.unsafe_setindex!{Name}(col::Column{Name}, v, i::Integer) = Base.unsafe_setindex!(col.(1), v, i)
Base.unsafe_setindex!{Name}(col::Column{Name}, cell::Cell{Name}, i::Integer) = Base.unsafe_setindex!(col.(1), cell.(1), i)
Base.unsafe_setindex!{Name}(col::Column{Name}, cell::Cell, i::Integer) = error("Column with name $Name don't match cell with name $(name(cell))")
Base.unsafe_setindex!{Name}(col::Column{Name}, col2::Column, inds::Integer) = error("Attempted scalar setindex! with a non-scalar value") # ambiguity
Base.unsafe_setindex!{Name}(col::Column{Name}, col2::Column{Name}, inds::Integer) = error("Attempted scalar setindex! with a non-scalar value") # ambiguity
Base.unsafe_setindex!{Name}(col::Column{Name}, v, inds) = Base.unsafe_setindex!(col.(1), v, i)
Base.unsafe_setindex!{Name}(col::Column{Name}, col2::Column{Name}, inds) = Base.unsafe_setindex!(col.(1), col2.(1), i)
Base.unsafe_setindex!{Name}(col::Column{Name}, col2::Column, inds) = error("Column with name $Name don't match column with name $(name(col2))")

# pushing, popping, etc
Base.pop!(col::Column) = pop!(col.(1))
Base.shift!(col::Column) = pop!(col.(1))

Base.push!(col::Column, v) = push!(col.(1), v)
Base.push!{Name}(col::Column{Name}, cell::Cell{Name}) = push!(col.(1), cell.(1))
Base.push!{Name}(col::Column{Name}, cell::Cell) = error("Column with name $Name don't match cell with name $(name(cell))")
Base.unshift!(col::Column, v) = unshift!(col.(1), v)
Base.unshift!{Name}(col::Column{Name}, cell::Cell{Name}) = unshift!(col.(1), cell.(1))
Base.unshift!{Name}(col::Column{Name}, cell::Cell) = error("Column with name $Name don't match cell with name $(name(cell))")

# append!/prepend!

# Concatenate cells and columns into colums
Base.vcat{Name}(c1::Union{Cell{Name}, Column{Name}}) = Column{Name}(vcat(c1.(1)))
Base.vcat{Name}(c1::Union{Cell{Name}, Column{Name}}, c2::Union{Cell{Name}, Column{Name}}) = Column{Name}(vcat(c1.(1),c2.(1)))
Base.vcat{Name}(c1::Union{Cell{Name}, Column{Name}}, c2::Union{Cell{Name}, Column{Name}}, cs::Union{Cell{Name}, Column{Name}}...) = vcat(Column{Name}(vcat(c1.(1), c2.(1))), cs...)

# Otherwise, names don't match...
Base.vcat(x::Union{Cell,Column}...) = error("Column names $(ntuple(i->name(x[i]),length(x))) don't match")
