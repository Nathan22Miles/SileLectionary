
SILE.registerCommand("color", function(options, content)
  local color = options.color or "black"
  color = SILE.colorparser(color)
  SILE.typesetter:pushHbox({ 
    outputYourself= function () SILE.outputter:pushColor(color) end
  });
  SILE.process(content)
  SILE.typesetter:pushHbox({ 
    outputYourself= function () SILE.outputter:popColor() end
  });
end, "Changes the active ink color to the color <color>.");
