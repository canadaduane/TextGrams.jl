# Load initial ArgParse library to get settings. This is so we can fail quickly
# if arguments are not passed correctly.
using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--verbose", "-v"
            help = "show progress updates"
            action = :store_true
        "--chunk-size", "-c"
            help = "number of words per chunk (defaults to 1000)"
            arg_type = Integer
            default = 1000
        "--ngrams", "-n"
            help = "the N in ngrams (e.g. '5' to create up to 5-grams)"
            arg_type = Integer
            default = 5
        "--model", "-m"
            help = "the Language Model (arpa, bin) to use (defaults to model.bin)"
            arg_type = String
            default = "model.bin"
        "FILES"
            help = "files or directories to cross compare, use 'X' to separate list A from list B"
            required = true
            nargs = '*'
    end

    return parse_args(s)
end

settings = parse_commandline()

# include: msg, maybe_timed
include("utils.jl")

msg("N set to ", settings["ngrams"])

# Load the rest of the libraries, now that we've parsed the command line
msg("Loading TextGrams...")
using TextGrams

fileX, fileY = splitFileList(settings["FILES"], "X")
emptyLists = map(((f) -> length(f) == 0), {fileX, fileY})
if any(emptyLists)
  println("Two file lists are required. Separate the first list\n",
          "from the second with 'X', e.g.:\n\n",
          "file1.txt file2.txt X file3.txt file4.txt")
  exit(-1)
end

msg("Using files X: ", fileX)
msg("Using files Y: ", fileY)

# msg("Loading DBI...")
# using DBI
# msg("Loading PostgreSQL...")
# using PostgreSQL
msg("Loading PyCall...")
using PyCall
msg("Loading kenlm...")
@pyimport kenlm

if isfile(settings["model"])
  model = kenlm.LanguageModel(settings["model"])
else
  println(STDERR, "Unable to load Language Model: ", settings["model"])
  exit(-1)
end

function query(model, ngrams)
  Float64[model[:score](ng) for ng in collect(keys(ngrams))]
end

function fname(filepath)
  replace(basename(filepath), r"\.txt|\.md$", "")
end

# connect(Postgres, "localhost", "duane", "", "wordtree", 5432) do conn
  doneX = String[]
  for fx in @task(fileProducer(fileX))
    dx = Document(open(fx), fx)
    dxChunks = splitDocument(dx, settings["chunk-size"])

    for fy in @task(fileProducer(fileY))
      dy = Document(open(fy), fy)
      dyChunks = splitDocument(dy, settings["chunk-size"])

      if fy in doneX
        println("already compared ", fx, " and ", fy)
      else
        # println("Comparing ", fx, " and ", fy, "...")
        for cxi in 1:length(dxChunks)
          chunkX = dxChunks[cxi]
          # println("  chunk X: ", cxi, " ('", chunkX.title, "'), ")
          ngramX = Ngrams(chunkX, settings["ngrams"])
          for cyi in 1:length(dyChunks)
            chunkY = dyChunks[cyi]
            # println("  chunk Y: ", cyi, " ('", chunkY.title, "')")
            ngramY = Ngrams(chunkY, settings["ngrams"])

            commonNgrams = intersectAdd(ngramX, ngramY)

            result = query(model, commonNgrams)
            # println("result", result)
            score = mean(result)
            # println("  score: ", score)
            # println(score, "\t", fx, "\t", fname(fx), "\t", fy, "\t", fname(fy), "\t", cxi, "\t", chunkX.title, "\t", cyi, "\t", chunkY.title, "\t")
            println(score, "\t", fname(fx), "\t", fname(fy), "\t", cxi, "\t", chunkX.title, "\t", cyi, "\t", chunkY.title, "\t")
          end
        end
      end
    end
    push!(doneX, fx)
  end

#   stmt = prepare(conn, "SELECT 1::bigint, 2.0::double precision, 'foo'::character varying, " *
#                      "'foo'::character(10);")
#   result = execute(stmt)
#   for row in result
#       println(row)
#   end
# end
