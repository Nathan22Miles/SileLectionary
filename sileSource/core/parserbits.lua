lpeg = require("lpeg")
local R = lpeg.R
local S = lpeg.S
local P = lpeg.P
local C = lpeg.C
local V = lpeg.V
local Cg = lpeg.Cg
local Ct = lpeg.Ct
local number = {}

local digit = R("09")
number.integer = (S("+-") ^ -1) * (digit   ^  1)
number.fractional = (P(".")   ) * (digit ^ 1)
number.decimal =  
  (number.integer *              -- Integer
  (number.fractional ^ -1)) +    -- Fractional
  (S("+-") * number.fractional)  -- Completely fractional number

number.scientific = 
  number.decimal * -- Decimal number
  S("Ee") *        -- E or e
  number.integer   -- Exponent

-- Matches all of the above
number.number = C(number.decimal + number.scientific) / function (n) return tonumber(n) end
local whitespace = S('\r\n\f\t ')^0
local units = P("mm") + P("cm") + P("in") + P("pt") + P("em") + P("ex") + P("en")
local zero = P("0") / function(...) return 0 end
local dimensioned_string = ( C(number.number) * whitespace * C(units) ) / function (x,n,u) return  SILE.toPoints(n, u) end

SILE.parserBits = {
  number = number,
  identifier = (R("AZ") + R("az") + P("_") + R("09"))^1,
  units = units,
  zero = zero,
  whitespace = whitespace,
  dimensioned_string = dimensioned_string,  
  length = Ct(Cg(dimensioned_string + zero, "length") * whitespace * (P("plus") * whitespace * Cg(dimensioned_string + zero, "stretch"))^-1 * whitespace * (P("minus") * whitespace * Cg(dimensioned_string + zero,"shrink"))^-1)
}