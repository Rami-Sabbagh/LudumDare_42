local term = require("terminal")
term.execute("save") flip()
term.execute("tileset") flip()

local first = true

clear(0)
printCursor(0,0,0)
while true do
  cam()
  pal()
  palt()
  printCursor(false,false,0)
  color(7)
  if not first then
    print("Press any key to run")
    for event, key in pullEvent do
      if event == "keypressed" then
        if key == "escape" then return end
        break
      end
    end
  else
    first = false
  end
  term.execute("tiled")
  flip()
  term.execute("run")
end