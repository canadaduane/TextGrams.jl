function each_file(fn::Function, path)
  if isdir(path)
    for file_or_dir in readdir(path)
      if !beginswith(file_or_dir, ".")
        fullpath = joinpath(path, file_or_dir)
        if isdir(fullpath)
          each_file(fn, fullpath)
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

function file_producer(paths)
  for p in paths
    each_file(p) do f
      produce(f)
    end
  end
end