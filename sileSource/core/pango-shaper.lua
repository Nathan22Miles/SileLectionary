local lgi = require("lgi");
require "string"
local pango = lgi.Pango
local fm = lgi.PangoCairo.FontMap.get_default()
local pango_context = lgi.Pango.FontMap.create_context(fm)

if not SILE.shapers then SILE.shapers = { } end
SILE.shapers.pango = {}

SILE.settings.declare({
  name = "shaper.spacepattern", 
  type = "string",
  default = "%s+",
  help = "The Lua pattern used for splitting words on spaces"
})

function itemize(s, pal)
  return pango.itemize(pango_context, s, 0, string.len(s), pal, nil)
end

function _shape(s, item)
  local offset = item.offset
  local length = item.length
  local analysis = item.analysis
  local pgs = pango.GlyphString.new()
  pango.shape(string.sub(s,1+offset), length, analysis, pgs)
  return pgs
end

local palcache = {}
local spacecache = {}
local function getPal(options)
  if options.pal then
    pal = options.pal
    return pal
  end
  local p = std.string.pickle(options)
  if palcache[p] then return palcache[p]
  else
    pal = pango.AttrList.new();
    if options.language then pal:insert(pango.Attribute.language_new(pango.Language.from_string(options.language))) end
    if options.font then pal:insert(pango.Attribute.family_new(options.font)) end
    if options.weight then pal:insert(pango.Attribute.weight_new(tonumber(options.weight))) end
    if options.size then pal:insert(pango.Attribute.size_new(options.size * 1024 * 0.75)) end -- I don't know why 0.75
    if options.style then pal:insert(pango.Attribute.style_new(
      options.style == "italic" and pango.Style.ITALIC or pango.Style.NORMAL)) end
    if options.variant then pal:insert(pango.Attribute.variant_new(
      options.variant == "smallcaps" and pango.Variant.SMALL_CAPS or pango.Variant.NORMAL)) end
  end
  if options.language then
    pango_context:set_language(pango.Language.from_string(options.language))
  end
  palcache[p] = pal
  return pal
end  

local function measureSpace( pal )
  local ss = SILE.settings.get("document.spaceskip") 
  if ss then return ss end
  if spacecache[pal] then return spacecache[pal] end
  local spaceitem = itemize(" ",pal)[1]
  local g = (_shape(" ",spaceitem).glyphs)[1]
  local spacewidth = g.geometry.width / 1024;
  spacecache[pal] = SILE.length.new({ length = spacewidth * 1.2, shrink = spacewidth/3, stretch = spacewidth /2 }) -- XXX
  return spacecache[pal]
end

local dimcache = {}
function SILE.shapers.pango.measureDim(char)
  local options = SILE.font.loadDefaults({})
  local pal = getPal(options)
  if dimcache[pal] and dimcache[pal][char] then return dimcache[pal][char] end
  if not dimcache[pal] then dimcache[pal] = {} end
  local charitem = itemize(char,pal)[1]
  local g = (_shape(char,charitem).glyphs)[1]
  if char == "x" then 
    local font = charitem.analysis.font
    local rect = font:get_glyph_extents(g.glyph)
    dimcache[pal][char] = -rect.y/1024
  else
    dimcache[pal][char] = g.geometry.width / 1024
  end
  return dimcache[pal][char]
end 

function SILE.shapers.pango.shape(text, options)
  if not options then options = {} end
  options = SILE.font.loadDefaults(options)

  local pal = getPal(options)
  local nodes = {}
  local gluewidth = measureSpace(pal)
  for token in SU.gtoke(text, SILE.settings.get("shaper.spacepattern")) do
    if (token.separator) then
      table.insert(nodes, SILE.nodefactory.newGlue({ width = gluewidth }))
    else
      local items = itemize(token.string, pal)
      local nnode = {}
      for i in pairs(items) do
        local pgs = _shape(token.string, items[i])
        -- Sum the glyphs in this string
        local text = string.sub(token.string,1+items[i].offset, items[i].length)
        local depth, height = 0,0
        local font = items[i].analysis.font
        local glyphs = {}
        for g in pairs(pgs.glyphs) do
          local rect = font:get_glyph_extents(pgs.glyphs[g].glyph)
          local desc = rect.y + rect.height
          local asc  = -rect.y 
          if desc > depth then depth = desc end
          if asc > height then height = asc end
          table.insert(glyphs, pgs.glyphs[g].glyph)
        end
        table.insert(nnode, SILE.nodefactory.newHbox({ 
          depth = depth / 1024,
          height= height / 1024,
          width = SILE.length.new({ length= pgs:get_width() / 1024 }),
          value = {font = font, text = text, glyphString = pgs, glyphs = glyphs, options = options }
        }))
      end
      table.insert(nodes, SILE.nodefactory.newNnode({ 
        nodes = nnode,
        text = token.string,
        pal = pal,
        options = options,
        language = options.language
      }))
    end
  end
  return nodes
end


SILE.shaper = SILE.shapers.pango

-- 
-- local s = "ltr שָׁוְא ltr"
-- 

-- for i in pairs(items) do
--   local offset = items[i].offset
--   local length = items[i].length
--   local analysis = items[i].analysis
--   local pgs = pango.GlyphString.new()
--   pango.shape(string.sub(s,1+offset), length, analysis, pgs)
--   return pgs
--   cr:move_to(x, 50)
--   cr:show_glyph_string(analysis.font, pgs)
--   x = x + pgs:get_width()/1024
--   print(x)
-- end
