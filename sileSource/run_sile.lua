local baseLuaPath = (os.getenv("SILE_PATH") and os.getenv("SILE_PATH").."/?.lua" or "")
package.path = ';?.lua;lua-libraries/?.lua;lua-libraries/?/init.lua;' .. package.path 

package.cpath = package.cpath .. ";core/?.dll;"

SILE = require("core/sile")

io.stdout:setvbuf 'no'

if not os.getenv 'LUA_REPL_RLWRAP' then
  print('This is SILE '..SILE.version)
end

SILE.parseArguments()
SILE.init()

if unparsed and unparsed[1] then
  SILE.masterFileName = unparsed[1]
  if SILE.preamble then
    print("Loading "..SILE.preamble)
    local i = SILE.resolveFile("classes/"..SILE.preamble)
    if i then
      SILE.readFile(i)
    else
      require("classes/"..SILE.preamble)
    end
  end
  SILE.readFile(unparsed[1])
  io.write("\n")
else
  SILE.repl()
end
