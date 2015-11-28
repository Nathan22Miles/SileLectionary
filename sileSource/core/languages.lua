SILE.languageSupport = {
  languages = {},
  loadLanguage = function(language)
    if SILE.languageSupport.languages[language] then return end
    if SILE.hyphenator.languages[language] then return end
    if not(language) or language == "" then language = "en" end
    ok, fail = pcall(function () SILE.require("languages/"..language.."-compiled") end)
    if ok then return end
    if not pcall(function () SILE.require("languages/"..language) end) then
      return
    end
  end
}

-- The following languages neither have hyphenation nor specific
-- language support at present. This code is here to suppress warnings.
SILE.hyphenator.languages.ar = {patterns={}}
