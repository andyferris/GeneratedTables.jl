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
        str = "Row parameter 1 (Names) is expected to be a tuple of unique symbols, got $Names" # TODO: reinsert colons in symbols?
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

@inline Base.names{Names}(::Table{Names}) = Names
@inline Base.names{Names, Types}(::Type{Table{Names,Types}}) = Names
@inline Base.names{T <: Table}(::Type{T}) = names(super(T))
@inline eltypes{Names, Types}(::Table{Names,Types}) = Types
@inline eltypes{Names, Types}(::Type{Table{Names,Types}}) = Types
@inline eltypes{T <: Table}(::Type{T}) = eltypes(super(T))

@inline nrow(t::Table) = length(t.(1))
@inline ncol{Names}(::Table{Names}) = length(Names)

# iterating
# TODO don't assume all containers are compatible with each other... (e.g. different implementations of dictionaries).
# Probably should define some kind of table key for this

# TODO bad codegen. Probably *much* better to revert to direct integer indexing here.
# TODO still bad codegen. Perhaps inference is having a problem with t.(1), etc

Base.start(t::Table) = 1
@generated function Base.next{Names}(t::Table{Names}, state)
    exprs = [:(Base.unsafe_getindex(t.($i),state)) for i = 1:length(Names)]

    println(Expr(:tuple, Expr(:call, Row{Names}, exprs...), :(state + 1)))
    return Expr(:tuple, Expr(:call, Row{Names}, exprs...), :(state + 1))
end
Base.done(t::Table, state) = state > nrow(t)
