import Base.copy!

export unionAdd!, unionAdd
export unionSub!, unionSub
export intersectAdd!, intersectAdd
export delete!, delete

# Add values to d from others
function unionAdd!(d::Ngrams, others::Ngrams...)
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

function unionAdd(src::Ngrams, others::Ngrams...)
  unionAdd!(deepcopy(src), others...)
end

# Subtract values in others from d
function unionSub!(d::Ngrams, others::Ngrams...)
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

function unionSub(d::Ngrams, others::Ngrams...)
  unionSub!(deepcopy(d), others...)
end

# Add values to d from others only if keys from others are found in d
function intersectAdd!(d::Ngrams, others::Ngrams...)
  for other in others
    for (k, v) in other
      if haskey(d, k)
        d[k] += v
      end
    end
  end
  return d
end

function intersectAdd(d::Ngrams, others::Ngrams...)
  intersectAdd!(deepcopy(d), others...)
end

# Remove keys from d that are found in others
function delete!(d::Ngrams, others::Ngrams...)
  for other in others
    for (k, v) in other
      Base.delete!(d, k)
    end
  end
  return d
end

function delete(d::Ngrams, others::Ngrams...)
  delete!(deepcopy(d), others...)
end
