local mapcode = fs.load("D:/Jam/map.lua")()
local layer = mapcode.layers[1]
local tdata = "LK12;TILEMAP;"..layer.width.."x"..layer.height..";"
tdata = tdata..table.concat(layer.data,";")..";"

local eapi = require("Editors")

local teditor = eapi.leditors[eapi.editors.tile]
teditor:import(tdata)
fs.write("D:/Jam/map.lk12",tdata)

local term = require("terminal")
term.execute("save")

--Import wires:
local wires = {}
wires.IN = {}

local objlayer = mapcode.layers[2]
for _,obj in ipairs(objlayer.objects) do
  if obj.shape == "polyline" and obj.visible then
    local ox, oy = obj.x, obj.y
    local sx, sy = obj.polyline[1].x+ox, obj.polyline[1].y+oy
    local ex, ey = obj.polyline[#obj.polyline].x+ox, obj.polyline[#obj.polyline].y+oy
    sx, sy = math.floor(sx/8), math.floor(sy/8)
    ex, ey = math.floor(ex/8), math.floor(ey/8)
    local id = sx.."x"..sy
    if not wires[id] then wires[id] = {} end
    wires[id][#wires[id]+1] = {ex,ey}
    wires.IN[ex.."x"..ey] = (wires.IN[ex.."x"..ey] or 0) + 1
  end
end

local JSON = require("Libraries.JSON")
local jdata = JSON:encode(wires)
fs.write("D:/Jam/wires.json",jdata)
fs.write("D:/Jam/wires.lua",[===[
local JSON = Library("JSON")
local wiresData = [==[]===]..jdata..[===[]==]

WIRES = JSON:decode(wiresData)
]===])