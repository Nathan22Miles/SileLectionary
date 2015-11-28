local _length
_length = std.object {
  length = 0,
  stretch = 0,
  shrink = 0,
  _type = "Length",

  fromLengthOrNumber = function (self, x)
    if type(x) == "table" then
      self.length = x.length
      self.stretch = x.stretch
      self.shrink = x.shrink
    else
      self.length = x
    end
    return self
  end,

  __tostring = function (x)
    local s = tostring(x.length).."pt"
    if x.stretch ~= 0 then s = s .. " plus "..x.stretch.."pt" end
    if x.shrink ~= 0 then s = s .. " minus "..x.shrink.."pt" end
    return s
  end,

  __add = function (self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    if type(other) == "table" then
      result.length = result.length + other.length
      result.stretch = result.stretch + other.stretch
      result.shrink = result.shrink + other.shrink
    else
      result.length = result.length + other
    end
    return result
  end,

  __sub = function (self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    if type(other) == "table" then
      result.length = result.length - other.length
      result.stretch = result.stretch - other.stretch
      result.shrink = result.shrink - other.shrink
    else
      result.length = result.length - other
    end
    return result
  end,

  -- __mul = function(self, other)
  --   local result = _length {}
  --   result:fromLengthOrNumber(self)
  --   if type(other) == "table" then
  --     SU.error("Attempt to multiply two lengths together")
  --   else
  --     result.length = result.length * other
  --     result.stretch = result.stretch * other
  --     result.shrink = result.shrink * other
  --   end
  --   return result
  -- end,
    
  __lt = function (self, other)
    return (self-other).length < 0
  end,
}

local length = {
  new = function (spec)
    return _length(spec or {})
  end,

  parse = function (spec)
    if not spec then return _length {} end
    local t = lpeg.match(SILE.parserBits.length, spec)
    if not t then SU.error("Bad length definition '"..spec.."'") end
    if not t.shrink then t.shrink = 0 end
    if not t.stretch then t.stretch = 0 end
    return _length(t)
  end,

  zero = _length {}
}

return length
