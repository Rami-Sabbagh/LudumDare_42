--Ludum Dare 42

--Libraries
local bump = Library("bump")
local class = Library("class")

--Contants
local sw,sh = screenSize()
local mw,mh = TileMap:size()
local diagonalFactor = math.sin(math.pi/4)

--Map Layers
local initMap = TileMap:cut() --Clone the map.
local bgMap = MapObj(mw+1,mh+1,SpriteMap) --Contains walls and background grid.

--Spritebatches
local bgBatch = SpriteMap.img:batch((mw+1)*(mh+1),"static")

--Bump world
local cellSize = 4
local world = bump.newWorld(cellSize)

--Classes
local instances = {}

--Wall
local Wall = class("static.Wall")

function Wall:initialize(x,y)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 9,9
  
  self.type = "wall"
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
  
  --Insert into the instances table
  instances[#instances+1] = self
end

--Player
local Player = class("dynamic.Player")

function Player:initialize(x,y)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 12,12
  
  self.type = "player"
  self.drawLayer = 1
  
  self.rot = 0
  
  self.beltPos = 0
  self.beltFrames = 4
  
  self.speed = 1
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
  
  --Insert into the instances table
  instances[#instances+1] = self
end

function Player:move(x,y)
  local actualX, actualY, cols, len = world:move(self,x,y)
  self.x, self.y = actualX, actualY
end

function Player:draw()
  palt(0,false)
  palt(14,true)
  pushMatrix()
  
  cam("translate",self.x+self.w/2,self.y+self.h/2)
  cam("rotate",self.rot)
  
  SpriteGroup(math.floor(13+self.beltPos), -8, -8, 1,2) --Belt left
  SpriteGroup(math.floor(13+self.beltPos), -8+16, -8, 1,2, -1) --Belt right
  SpriteGroup(11, -8,-8,2,2) --Player Base
  SpriteGroup(9, -8,-8,2,2) --Player Body
  
  popMatrix()
  palt()
end

function Player:checkControls(dt)
  local dx, dy = 0, 0
  
  if btn(1) then dx = -1 elseif btn(2) then dx = 1 end
  if btn(3) then dy = -1 elseif btn(4) then dy = 1 end
  
  if dx ~= 0 or dy ~= 0 then
    if dx ~= 0 and dy ~= 0 then dt = dt*diagonalFactor end
    self.rot = math.atan2(dx,-dy)
    local goalX, goalY = self.x + self.speed*dx*dt, self.y + self.speed*dy*dt
    self:move(goalX,goalY)
    self.beltPos = (self.beltPos + self.speed*dt) % self.beltFrames
  end
end

function Player:update(dt)
  self:checkControls(dt)
end

--Functions
local function _processBgMap()
  bgBatch:clear()
  
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
  
  local function setCell(x,y,tid,obj)
    bgMap:cell(x,y,tid)
    bgBatch:add(SpriteMap:quad(tid),x*8,y*8)
    if obj then Wall(x*8,y*8) end
  end

  initMap:map(function(x,y,tid)
      if tid == 2 then --Wall tile
        if isnt(x-1,y) and isnt(x,y-1) and is(x-1,y-1) then
          setCell(x,y,51,true)
        elseif isnt(x-1,y) and isnt(x,y-1) then
          setCell(x,y,3,true)
        elseif isnt(x-1,y) then
          setCell(x,y,27,true)
        elseif isnt(x,y-1) then
          setCell(x,y,4,true)
        elseif is(x-1,y) and is(x,y-1) and isnt(x-1,y-1) then
          setCell(x,y,52,true)
        else
          setCell(x,y,28,true)
        end
      else
        if is(x-1,y) and is(x,y-1) then
          setCell(x,y,5)
        elseif is(x-1,y) and is(x-1,y-1) then
          setCell(x,y,29)
        elseif is(x-1,y) then
          setCell(x,y,53)
        elseif is(x,y-1) and is(x-1,y-1) then
          setCell(x,y,6)
        elseif is(x,y-1) then
          setCell(x,y,7)
        elseif is(x-1,y-1) then
          setCell(x,y,30)
        else
          setCell(x,y,1)
        end
      end
    end)
end

local function _processObjects()
  initMap:map(function(x,y,tid)
    if tid == 97 then --Player
      Player(x*8,y*8)
    end
  end)
end

local drawLayer = 1
local function layerDrawFilter(item)
  if item.drawLayer and item.drawLayer == drawLayer then
    return true
  else
    return false
  end
end

local function updateFilter(item)
  return not not item.update
end

--Events
function _init()
  clear(0)
  colorPalette(14,10,10,10)
  colorPalette(15,35,35,35)
  _processBgMap()
  _processObjects()
end

function _update(dt)
  --Update objects
  do
    local items, len = world:queryRect(0,0,mw*8,mh*8,updateFilter)
    for i=1, len do
      items[i]:update(1)
    end
  end
end

function _draw()
  clear(14)
  
  --Draw background
  bgBatch:draw()
  
  --Draw objects
  for layer=1,1 do
    drawLayer = layer
    local items, len = world:queryRect(0,0,sw,sh,layerDrawFilter)
    for i=1,len do
      items[i]:draw()
    end
  end
  
  --Draw clock pixel
  if os.time()%2 == 0 then
    rect(0,0,1,1,false,8)
  end
end