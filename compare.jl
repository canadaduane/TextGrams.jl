using ArgParse
using TextGrams

global settings

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--verbose", "-v"
            help = "show progress updates"
            action = :store_true
        "--no-output"
            help = "don't show key/value result"
            action = :store_true
        "--baseline", "-b"
            help = "the baseline ngrams to use (a text file)"
            nargs = 1
        "--ngrams", "-n"
            help = "the N in ngrams (e.g. '3' to create up to 3-grams)"
            nargs = 1
            arg_type = Integer
            default = Integer[3]
        "FILES"
            help = "files or directories to cross compare, use 'X' to separate list A from list B"
            required = true
            nargs = '*'
    end

    return parse_args(s)
end

settings = parse_commandline()

function msg(m...)
  if settings["verbose"]
    println(m...)
  end
end

function maybe_timed(fn::Function, m...)
  msg(m...)
  if settings["verbose"]
    tic()
  end
  fn()
  if settings["verbose"]
    toc()
  end
end

baselinePath = settings["baseline"][1]

fileX, fileY = splitFileList(settings["FILES"], "X")
emptyLists = map(((f) -> length(f) == 0), {fileX, fileY})
if any(emptyLists)
  println("Two file lists are required. Separate the first list\n",
          "from the second with 'X', e.g.:\n\n",
          "file1.txt file2.txt X file3.txt file4.txt")
  exit(-1)
end

msg("baseline: ", baselinePath)
msg("files X: ", fileX)
msg("files Y: ", fileY)

for fx in @task(fileProducer(fileX))
  for fy in @task(fileProducer(fileY))
    println("files ", fx, ",", fy)
  end
end

baseline = Ngrams(open(baselinePath))


# baseline = ngramsOfTextFile(settings["baseline"][1], settings["baseline"][1], settings["ngrams"][1])

# println(baseline)
