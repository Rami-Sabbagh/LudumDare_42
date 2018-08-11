--Ludum Dare 42

--Contants
local sw,sh = screenSize()
local mw,mh = TileMap:size()

--Map Layers
local initMap = TileMap:cut() --Clone the map.
local bgMap = MapObj(mw+1,mh+1,SpriteMap) --Contains walls and background grid.

local function _processBgMap()
  local function is(x,y)
    local tid = initMap:cell(x,y)
    if tid and tid == 2 then return true end
    return false
  end

  local function isnt(x,y)
    local tid = initMap:cell(x,y)
    if tid and tid == 2 then return false end
    return true
  end

  initMap:map(function(x,y,tid)
      if tid == 2 then --Wall tile
        if isnt(x-1,y) and isnt(x,y-1) and is(x-1,y-1) then
          bgMap:cell(x,y,51)
        elseif isnt(x-1,y) and isnt(x,y-1) then
          bgMap:cell(x,y,3)
        elseif isnt(x-1,y) then
          bgMap:cell(x,y,27)
        elseif isnt(x,y-1) then
          bgMap:cell(x,y,4)
        elseif is(x-1,y) and is(x,y-1) and isnt(x-1,y-1) then
          bgMap:cell(x,y,52)
        else
          bgMap:cell(x,y,28)
        end
      else
        if is(x-1,y) and is(x,y-1) then
          bgMap:cell(x,y,5)
        elseif is(x-1,y) and is(x-1,y-1) then
          bgMap:cell(x,y,29)
        elseif is(x-1,y) then
          bgMap:cell(x,y,53)
        elseif is(x,y-1) and is(x-1,y-1) then
          bgMap:cell(x,y,6)
        elseif is(x,y-1) then
          bgMap:cell(x,y,7)
        elseif is(x-1,y-1) then
          bgMap:cell(x,y,30)
        else
          bgMap:cell(x,y,1)
        end
      end
    end)
end

function _init()
  clear(0)
  colorPalette(0,10,10,10)
  colorPalette(5,35,35,35)
  _processBgMap()
end

function _update(dt)
  
end

function _draw()
  bgMap:draw()
end