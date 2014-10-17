using MutableStrings

#=
 Transforms text such as the following:

   And behold, I said, "This is no good!"
   What shall ye say unto these people, there-
   fore?

 Into a cleaned up single line of text, like the following:

   and behold i said this is no good.what shall ye say unto these people therefore.

 Spaces indicate word boundaries, while periods indicate sentence boundaries.
=#
function clean!(text::MutableASCIIString)
  if length(text) == 1
    return text
  end

  join_lines = false
  just_added_period = false
  just_added_space = true # prevent whitespace at beginning
  j = 1
  for i in 1:length(text)
    c = text[i]
    n =
      if c >= 'A' && c <= 'Z'
        # Change upper case to lowercase
        c + 32
      elseif c == '\n' || c == '\t' || c == ',' || c == ';' || c == '&' || c == '/'
        # Change whitespace chars to spaces (i.e. all count as whitespace)
        ' '
      elseif c == '?' || c == '!' || c == ':'
        # Change exclamation, question marks to periods (i.e. sentence boundaries)
        '.'
      else
        c
      end

    if n == '-'
      # A dash at the end of a line indicates we should join word parts
      join_lines = true
    elseif join_lines && n == ' '
      # Ignore whitespace after a dash (i.e. including newlines, which is the
      # most common case because words that are broken by syllables are dashed)
    elseif n == '.' && !just_added_period
      # Erase space before period
      if (just_added_space)
        j -= 1
      end
      # Add a period to indicate sentence boundary
      text[j] = '.'
      j += 1
      just_added_period = true
      just_added_space = false
      join_lines = false
    elseif n == ' ' && !just_added_space && !just_added_period
      # Add a space to indicate word boundary
      text[j] = ' '
      j += 1
      just_added_space = true
      just_added_period = false
    elseif n >= 'a' && n <= 'z'
      # Normal text
      text[j] = n
      j += 1
      just_added_space = false
      just_added_period = false
      join_lines = false
    end
  end

  # erase word or sentence boundary markers at end of text
  if (just_added_space || just_added_period)
    j -= 1
  end

  # set the new length of the string
  resize!(text.data, j - 1)

  return text
end

function clean(text)
  clean!(MutableASCIIString(copy(text)))
end