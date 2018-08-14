--Ludum Dare 42
clearEStack()

local function setPalette()
  colorPalette(14,10,10,10)
  colorPalette(15,35,35,35)
end

--Libraries
local bump = Library("bump")
local class = Library("class")

--Contants
local showDialog
local resetRAM
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

--Wires system--

local triggerQueue = {}
local triggerQueueLength = 0

local function TRIGGER(x,y)
  --cprint("TRIGGER",x,y)
  local id = (x/8).."x"..(y/8)
  if WIRES[id] then
    for i=1, #WIRES[id] do
      local tp = WIRES[id][i]
      local tpid = tp[1].."x"..tp[2]
      if triggerQueue[tpid] then
        triggerQueue[tpid] = triggerQueue[tpid] + 1
      else
        triggerQueue[tpid] = 1
        triggerQueue[triggerQueueLength+1] = tp
        triggerQueueLength = triggerQueueLength+1
      end
      
      --[[local items, len = world:queryPoint(tx*8+4,ty*8+4)
      for i2=1,len do
        local item = items[i2]
        if item.trigger then
          item:trigger()
        end
      end]]
    end
  end
end

local function applyTriggers()
  for i=1, triggerQueueLength do
    local tp = triggerQueue[i]
    local tpid = tp[1].."x"..tp[2]
    local num = triggerQueue[tpid]
    local tx,ty = tp[1], tp[2]
    
    local items, len = world:queryPoint(tx*8+4,ty*8+4)
    for i2=1,len do
      local item = items[i2]
      if item.trigger then
        item:trigger(num)
      end
    end
  end
  
  triggerQueue = {}
  triggerQueueLength = 0
end

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

local CHECKPOINT_X, CHECKPOINT_Y = 0,0

--Player
local Player = class("dynamic.Player")

local MainPlayer

function Player:initialize(x,y)
  CHECKPOINT_X, CHECKPOINT_Y = x,y
  MainPlayer = self
  
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 12,12
  
  self.type = "player"
  self.drawLayer = 2
  
  self.rot = math.pi
  
  self.beltPos = 0
  self.beltFrames = 4
  
  self.speed = 90
  self.normalSpeed = 90
  self.slowSpeed = 21
  
  self.hasMirrorBox = false
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function Player:filter(other)
  if self.hasMirrorBox and other == self.hasMirrorBox then
    return false
  elseif other.receiver then
    return false
  elseif other.type == "door" and not other.closed then
    return false
  elseif other.touchtrigger then
    if not other.used then TRIGGER(other.x,other.y) end
    other.used = true
    return false
  elseif other.ignore then
    return false
  end
  return "slide"
end

function Player:move(x,y)
  local actualX, actualY, cols, len = world:move(self,x,y,self.filter)
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
  if self.hasMirrorBox then
    SpriteGroup(17, -8,-8,2,2) --Player Body
    palt(0,true)
    --SpriteGroup(61, -5,-8,2,2) --The box
    palt(0,false)
  else
    SpriteGroup(9, -8,-8,2,2) --Player Body
  end
  
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
    self:updateMirrorBox()
  end
  
  if btnp(5) then
    local bw, bh = 10, 10
    local bcx,bcy = self.x+self.w/2+math.sin(self.rot)*(self.w+bw)*0.5, self.y+self.h/2-math.cos(self.rot)*(self.h+bh)*0.5
    local bx, by = bcx-bw/2, bcy-bh/2
    
    local items, len = world:queryRect(bx,by,bw,bh,function(item)
      if self.hasMirrorBox and item == self.hasMirrorBox then return false end
      if item.touchtrigger or item.ignore then return false end
      return item ~= self
    end)
    
    if self.hasMirrorBox then
      if len == 0 then
        world:update(self.hasMirrorBox,bx,by)
        self.hasMirrorBox.x, self.hasMirrorBox.y = bx, by
        self.hasMirrorBox.drawLayer = 3
        self.hasMirrorBox = nil
        SFX(1)
      else
        SFX(2)
      end
    elseif len > 0 then
      local bcx,bcy = self.x+self.w/2+math.sin(self.rot)*3, self.y+self.h/2-math.cos(self.rot)*3
      local bx, by = bcx-bw/2, bcy-bh/2
      for i=1, len do
        local item = items[i]
        if item.type == "box" and item.mirror then
          self.hasMirrorBox = item
          world:update(self.hasMirrorBox,bx,by)
          self.hasMirrorBox.x, self.hasMirrorBox.y = bx, by
          self.hasMirrorBox.drawLayer = 1
          SFX(0)
          break
        end
      end
      
      if not self.hasMirrorBox then
        SFX(2)
      end
    end
  end
  
  if btnp(6) then
    if self.speed == self.normalSpeed then
      self.speed = self.slowSpeed
    else
      self.speed = self.normalSpeed
    end
  end
end

function Player:updateMirrorBox()
  if not self.hasMirrorBox then return end
  
  local bw, bh = 10, 10
  local bcx,bcy = self.x+self.w/2+math.sin(self.rot)*3, self.y+self.h/2-math.cos(self.rot)*3
  local bx, by = bcx-bw/2, bcy-bh/2
  
  world:update(self.hasMirrorBox,bx,by)
  self.hasMirrorBox.x, self.hasMirrorBox.y = bx, by
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
  self.drawLayer = 4
  
  self.length = 8*32
  
  self.laser = math.pi*0.5*(tid-98)
  self.emitter = true
  
  self.enabled = true
  self.wired = false
  
  if WIRES.IN[(self.x/8).."x"..(self.y/8)] then
    self.enabled = false
    self.wired = true
  end
  
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

function LaserEmitter:castLaser()
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
      elseif item.glass or item.ignore or item.touchtrigger then
        --Pass throw
        x1,y1, x2,y2 = x2,y2, oldx2, oldy2
      elseif item.receiver then
        local pos = {item.x/8, item.y/8}
        if not triggerQueue[pos] then
          triggerQueue[triggerQueueLength+1] = pos
          triggerQueueLength = triggerQueueLength +1
        end
        triggerQueue[pos] = (triggerQueue[pos] or 0) +1
        --TRIGGER(item.x, item.y)
        
        x1 = math.max(item.x+1,math.min(item.x+item.w-3,x1))
        y1 = math.max(item.y+1,math.min(item.y+item.h-3,y1))
      end
    end
    
    self.laserLine[#self.laserLine+1] = x1
    self.laserLine[#self.laserLine+1] = y1
    
    if not info or (not item.mirror and not item.glass and not item.ignore and not item.touchtrigger) then break end
  end
end

function LaserEmitter:trigger()
  self.triggered = true
end

function LaserEmitter:update(dt)
  if self.wired then
    self.enabled = self.triggered
    self.triggered = false
  end
  
  if self.enabled then
    self:castLaser()
  elseif self.laserLine then
    self.laserLine = nil
  end
end

function LaserEmitter:draw()
  if self.laserLine then
    --color(8) lines(unpack(self.laserLine))
    for i=1,#self.laserLine-3,2 do
      line(self.laserLine[i],self.laserLine[i+1],self.laserLine[i+2],self.laserLine[i+3],8)
    end
  end
  
  if not self.enabled then pal(2,0) pal(8,2) end
  Sprite(self.sid,self.x+self.ox,self.y+self.oy)
  if not self.enabled then pal() end
end

--Laser reciever
local LaserReceiver = class("static.LaserReceiver")

function LaserReceiver:initialize(x,y,tid)
  self.x, self.y = x, y
  self.w, self.h = 11, 11
  
  self.type = "wall"
  self.drawLayer = 3
  
  --self.laser = math.pi*0.5*(tid-102)
  self.receiver = true
  self.laser = false
  --self.gotLaser = false
  
  self.sid = 81+tid-102
  self.ox, self.oy = 0,0
  if self.sid < 82 or self.sid > 83 then
    self.ox, self.oy = 1,1
  end
  
  --Add to the bump world
  world:add(self,self.x-1,self.y-1,self.w,self.h)
end

function LaserReceiver:draw()
 -- pal(1,11)
  palt(0,false) palt(14,true)
  if self.laser then pal(0,1) pal(13,12) end
  Sprite(self.sid,self.x+self.ox,self.y+self.oy)
  if self.laser then pal() end
  palt()
  
end

function LaserReceiver:update(dt)
  self.laser = self.triggered
  self.triggered = false
  
  if self.laser then
    TRIGGER(self.x,self.y)
  end
end

function LaserReceiver:trigger()
  self.triggered = true
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

--MirrorBox
local MirrorBox = class("pickable.MirrorBox")

function MirrorBox:initialize(x,y)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 10,10
  
  self.type = "box"
  self.mirror = true
  
  self.drawLayer = 3
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function MirrorBox:draw()
  --Sprite(118, self.x, self.y)
  SpriteGroup(61,self.x,self.y,2,2)
end

function MirrorBox:mirrorLaser(x1,y1,x2,y2)
  local length = 230
  
  local angle = math.atan2(y1-y2,x2-x1)
  
  if x1 <= self.x or x1 >= self.x+self.w-1 then --left/right side
    angle = math.pi - angle
  else --front/back side
    angle = -angle
  end
  
  if x1 <= self.x then x1,y1 = self.x-1,y1+1 end
  if y1 <= self.y then y1 = self.y-1 end
  if x1 >= self.x+self.w-1 then x1,y1 = self.x+self.w-1,y1-1 end
  if y1 >= self.y+self.h-1 then y1,x1 = self.y+self.h-1,x1-1 end
  
  local dx = math.cos(angle)*length + x1
  local dy = -math.sin(angle)*length + y1
  
  return 3, x1,y1,dx,dy
end

--Glass block
local GlassBlock = class("static.GlassBlock")

function GlassBlock:initialize(x,y)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 8,8
  
  self.type = "wall"
  self.glass = true
  
  self.drawLayer = 3
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function GlassBlock:draw()
  Sprite(119,self.x,self.y)
end

--Door
local Door = class("triggerable.Door")

function Door:initialize(x,y,hz)
  self.x, self.y = x, y
  self.w, self.h = hz and 16 or 8, hz and 8 or 16
  
  self.spr = hz and 65 or 63
  self.spr2 = hz and 89 or 64
  self.sprw, self.sprh = hz and 2 or 1, hz and 1 or 2
  
  self.type = "door"
  self.drawLayer = 1
  self.crushTime = 0.4
  self.crushTimer = false
  
  self.closed = true
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function Door:trigger()
  self.triggered = true
end

function Door:update(dt)
  if self.crushTimer then self.crushTimer = self.crushTimer - dt end
  if self.triggered and self.closed then
    SFX(3,2) --Opened
  elseif (not self.triggered) and (not self.closed) then
    SFX(4,2) --Closed
    local items,len = world:queryRect(self.x,self.y,self.w,self.h)
    for i=1, len do
      local item = items[i]
      if item.type == "player" then
        if not self.curshTimer then
          self.crushTimer = self.crushTime
        end
      end
    end
  end
  if self.crushTimer and self.crushTimer <= 0 then
    local items,len = world:queryRect(self.x,self.y,self.w,self.h)
    for i=1, len do
      local item = items[i]
      if item.type == "player" then
        showDialog(-2)
        reboot()
      end
    end
    self.crushTimer = false
  end
  self.closed = not self.triggered
  self.triggered = false
end

function Door:draw()
  SpriteGroup(self.closed and self.spr or self.spr2, self.x, self.y, self.sprw,self.sprh)
end

--Delay
local Delay = class("wire.Delay")

function Delay:initialize(x,y,instant)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  
  self.time = 1
  self.timer = 0
  self.active = false
  self.instant = instant
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function Delay:trigger()
  self.timer = self.time
  self.active = self.instant
end

function Delay:update(dt)
  if self.active then
    self.timer = self.timer - dt
    TRIGGER(self.x,self.y)
    if self.timer <= 0 then
      self.active = false
    end
  elseif self.timer > 0 then
    self.active = true
  end
end

--Start trigger
local STrigger = class("wire.STrigger")

function STrigger:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  
  self.timer = 0.1
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function STrigger:update(dt)
  if self.timer ~= -1 then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      TRIGGER(self.x,self.y)
      self.timer = -1
    end
  end
end

--Touch trigger
local TTrigger = class("wire.TTrigger")

function TTrigger:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  self.touchtrigger = true
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

--FREP
local WREP = class("wire.Repeater")

function WREP:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function WREP:trigger()
  self.triggered = true
end

function WREP:update(dt)
  if self.triggered then
    TRIGGER(self.x,self.y)
  end
  
  self.triggered = false
end

--FUSE
local WFUSE = class("wire.Fuse")

function WFUSE:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  self.timer = 0.5
  
  self.active = false
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function WFUSE:trigger()
  if self.timer >= 0 then return end
  self.triggered = true
end

function WFUSE:update(dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
    return
  end
  
  if self.active then
    TRIGGER(self.x, self.y)
  end
  
  if self.triggered then
    self.active = true
    self.triggered = false
  end
end

--AND
local WAND = class("wire.And")

function WAND:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  
  self.total = WIRES.IN[(x/8).."x"..(y/8)] or 0
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function WAND:trigger(num)
  self.triggered = num
end

function WAND:update(dt)
  if self.triggered and self.triggered >= self.total then
    TRIGGER(self.x,self.y)
    self.triggered = false
  end
end

--not
local WNOT = class("wire.Not")

function WNOT:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function WNOT:trigger()
  self.triggered = true
end

function WNOT:update(dt)
  if not self.triggered then
    TRIGGER(self.x,self.y)
  end
  
  self.triggered = false
end

--dia
local WDIA = class("wire.DIA")

function WDIA:initialize(x,y,id)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  self.id = id
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function WDIA:trigger()
  self.triggered = true
end

function WDIA:update(dt)
  if self.triggered and self.id then
    showDialog(self.id)
    self.id = nil
  end
  
  self.triggered = false
end

--checkpoint
local WCP = class("wire.CP")

function WCP:initialize(x,y)
  self.x, self.y = x,y
  self.w, self.h = 8,8
  
  self.type = "special"
  self.ignore = true
  self.used = false
  
  --Add to the bump world
  world:add(self,self.x,self.y,self.w,self.h)
end

function WCP:trigger()
  self.triggered = true
end

function WCP:update(dt)
  if self.triggered and not self.used then
    CHECKPOINT_X, CHECKPOINT_Y = self.x, self.y
    resetRAM()
    self.used = true
  end
  
  self.triggered = false
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
    elseif tid == 123 then
      Delay(x*8,y*8)
      return 2 --Convert into wall
    elseif tid == 124 then
      WAND(x*8,y*8)
      return 2 --Convert into wall
    elseif tid == 125 then
      STrigger(x*8,y*8)
      return 2 --Convert into wall
    elseif tid == 126 then
      WNOT(x*8,y*8)
      return 2 --Convert into wall
    elseif tid == 73 then
      WFUSE(x*8,y*8)
      return 2 --Convert into wall
    elseif tid == 74 then
      WREP(x*8,y*8)
      return 2 --Convert into wall
    elseif tid == 75 then
      Delay(x*8,y*8,true)
      return 2 --Convert into wall
    elseif tid >= 128 then
      WDIA(x*8,y*8,tid-127)
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
    elseif tid == 118 then --Mirror box
      MirrorBox(x*8,y*8)
    elseif tid == 119 then --Glass block
      GlassBlock(x*8,y*8)
    elseif tid == 121 then --Door vertical
      Door(x*8,y*8,false)
    elseif tid == 122 then --Door horizental
      Door(x*8,y*8,true)
    elseif tid == 127 then --Touch trigger
      TTrigger(x*8,y*8)
    elseif tid == 120 then --Check point
      WCP(x*8,y*8)
    end
  end)
end

local drawLayer = 1
local function layerDrawFilter(item)
  return (item.drawLayer and item.drawLayer == drawLayer)
end

local darkpal = {0,0,5,1,2,1,13,6,2,4,9,3,13,5,0,0}
--Chat pop up
showDialog = function(id)
  local backup = screenshot()
  local scr = screenshot()
  scr:map(function(x,y,c)
    return darkpal[c+1]
  end)

  scr = scr:image()
  
  clear(0) scr:draw()
  colorPalette()
  
  local dialog = DIALOGS[id]
  local dPos = 1
  
  local icon, name, message, cchar = 289 + (dialog[dPos]-1)*4, dialog[dPos+1], dialog[dPos+2], 1
  dPos = dPos+3
  
  message = table.concat(select(2,wrapText(message,sw-32-4-6-6)),"\n")
  
  for event, a,b,c,d,e,f in pullEvent do
    if event == "keypressed" then
      __BTNKeypressed(a,c)
    elseif event == "touchcontrol" then
      __BTNTouchControl(a,b)
    elseif event == "gamepad" then
      __BTNGamepad(a,b,c)
    elseif event == "update" then
      clear(0) scr:draw()
      
      --Update line cut
      cchar = cchar + a*25
      
      --ICON--
      local iconX, iconY = 2, sh-2 - 32-2-2
      rect(iconX,iconY,32+2+2,32+2+2,false,0)
      rect(iconX,iconY,32+2+2,32+2+2,true,7)
      if cchar >= #message then
        SpriteGroup(icon,iconX+2,iconY+2,2,2, 2,2)
      else
        SpriteGroup(icon+(math.floor(os.clock()*8)%2)*2,iconX+2,iconY+2,2,2, 2,2)
      end
      
      --NAME--
      local nameX, nameY = iconX, iconY - 11
      local nameW = #name*5 + 3
      rect(nameX,nameY,nameW,10,false,0)
      rect(nameX,nameY,nameW,10,true,7)
      color(7) print(name,nameX+2,nameY+2)
      
      --TEXT--
      local tboxX, tboxY = iconX+32+4+2, iconY
      rect(tboxX,tboxY,sw-tboxX-2,32+4,false,0)
      rect(tboxX,tboxY,sw-tboxX-2,32+4,true,7)
      clip(tboxX,tboxY,sw-tboxX-2,32+4)
      
      if cchar >= #message then
        color(6) print(message:sub(1,cchar),tboxX+3,tboxY+4)
      else
        color(6) print(message:sub(1,cchar).."\xFF",tboxX+3,tboxY+4)
      end
      
      clip()
      
      if cchar > #message+1 then
        local ux, uy = nameX+nameW+2,nameY
        rect(ux,uy,sw-ux-2,10,false,0)
        rect(ux,uy,sw-ux-2,10,true,7)
        color(13) print("Press   to continue.",ux+2,uy+2)
        Sprite(193,ux+2+5*5+2,uy+1)
        
        if btnp(5) then
          if dialog[dPos] then
            icon, name, message, cchar = 289 + (dialog[dPos]-1)*4, dialog[dPos+1], dialog[dPos+2], 1
            dPos = dPos+3
            
            message = table.concat(select(2,wrapText(message,sw-32-4-6-6)),"\n")
          else break end
        end
      elseif btnp(5) then
        cchar = #message
      end
      
      if btnp(7) then break end
      
      __BTNUpdate(a)
    end
  end
  
  if id == 6 then
    openURL("https://ldjam.com/events/ludum-dare/42/lasersbot")
    shutdown()
  end
  
  clear(0)
  backup:image():draw()
  setPalette()
  clearEStack()
end

--The VRAM effects
local badPixelsImageData = imagedata(sw,sh)
badPixelsImageData:map(function() return 15 end)
local badPixelsImage = badPixelsImageData:image()
local totalBadPixels = 0
local screenPixels = 192*128*0.6
--local badAddresses = {}
local randomizeTime = 0.25
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
  else
    return newBadAddress()
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

local RAM = 6*1024

resetRAM = function()
  badPixelsImageData:map(function() return 15 end)
  badPixelsImage:refresh()
  totalBadPixels = 0
  RAM = 6*1024
  showDialog(-1)
end

--Events
function _init()
  clear(0)
  _processLasers()
  _processBgMap()
  _processObjects()
  setPalette()
end

function _update(dt)
  --Update objects
  do
    local items, len = world:getItems()
    for i=1, len do
      if items[i].update then
        items[i]:update(dt)
      end
    end
  end
  
  applyTriggers()
  
  if RAM > 0 then
    RAM = RAM - 400*dt
  else
    --Randomize bad pixels
    randomizeTimer = randomizeTimer - dt
    if randomizeTimer <= 0 then
      randomizeTimer = randomizeTime
      for i=1,25 do newBadAddress() end
    end
    
    if totalBadPixels >= screenPixels then
      --[[resetRAM()
      MainPlayer:move(CHECKPOINT_X,CHECKPOINT_Y)
      MainPlayer.rot = 0]]
      
      showDialog(0)
      reboot()
    end
  end
end

local k6 = 6*1024
local k12 = 12*1024

function _draw()
  clear(14)
  
  pushMatrix()
  cam("translate",math.floor(sw/2-MainPlayer.x-MainPlayer.w/2),math.floor(sh/2-MainPlayer.y-MainPlayer.h/2))
  
  --Draw background
  bgBatch:draw()
  
  --Draw objects
  for layer=4,1,-1 do
    drawLayer = layer
    local items, len = world:queryRect(0,0,mw*8+8,mh*8+8,layerDrawFilter)
    for i=1,len do
      items[i]:draw()
    end
  end
  
  popMatrix()
  
  --VRAM effects
  pokeBadAddress()
  
  --RAM bar
  
  rect(0,0,sw,4,false,0)
  rect(-1,-1,sw+2,6,true,6)
  rect(0,0,sw/2,3,false,5)
  rect(sw/2+1,0,sw/2,3,false,13)
  rect(0,0,((k6-RAM)/k12 + (totalBadPixels/screenPixels)/2)*sw,4,false,8)
end