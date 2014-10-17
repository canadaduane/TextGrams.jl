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

# Subtract values in others from d
function union_sub!{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k, v) in other
      if haskey(d, k)
        d[k] -= v
        if d[k] < 0
          d[k] = 0
        end
      end
    end
  end
  return d
end

function union_sub{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  union_subtract!(copy(d), others...)
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
function delete!{K,V}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k, v) in other
      delete!(d, k)
    end
  end
  return d
end

function delete{K,V}(d::Associative{K,V}, others::Associative{K,V}...)
  subtract_del!(copy(d), others...)
end
