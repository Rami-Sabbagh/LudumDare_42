--Ludum Dare 42

--Libraries
local bump = Library("bump")
local class = Library("class")

--Contants
local sw,sh = screenSize()
local mw,mh = TileMap:size()
local diagonalFactor = math.sin(math.pi/4)
local band, rshift = bit.band, bit.rshift

--Map Layers
local prcMap = TileMap:cut() --Clone the map.
local bgMap = MapObj(mw+1,mh+1,SpriteMap) --Contains walls and background grid.

--Spritebatches
local bgBatch = SpriteMap.img:batch((mw+1)*(mh+1),"static")

--Bump world
local cellSize = 4
local world = bump.newWorld(cellSize)

--Classes--

--Wall
local Wall = class("static.Wall")

function Wall:initialize(x,y)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 9,9
  
  self.type = "wall"
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
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
  
  self.speed = 1.5
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function Player:move(x,y)
  local actualX, actualY, cols, len = world:move(self,x,y)
  self.x, self.y = actualX, actualY
end

function Player:draw()
  palt(0,false)
  palt(14,true)
  pushMatrix()
  
  cam("translate",math.floor(self.x+self.w/2),math.floor(self.y+self.h/2))
  cam("rotate",self.rot)
  
  SpriteGroup(13+self.beltPos, -8, -8, 1,2) --Belt left
  SpriteGroup(13+self.beltPos, -8+16, -8, 1,2, -1) --Belt right
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

--Laser emitter
local LaserEmitter = class("static.LaserEmitter")

function LaserEmitter:initialize(x,y,tid)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 9, 9
  
  self.type = "wall"
  self.drawLayer = 2
  
  self.length = 8*32
  
  self.laser = math.pi*0.5*(tid-98)
  self.emitter = true
  self.enabled = true
  
  self.laserDx = self.x+4+math.cos(self.laser)*self.length
  self.laserDy = self.y+4+math.sin(self.laser)*-self.length
  
  self.sid = 57+tid-98
  self.ox, self.oy = 0,0
  if self.sid < 58 or self.sid > 59 then
    self.ox, self.oy = 1,1
  end
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function LaserEmitter:update(dt)
  local x1,y1, x2,y2 = self.x+4, self.y+4, self.laserDx, self.laserDy
  self.laserLine = {x1,y1}
  local item = self
  
  while true do
    local infos, len = world:querySegmentWithCoords(x1,y1, x2,y2)
    local index = 1; if item == self then index = 3 elseif infos[1] and infos[1].item == item then index = 2 end
    local info = infos[index]
    if info then
      local oldx2, oldy2 = x2, y2
      item, x1,y1, x2,y2 = info.item, info.x1, info.y1, info.x2, info.y2
      
      if item.mirror then
        local state,ix,iy, dx,dy = item:mirrorLaser(x1,y1, x2,y2)
        if state == 3 then --reflect
          x1,y1, x2,y2 = ix,iy, dx,dy
        elseif state == 2 then --block
          info = false
        elseif state == 1 then --passthrow
          x1,y1, x2,y2 = x2,y2, oldx2, oldy2
        end
      end
    end
    
    self.laserLine[#self.laserLine+1] = x1
    self.laserLine[#self.laserLine+1] = y1
    
    if not info or not item.mirror then break end
  end
end

function LaserEmitter:draw()
  if self.laserLine then
    color(8) lines(unpack(self.laserLine))
  end
  
  Sprite(self.sid,self.x+self.ox,self.y+self.oy)
end

--Laser reciever
local LaserReceiver = class("static.LaserReceiver")

function LaserReceiver:initialize(x,y,tid)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 9, 9
  
  self.type = "wall"
  self.drawLayer = 2
  
  self.laser = math.pi*0.5*(tid-102)
  self.receiver = true
  self.enabled = true
  
  self.sid = 81+tid-102
  self.ox, self.oy = 0,0
  if self.sid < 82 or self.sid > 83 then
    self.ox, self.oy = 1,1
  end
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function LaserReceiver:draw()
  Sprite(self.sid,self.x+self.ox,self.y+self.oy)
end

--Laser Mirror
local LaserMirror = class("static.LaserMirror")

do
  --Check if this point is over the reflection line or not.
  local function ovrl(self,x,y)
    local bx, by, fx, fy, w,h = self.x, self.y, self.fx, self.fy, self.w, self.h
    local r1, r2 = false, false
    if fx then r1 = (x >= bx+w-1) else r1 = (x <= bx) end
    if fy then r2 = (y >= by+h-1) else r2 = (y <= by) end
    return r1 or r2
  end
  
  local function getIntersection(x1,y1,x2,y2, x3,y3,x4,y4)
    local a,b,c = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4), (x1*y2-y1*x2), (x3*y4-y3*x4)
    return (b*(x3-x4)-(x1-x2)*c)/a,(b*(y3-y4)-(y1-y2)*c)/a
  end

  function LaserMirror:initialize(x,y,tid)
    self.type = "wall"
    self.mirror = true
    self.tid = tid
    
    --Add to the bg batch
    bgBatch:add(SpriteMap:quad(self.tid),x,y)
    
    if self.tid <= 109 then --45 digree
      self.vid = self.tid - 106
      self.x, self.y, self.w, self.h = x,y, 8,8
      self.angle = math.pi/4
    elseif self.tid <= 113 then --22.5 diggree
      self.vid = self.tid - 110
      self.angle = math.pi/8
      
      if self.vid == 0 or self.vid == 1 then
        self.x, self.y, self.w, self.h = x,y+4, 8,4
      elseif self.vid == 2 or self.vid == 3 then
        self.x, self.y, self.w, self.h = x,y, 8,4
      end
    else -- 67.5 digree
      self.vid = self.tid - 114
      self.angle = math.pi/2 - math.pi/8
      
      if self.vid == 0 or self.vid == 3 then
        self.x, self.y, self.w, self.h = x+4,y, 4,8
      elseif self.vid == 1 or self.vid == 2 then
        self.x, self.y, self.w, self.h = x,y, 4,8
      end
    end
    
    if self.vid == 0 then
      self.fx, self.fy = false,false
    elseif self.vid == 1 then
      self.fx, self.fy = true,false
      self.angle = math.pi - self.angle
    elseif self.vid == 2 then
      self.fx, self.fy = true,true
      --self.angle = math.pi*2-self.angle
    elseif self.vid == 3 then
      self.fx, self.fy = false,true
      self.angle = -self.angle--self.angle - math.pi
    end
    
    --Add to the bump world
    world:add(self,self.x,self.y,self.w,self.h)
  end
  
  function LaserMirror:mirrorLaser(x1,y1,x2,y2)
    if ovrl(self,x1,y1) and ovrl(self,x2,y2) then
      return 1 --Pass throw
    elseif not (ovrl(self,x1,y1) or ovrl(self,x2,y2)) then
      return 2 --Block
    else
      local ix, iy = getIntersection(self.x,self.y+self.h,self.x+self.w,self.y, x1,y1,x2,y2)
      
      local angle = self.angle*2 - math.atan2(y1-iy,ix-x1)
      
      local length = 230
      
      local dx = math.cos(angle)*length + ix
      local dy = -math.sin(angle)*length + iy
      
      return 3, ix,iy,dx,dy
    end
  end
end

--Functions
local function _processLasers()
  prcMap:map(function(x,y,tid)
    if tid >= 98 and tid <= 101 then
      LaserEmitter(x*8,y*8,tid)
      return 2 --Convert into wall
    elseif tid >= 102 and tid <= 105 then
      LaserReceiver(x*8,y*8,tid)
      return 2 --Convert into wall
    end
  end)
end

local function _processBgMap()
  bgBatch:clear()
  
  local function is(x,y)
    local tid = prcMap:cell(x,y)
    if tid and tid == 2 then return true end
    return false
  end

  local function isnt(x,y)
    local tid = prcMap:cell(x,y)
    if tid and tid == 2 then return false end
    return true
  end
  
  local function setCell(x,y,tid,obj)
    bgMap:cell(x,y,tid)
    bgBatch:add(SpriteMap:quad(tid),x*8,y*8)
    if obj then Wall(x*8,y*8) end
  end

  prcMap:map(function(x,y,tid)
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
  prcMap:map(function(x,y,tid)
    if tid == 97 then --Player
      Player(x*8,y*8)
    elseif tid >= 106 and tid <= 117 then --Laser mirror
      LaserMirror(x*8,y*8,tid)
    end
  end)
end

local drawLayer = 1
local function layerDrawFilter(item)
  return (item.drawLayer and item.drawLayer == drawLayer)
end

local function updateFilter(item)
  return item.update
end

--The VRAM effects
local badPixelsImageData = imagedata(sw,sh)
badPixelsImageData:map(function() return 15 end)
local badPixelsImage = badPixelsImageData:image()
local totalBadPixels = 0
--local badAddresses = {}
local randomizeTime = 1
local randomizeTimer = randomizeTime

local function newBadAddress()
  local x,y,value = math.random(0,sw/2)*2, math.random(0,sh-1), math.random(0,255)
  
  --Separate the 2 pixels from each other
  local lpix = band(value,0xF0)
  local rpix = band(value,0x0F)
  
  --Shift the left pixel
  lpix = rshift(lpix,4)
  
  if badPixelsImageData:getPixel(x,y) == 15 then
    totalBadPixels = totalBadPixels + 2
  end
  
  --Set the pixels
  badPixelsImageData:setPixel(x,y,math.min(lpix,14))
  badPixelsImageData:setPixel(x+1,y,math.min(rpix,14))
  
  --Update the image
  badPixelsImage:refresh()
end

local function pokeBadAddress()
  palt(0,false) palt(15,true)
  badPixelsImage:draw()
  palt()
end

--Events
function _init()
  clear(0)
  colorPalette(14,10,10,10)
  colorPalette(15,35,35,35)
  _processLasers()
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
  
  --Randomize bad pixels
  --[[randomizeTimer = randomizeTimer - dt
  if randomizeTimer <= 0 or true then
    randomizeTimer = randomizeTime
    for i=1,10 do newBadAddress() end
  end]]
end

function _draw()
  clear(14)
  
  --Draw background
  bgBatch:draw()
  
  --Draw objects
  for layer=2,1,-1 do
    drawLayer = layer
    local items, len = world:queryRect(0,0,sw,sh,layerDrawFilter)
    for i=1,len do
      items[i]:draw()
    end
  end
  
  --VRAM effects
  pokeBadAddress()
end