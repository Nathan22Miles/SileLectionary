-- This is the default typesetter. You are, of course, welcome to create your own.
local awful_bad = 1073741823
local inf_bad = 10000
local eject_penalty = -inf_bad
local supereject_penalty = 2 * -inf_bad
local deplorable = 100000

if std.string.monkey_patch then -- stdlib >= 40
  std.string.monkey_patch()
end

SILE.settings.declare({
  name = "typesetter.widowpenalty", 
  type = "integer",
  default = 3000,
  help = "Penalty to be applied to widow lines (at the start of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.parseppattern", 
  type = "string or integer",
  default = "\n\n+",
  help = "Lua pattern used to separate paragraphs"
})
SILE.settings.declare({
  name = "typesetter.orphanpenalty",
  type = "integer",
  default = 3000,
  help = "Penalty to be applied to orphan lines (at the end of a paragraph)"
})

SILE.settings.declare({
  name = "typesetter.parfillskip",
  type = "Glue",
  default = SILE.nodefactory.newGlue("0pt plus 10000pt"),
  help = "Glue added at the end of a paragraph"
})

SILE.settings.declare({
  name = "typesetter.breakwidth",
  type = "Length or nil",
  default = nil,
  help = "Width to break lines at"
})
SILE.defaultTypesetter = std.object {
  -- Setup functions
  hooks = {},
  init = function(self, frame)
    self.stateQueue = {};
    self:initFrame(frame)
    self:initState();
    return self
  end,
  initState = function(self)
    self.state = {
      nodes = {},
      outputQueue = {},
      lastBadness = awful_bad,      
    };
    self:initline()
  end,
  initFrame = function(self, frame)
    self.frame = frame
    self.frame:init()
  end,
  pushState = function(self)
    table.insert(self.stateQueue, self.state);
    self:initState();
  end,
  popState = function(self)
    self.state = table.remove(self.stateQueue)
    if not self.state then SU.error("Typesetter state queue empty") end
  end,
  vmode = function(self)
    return #self.state.nodes == 0
  end,

  debugState = function(self)
    print("\n---\nI am in "..(self:vmode() and "vertical" or "horizontal").." mode")
    print("Writing into "..self.frame:toString())
    print("Recent contributions: ")
    for i = 1,#(self.state.nodes) do
      io.write(self.state.nodes[i].. " ")
    end
    print("\nVertical list: ")
    for i = 1,#(self.state.outputQueue) do
      print("  "..self.state.outputQueue[i])
    end
  end,
  -- Boxy stuff
  pushHbox = function (self, spec) table.insert(self.state.nodes, SILE.nodefactory.newHbox(spec)); end,
  pushGlue = function (self, spec) return table.insert(self.state.nodes, SILE.nodefactory.newGlue(spec)); end,
  pushPenalty = function (self, spec) return table.insert(self.state.nodes, SILE.nodefactory.newPenalty(spec)); end,
  pushVbox = function (self, spec) local v = SILE.nodefactory.newVbox(spec); table.insert(self.state.outputQueue,v); return v; end,
  pushVglue = function (self, spec) return table.insert(self.state.outputQueue, SILE.nodefactory.newVglue(spec)); end,
  pushVpenalty = function (self, spec) return table.insert(self.state.outputQueue, SILE.nodefactory.newPenalty(spec)); end,

  -- Actual typesetting functions
  typeset = function (self, text)
    for t in SU.gtoke(text,SILE.settings.get("typesetter.parseppattern")) do
      if (t.separator) then 
        self:leaveHmode();
        SILE.documentState.documentClass.endPar(self)
      else self:setpar(t.string)
      end
    end
  end,

  initline = function (self)
    if (#self.state.nodes == 0) then
      table.insert(self.state.nodes, SILE.nodefactory.zeroHbox)
    end
  end,

  -- Takes string, writes onto self.state.nodes
  setpar = function (self, t)
    t = string.gsub(t,"\n", " ");
    --t = string.gsub(t,"^%s+", "");
    if (#self.state.nodes == 0) then
      self:initline()
      SILE.documentState.documentClass.newPar(self)
    end
    for token in SU.gtoke(t, "-") do
      local t2= token.separator and token.separator or token.string
      local newNodes = SILE.shaper.shape(t2)
      for i=1,#newNodes do
          self.state.nodes[#(self.state.nodes)+1] = newNodes[i]
          if token.separator then
            self.state.nodes[#(self.state.nodes)+1] = SILE.nodefactory.newPenalty({ value = SILE.settings.get("linebreak.hyphenPenalty") })
          end
      end
    end
  end,

  -- Empties self.state.nodes, breaks into lines, puts lines into vbox, adds vbox to
  -- Turns a node list into a list of vboxes
  boxUpNodes = function (self)
    local nl = self.state.nodes
    while (#nl > 0 and (nl[#nl]:isPenalty() or nl[#nl]:isGlue())) do
     table.remove(nl);
    end
    while (#nl >0 and nl[1]:isPenalty()) do table.remove(nl,1) end
    if #nl == 0 then return {} end
    self:pushGlue(SILE.settings.get("typesetter.parfillskip"));
    self:pushPenalty({ flagged= 1, penalty= -inf_bad });
    local listToString = function(l)
      local rv = ""
      for i = 1,#l do rv = rv ..l[i] end return rv
    end
    SU.debug("typesetter", "Boxed up "..listToString(nl));

    local breakWidth = SILE.settings.get("typesetter.breakwidth") or self.frame:width()
    SU.debug("typesetter", "breakWidth="..SILE.settings.get("typesetter.breakwidth"))
    
    if (type(breakWidth) == "table") then breakWidth = breakWidth.length end
    local breaks = SILE.linebreak:doBreak( nl, breakWidth);
    if (#breaks == 0) then
      SU.error("Couldn't break :(")
    end
    local lines = self:breakpointsToLines(breaks);
    local vboxes = {}
    local previousVbox = nil
    for index=1, #lines do
      local l = lines[index]
      local v = SILE.nodefactory.newVbox({ nodes = l.nodes, ratio = l.ratio });
      local pageBreakPenalty = 0
      if (#lines > 1 and index == 1) then
        pageBreakPenalty = SILE.settings.get("typesetter.widowpenalty")
      elseif (#lines > 1 and index == (#lines-1)) then
        pageBreakPenalty = SILE.settings.get("typesetter.orphanpenalty")
      end
      if index > 1 then
        vboxes[#vboxes+1] = self:leadingFor(v, previousVbox)
      end
      vboxes[#vboxes+1] = v
      previousVbox = v
      if pageBreakPenalty > 0 then
        SU.debug("typesetter", "adding penalty of "..pageBreakPenalty.." after "..v)
        vboxes[#vboxes+1] = SILE.nodefactory.newPenalty({ penalty = pageBreakPenalty})
      end
    end
    return vboxes
  end,

  pageTarget = function(self)
    return self.frame:height()
  end,
  registerHook = function (self, category, f)
    if not self.hooks[category] then self.hooks[category] = {} end
    self.hooks[category][1+#(self.hooks[category])] = f
  end,
  runHooks = function(self, category, data)
    if not self.hooks[category] then return data end
    for i = 1,#self.hooks[category] do
      data = self.hooks[category][i](self, data)
    end
    return data
  end,
  registerPageBreakHook = function (self, f)
    self:registerHook("pagebreak", f)
  end,
  registerNewPageHook = function (self, f)
    self:registerHook("newpage", f)
  end,
  pageBuilder = function (self, independent)
    local vbox;
    local pageNodeList
    if #(self.state.outputQueue) == 0 then return end
    local target = self:pageTarget()
    pageNodeList, self.state.lastPenalty = SILE.pagebuilder.findBestBreak(self.state.outputQueue, target)
    if not pageNodeList then -- No break yet
      return false
    end
    pageNodeList = self:runHooks("pagebreak",pageNodeList)
    self:setVerticalGlue(pageNodeList, target)
    self:outputLinesToPage(pageNodeList);
    return true
  end,

  setVerticalGlue = function (self, pageNodeList, target)
    -- Do some sums on that list
    local glues = {};
    local gTotal = SILE.length.new()
    local totalHeight = SILE.length.new()

    for i=1,#pageNodeList do
      totalHeight = totalHeight + pageNodeList[i].height + pageNodeList[i].depth
      if pageNodeList[i]:isVglue() then 
        table.insert(glues,pageNodeList[i]);
        gTotal = gTotal + pageNodeList[i].height
      end
    end

    local adjustment = (target - totalHeight).length

    if (adjustment > gTotal.stretch) then adjustment = gTotal.stretch end
    if (adjustment / gTotal.stretch > 0) then 
      for i,g in pairs(glues) do
        g:setGlue(adjustment * g.height.stretch / gTotal.stretch)
      end
    end

    SU.debug("pagebuilder", "Glues for self page adjusted by "..(adjustment/gTotal.stretch) )  
  end,

  initNextFrame = function(self)
    self.frame:leave()
    if (self.frame.next and not (self.state.lastPenalty <= supereject_penalty )) then
      self:initFrame(SILE.getFrame(self.frame.next));
    elseif not self.frame:isMainContentFrame() then
      SU.warn("Overfull content for frame "..self.frame.id)
      self:chuck()
    else
      SILE.documentState.documentClass:endPage()
      self:initFrame(SILE.documentState.documentClass:newPage()); -- XXX Hack
    end
    -- Always push back and recalculate. The frame may have a different shape, or
    -- we may be doing clever things like grid typesetting. CPU time is cheap.
    self:pushBack();
  end,

  pushBack = function (self)
    SU.debug("typesetter", "Pushing back "..#(self.state.outputQueue).." nodes")
    --self:pushHbox({ width = SILE.length.new({}), value = {glyph = 0} });
    local v
    local function luaSucks (a) v=a return a end

    local oldqueue = self.state.outputQueue
    self.state.outputQueue = {}
    while luaSucks(table.remove(oldqueue,1)) do
      if not v:isVglue() and not v:isPenalty() then
        for i=1,#(v.nodes) do
            if v.nodes[i]:isDiscretionary() then
              v.nodes[i].used = 0 -- HACK HACK HACK
            end
            -- HACK HACK HACK HACK HACK
            if not (v.nodes[i]:isGlue() and (v.nodes[i].value == "lskip" or v.nodes[i].value == "rskip")) then
              self.state.nodes[#(self.state.nodes)+1] = v.nodes[i]
            end
        end
      else
        -- local vboxlist = self:boxUpNodes()
        -- self.state.nodes = {};
        -- for index=1, #vboxlist do
        --   self.state.outputQueue[#(self.state.outputQueue)+1] = vboxlist[index]
        -- end
        -- self.state.outputQueue[#(self.state.outputQueue)+1] = v
      end
    end
    self:leaveHmode();
    self:runHooks("newpage")
  end,
  outputLinesToPage = function (self, lines)
    SU.debug("pagebuilder", "OUTPUTTING frame "..self.frame.id);
    local i
    for i = 1,#lines do local l = lines[i]
      if not self.frame.state.totals.pastTop and not (l:isVglue() or l:isPenalty()) then
        self.frame.state.totals.pastTop = true
      end
      if self.frame.state.totals.pastTop then
        l:outputYourself(self, l)
      end
    end
  end,
  leaveHmode = function(self, independent)
    SU.debug("typesetter", "Leaving hmode");
    local vboxlist = self:boxUpNodes()
    self.state.nodes = {};
    -- Push output lines into boxes and ship them to the page builder
    for index=1, #vboxlist do
      self.state.outputQueue[#(self.state.outputQueue)+1] = vboxlist[index]
    end
    if self:pageBuilder() and not independent then
      self:initNextFrame()
    end
  end,
  leadingFor = function(self, v, previous)
    -- Insert leading
    SU.debug("typesetter", "   Considering leading between self two lines");
    local prevDepth = 0
    if previous then prevDepth = previous.depth end
    SU.debug("typesetter", "   Depth of previous line was "..tostring(prevDepth));
    local bls = SILE.settings.get("document.baselineskip")
    local d = bls.height - v.height - prevDepth;
    d = d.length
    SU.debug("typesetter", "   Leading height = " .. tostring(bls.height) .. " - " .. tostring(v.height) .. " - " .. tostring(prevDepth) .. " = "..d) ;

    if (d > SILE.settings.get("document.lineskip").height.length) then
      len = SILE.length.new({ length = d, stretch = bls.height.stretch, shrink = bls.height.shrink })
      return SILE.nodefactory.newVglue({height = len});
    else
      return SILE.nodefactory.newVglue(SILE.settings.get("document.lineskip"));
    end
  end,
  addrlskip = function (self, slice)
    local rskip = SILE.settings.get("document.rskip")
    if rskip then
      rskip.value = "rskip"
      table.insert(slice, rskip)
      table.insert(slice, SILE.nodefactory.zeroHbox)
    end
    local lskip = SILE.settings.get("document.lskip")
    if lskip then
      lskip.value = "lskip"
      table.insert(slice, 1, lskip) 
      table.insert(slice, 1, SILE.nodefactory.zeroHbox) 
    end
  end,
  breakpointsToLines = function(self, bp)
    local linestart = 0;
    local lines = {};
    local nodes = self.state.nodes;

    for i,point in pairs(bp) do
      if not(point.position == 0) then
        slice = {}
        local seenHbox = 0
        local toss = 1
        for j = linestart, point.position do
          slice[#slice+1] = nodes[j]
          if nodes[j] then
            toss = 0
            if nodes[j]:isBox() then seenHbox = 1 end
          end
        end
        if seenHbox == 0 then break end
        self:addrlskip(slice)

        local naturalTotals = SILE.length.new({length =0 , stretch =0, shrink = 0})
        for i,node in ipairs(slice) do
          if (node:isBox() or (node:isPenalty() and node.penalty == -inf_bad)) then
            skipping = 0
            if node:isBox() then
              naturalTotals = naturalTotals + node.width
            end
          elseif skipping == 0 then-- and not(node:isGlue() and i == #slice) then
            naturalTotals = naturalTotals + node.width
          end
        end
        local i = #slice
        while i > 1 do
          if slice[i]:isGlue() or slice[i] == SILE.nodefactory.zeroHbox then
            -- Do nothing
          elseif (slice[i]:isDiscretionary()) then
            slice[i].used = 1;
            if slice[i].parent then slice[i].parent.hyphenated = true end
            naturalTotals = naturalTotals + slice[i]:prebreakWidth()
          else
            break
          end
          i = i -1
        end
        local left = (point.width - naturalTotals.length)

        if left < 0 then
          left = left / naturalTotals.shrink
        else
          left = left / naturalTotals.stretch
        end
        if left < -1 then left = -1 end
        local thisLine = { ratio = left, nodes = slice };
        lines[#lines+1] = thisLine
        linestart = point.position+1
      end
    end
    --self.state.nodes = nodes.slice(linestart+1,nodes.length);
    return lines;
  end,
  chuck = function(self) -- emergency shipout everything
    self:leaveHmode(true)
    self:outputLinesToPage(self.state.outputQueue)
    self.state.outputQueue = {}
  end
};

SILE.typesetter = SILE.defaultTypesetter {};

SILE.typesetNaturally = function (frame, f)
  local saveTypesetter = SILE.typesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:leave() end
  SILE.typesetter = SILE.defaultTypesetter {};
  SILE.typesetter:init(frame)
  SILE.settings.temporarily(f)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:chuck()
  SILE.typesetter.frame:leave()
  SILE.typesetter = saveTypesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:enter() end
end;
