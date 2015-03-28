using MutableStrings

facts("Clean") do
  context("lowercases text") do
    @fact clean("ALL UPPERCASE") => "all uppercase"
  end

  context("compacts whitespace") do
    @fact clean("is\t it    so? ok.") => "is it so\nok\n"
  end

  context("separates words with double hyphen") do
    @fact clean("good--do it") => "good do it"
  end

  context("separates words with newlines") do
    @fact clean("a\nb\nc") => "a b c"
  end

  context("separates words with underscores") do
    @fact clean("short_title") => "short title"
  end

  context("compacts whitespace around double hyphen") do
    @fact clean("good -- do it") => "good do it"
  end

  context("does not add whitespace when double hyphen occurs after end of sentence") do
    @fact clean("ok.--maybe") => "ok\nmaybe"
  end

  context("treats [) =>/&] as whitespace") do
    @fact clean("a) =>bb&cc/d") => "a bb cc d"
  end

  context("treats [;:!?] as sentence separators") do
    @fact clean("x;y?z!:q") => "x\ny\nz\nq"
  end

  context("joins hyphenated words at line end") do
    @fact clean("satis-\nfaction") => "satisfaction"
  end

  context("ignores whitespace after hyphen at line end") do
    @fact clean("satis- \t \nfaction") => "satisfaction"
  end

  context("ignores numbers") do
    @fact clean("123abc") => "abc"
  end

  context("ignores quotes and braces") do
    @fact clean("[jim] \"speaks\"") => "jim speaks"
  end

  context("keeps apostrophes") do
    @fact clean("dad's") => "dad's"
  end

  context("keeps abbreviated single letters") do
    @fact clean("a mr t. sawyer") => "a mr t. sawyer"
  end

  context("keeps abbreviated single letters that follow other abbreviations without spaces") do
    @fact clean("a mr t.j. sawyer") => "a mr t.j. sawyer"
  end

  context("handles documents of size 0") do
    @fact clean("") => ""
  end

  context("handles documents of size 1") do
    @fact clean("A") => "a"
  end

  context("can use custom line separator") do
    @fact clean("one?\ntwo!", '|') => "one|two|"
  end

  context("can use custom word separator") do
    @fact clean("good old time", '\n', '|') => "good|old|time"
  end
end
