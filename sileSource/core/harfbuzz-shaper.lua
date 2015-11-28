
if not SILE.shapers then SILE.shapers = { } end
SILE.shapers.harfbuzz = {}

SILE.tokenizers.default = function(text)
  return SU.gtoke(text, SILE.settings.get("shaper.spacepattern"))
end

SILE.settings.declare({
  name = "shaper.spacepattern", 
  type = "string",
  default = "%s+",
  help = "The Lua pattern used for splitting words on spaces"
})

SILE.shapers.harfbuzz = require("justenoughharfbuzz")

local debugging_face = function(opts)
  local face = SILE.shapers.harfbuzz._face(opts)
  if not face then 
    SU.error("Could not find requested font "..opts.." or any suitable substitutes")
  end
  SU.debug("fonts", "Resolved font family "..opts.font.." -> "..face.filename)
  return face
end

local function doShape (s, options)
  local face = SILE.font.cache(options, debugging_face)
  if not face then 
    SU.error("Could not find requested font "..options.." or any suitable substitutes")
  end
  return { SILE.shapers.harfbuzz._shape(s,face.face,options.script, options.direction,options.language, options.size, options.features) }
end

local function measureSpace( options )
  local ss = SILE.settings.get("document.spaceskip") 
  if ss then return ss end
  local i = doShape(" ", options)
  if not i[1] then return SILE.length.new() end
  local spacewidth = i[1].width
  return SILE.length.new({ length = spacewidth * 1.2, shrink = spacewidth/3, stretch = spacewidth /2 }) -- XXX
end

function SILE.shapers.harfbuzz.measureDim(char)
  local options = SILE.font.loadDefaults({})
  local i = doShape(char, options)
  if char == "x" then 
    return i[1].height
  else
    return i[1].width
  end
end 

function SILE.shapers.harfbuzz.shape(text, options)
  if not options then options = {} end
  options = SILE.font.loadDefaults(options)
  -- Cache the font
  face = SILE.font.cache(options, SILE.shapers.harfbuzz._face)
  local nodes = {}
  local gluewidth = measureSpace(options)

  -- Do language-specific tokenization
  pcall(function () SILE.require("languages/"..options.language) end)
  local tokenizer = SILE.tokenizers[options.language]
  if not tokenizer then
    tokenizer = SILE.tokenizers.default
  end

  for token in tokenizer(text) do
    if (token.separator) then
      table.insert(nodes, SILE.nodefactory.newGlue({ width = gluewidth }))
    elseif (token.node) then
      table.insert(nodes, token.node)
    else
      local items = doShape(token.string, options)
      local nnode = {}

      local glyphs = {}
      local totalWidth = 0
      local depth = 0
      local height = 0
      local glyphNames = {}

      for i = 1,#items do local glyph = items[i]        
        if glyph.depth > depth then depth = glyph.depth end
        if glyph.height > height then height = glyph.height end
        totalWidth = totalWidth + glyph.width
        table.insert(glyphs, glyph.codepoint)
        table.insert(glyphNames, glyph.name)
      end

      table.insert(nnode, SILE.nodefactory.newHbox({ 
        depth = depth,
        height= height,
        width = SILE.length.new({ length = totalWidth }),
        value = {glyphString = glyphs, glyphNames = glyphNames, options = options, text = token.string[i] }
      }))

      table.insert(nodes, SILE.nodefactory.newNnode({ 
        nodes = nnode,
        text = token.string,
        options = options,
        language = options.language
      }))
    end
  end
  return nodes
end

SILE.shaper = SILE.shapers.harfbuzz
