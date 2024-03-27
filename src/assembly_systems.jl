struct AssemblySystem{T<:Integer, F<:AbstractFloat, G<:AbstractGeometry{T,F}}
    intmat::BitMatrix
    monomers::Vector{Structure{T,F}}
    geometries::Vector{G}
    n_species::Integer
    n_edges::Integer
    _sides_sum::Vector{T}
end

function AssemblySystem(interactions::AbstractMatrix{<:Integer}, geometries::Vector{G}, face_labels=nothing) where {T,F,G<:AbstractGeometry{T,F}}
    interactions = convert(Matrix{T}, interactions)
    n_species = length(geometries)

    sides = [length(geom) for geom in geometries]
    n_sides = sum(sides; init=0)
    n_edges = size(interactions, 1)

    monomers = Structure{T,F}[]
    sides_sum = cumsum(sides)
    last_label = 0

    for i in 1:n_species
        if isnothing(face_labels)
            face_labels = collect(1:sides[i])
        end

        fl = convert(Vector{T}, face_labels .+ last_label)
        m = create_monomer(geometries[i], T(i), fl)
        push!(monomers, m)

        last_label = fl[end]
    end

    interaction_matrix = falses(n_sides, n_sides)
    for edge in eachrow(interactions)
        a, b, c, d = edge
        i, j = irg_flatten(a, b, sides_sum), irg_flatten(c, d, sides_sum)
        interaction_matrix[i, j] = interaction_matrix[j, i] = true
    end

    return AssemblySystem{T,F,G}(interaction_matrix, monomers, geometries, n_species, n_edges, sides_sum)
end
function AssemblySystem(interactions::AbstractMatrix{<:Integer}, geometry::AbstractGeometry{T,F}, face_labels=nothing) where {T,F}
    n_species = maximum(interactions[:, [1, 3]])
    geometries = [geometry for _ in 1:n_species]
    return AssemblySystem(interactions, geometries, face_labels)
end

Base.size(A::AssemblySystem) = A.n_species, A.n_edges
Base.show(io::Core.IO, A::AssemblySystem{T,F}) where {T, F} = println(io, "$(size(A)) AssemblySytem{$T,$F}")