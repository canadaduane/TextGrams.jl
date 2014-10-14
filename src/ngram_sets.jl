function union_add!{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k,v) in other
      if haskey(d, k)
        d[k] += v
      else
        d[k] = v
      end
    end
  end
  return d
end

function intersect_add!{K,V <: Number}(d::Associative{K,V}, others::Associative{K,V}...)
  for other in others
    for (k,v) in other
      if haskey(d, k)
        d[k] += v
      end
    end
  end
  return d
end
