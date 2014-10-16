# Add values to d from others
function union_add!{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k, v) in other
      if haskey(d, k)
        d[k] += v
      else
        d[k] = v
      end
    end
  end
  return d
end

function union_add{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  union_add!(copy(d), others...)
end

# Add values to d from others only if keys from others are found in d
function intersect_add!{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k, v) in other
      if haskey(d, k)
        d[k] += v
      end
    end
  end
  return d
end

function intersect_add{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  intersect_add!(copy(d), others...)
end

# Remove keys from d that are found in others
function subtract_del!{K,V}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k, v) in other
      delete!(d, k)
    end
  end
  return d
end

function subtract_del{K,V}(d::Associative{K,V}, others::Associative{K,V}...)
  subtract_del!(copy(d), others...)
end
