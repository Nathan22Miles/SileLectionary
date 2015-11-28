local gridSpacing -- Should be a setting

local makeUp = function ()
  local toadd = gridSpacing - (SILE.typesetter.frame.state.totals.gridCursor % gridSpacing)   
  SILE.typesetter.frame.state.totals.gridCursor = SILE.typesetter.frame.state.totals.gridCursor + toadd
  return SILE.nodefactory.newVglue({ height = SILE.length.new({ length = toadd }) })
end

local leadingFor = function(this, vbox, previous)
  if not this.frame.state.totals.gridCursor then this.frame.state.totals.gridCursor = SILE.typesetter.frame.state.cursorY end
  this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + previous.height.length + previous.depth.length
  return makeUp()
end

local pushVglue = function(this, spec)
  if not this.frame.state.totals.gridCursor then this.frame.state.totals.gridCursor = SILE.typesetter.frame.state.cursorY end
  this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + spec.height.length
  SILE.defaultTypesetter.pushVglue(this, spec);
  SILE.defaultTypesetter.pushVglue(this, makeUp())
end

local newBoxup = function (this)
  local b = SILE.defaultTypesetter.boxUpNodes(this)
  if not this.frame.state.totals.gridCursor then this.frame.state.totals.gridCursor = SILE.typesetter.frame.state.cursorY end
  
  if #b > 1 then
    this.frame.state.totals.gridCursor = this.frame.state.totals.gridCursor + b[#b].height.length + b[#b].depth.length
  end
  return b
end

local debugGrid = function()
  local t = SILE.typesetter
  if not t.frame.state.totals.gridCursor then t.frame.state.totals.gridCursor = SILE.typesetter.frame.state.cursorY end
  local g = t.frame.state.totals.gridCursor
  while g < t.frame:bottom() do
    SILE.outputter.rule(t.frame:left(), g, t.frame:width(), 0.1)
    g = g + gridSpacing
  end
end

SILE.registerCommand("grid:debug", debugGrid)

SILE.registerCommand("grid", function(options, content)
  SU.required(options, "spacing", "grid package")
  gridSpacing = SILE.parseComplexFrameDimension(options.spacing,"h");
  SILE.typesetter:chuck()

  SILE.typesetter.leadingFor = leadingFor
  SILE.typesetter.pushVglue = pushVglue
  SILE.typesetter.boxUpNodes = newBoxup
  SILE.typesetter.setVerticalGlue = function () end
  SILE.typesetter.frame.state.totals.gridCursor = SILE.typesetter.frame.state.cursorY
  -- add some now
  SILE.defaultTypesetter.pushVglue(SILE.typesetter, makeUp())
end, "Begins typesetting on a grid spaced at <spacing> intervals.")

SILE.registerCommand("no-grid", function (options, content)
  SILE.typesetter.leadingFor = SILE.defaultTypesetter.leadingFor
  SILE.typesetter.pushVglue = SILE.defaultTypesetter.pushVglue
  SILE.typesetter.setVerticalGlue = SILE.defaultTypesetter.setVerticalGlue
  -- SILE.typesetter.state = t.state
end, "Stops grid typesetting.")