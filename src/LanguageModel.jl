export WordResult, RowResult
export query, queryRows, queryCustom

type LMConfig
  lm::String
  query::String
  function LMConfig(lm=:ENV, qry=:ENV)
    lmPath    = getenv("LM_PATH", lm, "/var/kenlm/default.bin")
    queryPath = getenv("LM_QUERY_BIN", qry, "/usr/local/bin/query")
    if !isfile(lmPath)
      error("LM language model '$(lmPath)' not found")
    end
    if !isexecutable(queryPath)
      error("LM query binary '$(queryPath)' not found or is not executable")
    end
    new(lmPath, queryPath)
  end
end

type WordResult
  word::ASCIIString
  vocab::Integer
  ngramLength::Integer
  probability::Float32
end

type RowResult
  wordResults::Array{WordResult}
  totalProbability::Float32
  outOfVocabulary::Integer
end

function getenv(key, overrideValue, defaultValue="")
  if overrideValue == :ENV
    if haskey(ENV, key)
      ENV[key]
    else
      defaultValue
    end
  else
    overrideValue
  end
end

function WordResult(result::ASCIIString)
  parts = split(result, " ")
  if length(parts) != 3
    error("Unparsable WordResult: $(result)")
  end
  word, vocab = split(parts[1], "=")

  WordResult(word, int(vocab), int(parts[2]), float(parts[3]))
end

function RowResult(result::ASCIIString)
  parts = split(result, "\t")
  if length(parts) <= 1
    error("Expected RowResult to have at least one WordResult: $(result)")
  end
  totals = split(replace(parts[end], ": ", ":"), " ")

  wordResults = [WordResult(convert(ASCIIString, r)) for r in parts[1:end-1]]

  totalProbabilityParts = split(totals[1], ":")
  outOfVocabularyParts = split(totals[2], ":")
  RowResult(
    wordResults,
    float(totalProbabilityParts[2]),
    int(outOfVocabularyParts[2]))
end

function queryCustom(eachLine::Function, phraseList::Array{ASCIIString}, config=LMConfig())
  (so, si, pr) = readandwrite(`$(config.query) -n $(config.lm)`)

  pList = map(phraseList) do phrase
    replace(phrase, "\n", "")
  end

  # Send list of words to (Ken)LM query
  # TODO: make this async
  i = 1
  for phrase in pList # filter(p -> p != "", phraseList)
    # println(i, ". ", phrase)
    write(si, phrase * "\n")
    i += 1
  end
  close(si)

  # println("================")
  # println(" END OF PHRASES")
  # println("================")

  results = Dict{ASCIIString, Any}()
  for i in range(1, length(pList))
    result = chomp(readline(so))
    # println(i, ". ", result)
    results[pList[i]] = eachLine(result)
  end
  close(so)

  results
end

function queryRows(phraseList::Array{ASCIIString}, config=LMConfig())
  queryCustom(phraseList, config) do row
    RowResult(row)
  end
end

function query(phraseList::Array{ASCIIString}, config=LMConfig())
  queryCustom(phraseList, config) do row
    RowResult(row).totalProbability
  end
end

function query(ngrams::Ngrams, config=LMConfig())
  query(collect(keys(ngrams)), config)
end