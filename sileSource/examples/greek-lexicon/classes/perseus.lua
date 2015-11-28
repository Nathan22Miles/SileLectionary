local plain = SILE.require("classes/plain");
local perseus = plain { id = "perseus" };
SILE.scratch.perseus = {}
perseus:declareFrame("a",    {left = "8.3%",            right = "48%",            top = "11.6%",       bottom = "80%", next="b"});
perseus:declareFrame("b",    {left = "52%",             right = "100% - left(a)", top = "top(a)",      bottom = "bottom(a)"    });
perseus:declareFrame("folio",{left = "left(a)",         right = "right(b)",       top = "bottom(a)+3%",bottom = "bottom(a)+8%" });
perseus.pageTemplate.firstContentFrame = perseus.pageTemplate.frames["a"];

SILE.registerCommand("lexicalEntry", function (options, content)
  SILE.call("noindent")
  local pos = SILE.findInTree(content, "posContainer")
  if not pos then return end
  local senses = SILE.findInTree(pos, "senses")
  if not senses[1] then return end
  SILE.process(content)
  SILE.typesetter:typeset(".")

  SILE.call("par")
  SILE.call("smallskip")
end)

SILE.registerCommand("senses", function(options, content)
  SILE.scratch.perseus.senseNo = 0
  SILE.process(content)
end)

SILE.registerCommand("senseContainer", function(options, content)
  SILE.scratch.perseus.senseNo = SILE.scratch.perseus.senseNo + 1
  SILE.typesetter:typeset(SILE.scratch.perseus.senseNo .. ". ")
  SILE.process(content)
end)

SILE.registerCommand("authorContainer", function(options, content)
  local auth = SILE.findInTree(content, "author")
  if not auth then return end
  local name = SILE.findInTree(auth, "name")
  if name and name[1] ~= "NULL" then 
    SILE.call("font", {style="italic"}, function ()
      SILE.typesetter:typeset("("..name[1]..")")
    end)
  end
end)


return perseus