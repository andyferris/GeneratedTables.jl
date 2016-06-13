@Generated immutable Column{Name, T}
    :($Name::$T)
end

function Base.call{Name, T}(::Type{Column{Name}}, data::T)
    Column{Name,T}(data)
end

@inline name{Name}(::Column{Name}) = Name
@inline name{Name, T}(::Type{Column{Name,T}}) = Name
@inline name{C <: Column}(::Type{C}) = name(super(C))
@inline Base.eltype{Name, T}(::Column{Name,T}) = eltype(T)
@inline Base.eltype{Name, T}(::Type{Column{Name,T}}) = eltype(T)
@inline Base.eltype{C <: Column}(::Type{C}) = eltype(super(C))

# iterating
Base.start(col::Column) = start(col.(1))
Base.next(col::Column, state) = next(col.(1))
Base.done(col::Column, state) = done(col.(1))

# indexing
Base.endof(col::Column) = endof(col.(1))

Base.getindex(col::Column, i::Integer) = col.(1)[i]
Base.getindex{Name}(col::Column{Name}, inds) = Column{Name}(col.(1)[inds])

Base.setindex!(col::Column, v, i::Integer) = setindex!(col.(1), v, i)
Base.setindex!{Name}(col::Column{Name}, v::Cell{Name}, i::Integer) = setindex!(col.(1), v.(1), i)
Base.setindex!(col::Column, v, inds) = setindex!(col.(1), v, i)
Base.setindex!{Name}(col::Column{Name}, v::Column{Name}, inds) = setindex!(col.(1), v.(1), i)

Base.unsafe_getindex(col::Column, i::Integer) = Base.unsafe_getindex(col.(1), i)
Base.unsafe_getindex{Name}(col::Column{Name}, inds) = Column{Name}(Base.unsafe_getindex(col.(1), inds))

Base.unsafe_setindex!(col::Column, v, i::Integer) = Base.unsafe_setindex!(col.(1), v, i)
Base.unsafe_setindex!{Name}(col::Column{Name}, v::Cell{Name}, i::Integer) = Base.unsafe_setindex!(col.(1), v.(1), i)
Base.unsafe_setindex!(col::Column, v, inds) = Base.unsafe_setindex!(col.(1), v, i)
Base.unsafe_setindex!{Name}(col::Column{Name}, v::Column{Name}, inds) = Base.unsafe_setindex!(col.(1), v.(1), i)

# pushing, popping, etc
Base.pop!(col::Column{Name}) = pop!(col.(1))
Base.shift!(col::Column{Name}) = pop!(col.(1))

Base.push!(col::Column, v) = push!(col.(1), v)
Base.push!{Name}(col::Column{Name}, cell::Cell{Name}) = push!(col.(1), cell.(1))
Base.unshift!{Name}(col::Column, v) = unshift!(col.(1), v)
Base.unshift!{Name}(col::Column{Name}, cell::Cell{Name}) = unshift!(col.(1), cell.(1))
