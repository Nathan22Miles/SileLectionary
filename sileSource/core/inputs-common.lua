SILE.inputs.common = {
  init = function(fn, t)
    local dclass = t.attr.class or "plain"
    SILE.documentState.documentClass = SILE.require("classes/"..dclass)
    SU.required(t.attr, "papersize", fn)
    for k,v in pairs(t.attr) do
      if SILE.documentState.documentClass.options[k] then
        SILE.documentState.documentClass.options[k](v)
      end
    end

    if not SILE.outputFilename and SILE.masterFileName then
      SILE.outputFilename = string.gsub(SILE.masterFileName,"%..-$", "").. ".pdf"
    end
    local ff = SILE.documentState.documentClass:init()
    SILE.typesetter:init(ff)
  end
}

SILE.process = function(t)
  if type(t) == "function" then return t() end
  for k,v in ipairs(t) do
    SILE.currentCommand = v
    if type(v) == "string" then
      SILE.typesetter:typeset(v)
    elseif SILE.Commands[v.tag] then
      SILE.Commands[v.tag](v.attr,v)
    else
      SU.error("Unknown command "..(v.tag or v.id))
    end
  end
end

-- Just a simple one-level find. We're not reimplementing XPath here.
SILE.findInTree = function (t, tag)
  for k,v in ipairs(t) do
    if type(v) == "string" then
    elseif v.tag == tag then
      return v
    end
  end
end