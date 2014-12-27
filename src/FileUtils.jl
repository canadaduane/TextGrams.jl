export eachFile, fileProducer, splitFileList

function eachFile(fn::Function, path)
  if isdir(path)
    for file_or_dir in readdir(path)
      if !beginswith(file_or_dir, ".")
        fullpath = joinpath(path, file_or_dir)
        if isdir(fullpath)
          eachFile(fn, fullpath)
        else
          fn(fullpath)
        end
      end
    end
  elseif isfile(path)
    fn(path)
  else
    error("File or directory not found: $path")
  end
end

function fileProducer(paths)
  for p in paths
    eachFile(p) do f
      produce(f)
    end
  end
end

function splitFileList(list, separator="--")
  l1 = eltype(list)[]
  l2 = eltype(list)[]
  markerFound = false
  for i in 1:length(list)
    if markerFound
      push!(l2, list[i])
    else
      if list[i] == separator
        markerFound = true
      else
        push!(l1, list[i])
      end
    end
  end
  return (l1, l2)
end