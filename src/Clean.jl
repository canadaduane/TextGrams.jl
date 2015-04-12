using MutableStrings
using Base.copy

export clean!, clean

#=
 Transforms text such as the following:

   And behold, I said--"This is no good!" What
   shall ye say unto these people, there-
   fore?

 Into a set of sentences, one per line, like the following:

   and behold i said this is no good
   what shall ye say unto these people therefore

 Spaces indicate word boundaries, while periods indicate sentence boundaries.
=#
function clean!(text::MutableASCIIString, lineSep = '\n', wordSep = ' ')
  if length(text) == 0
    return text
  end

  justAddedLineSep = false
  justAddedWordSep = true # prevent whitespace at beginning
  maxScanAhead = 30
  i, j = (1, 1)
  textLen = length(text)

  while i <= textLen
    c = text[i]
    n =
      if c >= 'A' && c <= 'Z'
        # Change upper case to lowercase
        c + 32
      elseif c == '\t' || c == '_' || c == ',' || c == ':' || c == '&' || c == '/'
        # Change inconsequential punctuation to spaces (i.e. all count as whitespace)
        ' '
      elseif c == '?' || c == '!' || c == ';'
        # Change exclamation, question marks to periods (i.e. sentence boundaries)
        '.'
      else
        c
      end

    # hyphen at end of line joins word fragments
    if n == '-'
      # double dash? (doesn't count as hyphen)
      if i < textLen && text[i + 1] == '-'
        if !justAddedWordSep && !justAddedLineSep
          text[j] = wordSep
          j += 1
          i += 1
          justAddedWordSep = true
          justAddedLineSep = false
        end
      else
        # # scan ahead to see if this hyphen is at the end of the line
        k = i + 1
        while k < i + maxScanAhead && k <= textLen
          s = text[k]
          if s != '\t' && s != ' '
            if s == '\n'
              # this is a hyphenated line join, so join the lines
              i = k
              break
            else
              # not a line join
              break
            end
          end
          k += 1
        end
      end
    elseif n == '.' && !justAddedLineSep
      # look-behind and see if this is an abbreviation
      if (c == '.' && j >= 3)
        a = text[j - 1]
        if a >= 'a' && a <= 'z'
          b = text[j - 2]

          # we're just checking for single-letter abbrevs,
          # so see if 2-chars-behind is whitespace
          if b == ' ' || b == '.' || b == '\n' || b == '\t'
            text[j] = '.'
            j += 1

            i += 1; continue
          end
        end
      end

      # Erase space before period
      if (justAddedWordSep && j > 1)
        j -= 1
      end
      # Add a sentence boundary (e.g. '\n')
      text[j] = lineSep
      j += 1
      justAddedLineSep = true
      justAddedWordSep = false
    elseif (n == ' ' || n == '\n') && 
           !justAddedWordSep && 
           !justAddedLineSep
      # Add a word boundary (e.g. ' ')
      text[j] = wordSep
      j += 1
      justAddedLineSep = false
      justAddedWordSep = true
    elseif n == '\'' || (n >= 'a' && n <= 'z')
      # Normal text
      text[j] = n
      j += 1
      justAddedLineSep = false
      justAddedWordSep = false
    end
    i += 1
  end

  # erase word or sentence boundary markers at end of text
  if (justAddedWordSep)
    j -= 1
  end

  # set the new length of the string
  resize!(text.data, j - 1)

  return text
end

function clean(text::String, lineSep = '\n', wordSep = ' ')
  clean!(MutableASCIIString(copy(text)), lineSep, wordSep)
end

