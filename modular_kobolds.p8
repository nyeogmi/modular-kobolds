pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
posers={}
movers={}

function _init()
 microgame:init()
 
 local function add_poser(anim)
  local k=moko:new(0,{11,3,8})
  k:loop(anim)
  add(posers,k)
 end
 for i in all{"run","idle","walk","crawl","crouch","jump"} do
  add_poser(i)
 end
 
 local function add_mover(k,anim,hsp)
  k:loop(anim)
  add(movers,{
   kobold=k,
   x=0,
   hsp=hsp
  })
 end

 add_mover(moko:new(2,{9,4,11}),"run",1)
 add_mover(moko:new(3,{8,2,11}),"walk",0.5)
 add_mover(moko:new(1,{10,9,12}),"crawl",0.25)
 
 demo_t=0
end

function _update()
 microgame:update()
 for k in all(posers) do
  k:update()
 end
 
 for k in all(movers) do
  k.kobold:update()
  k.x+=k.hsp
  if k.x > 96 then
   k.hsp=-abs(k.hsp)
  elseif k.x < 32 then
   k.hsp=abs(k.hsp)
  end
 end
 
 demo_t+=1
end

function _draw()
 local flip_x=(demo_t\30)%2==1
 local flip_y=(demo_t\60)%2==1
 
 cls(0)
 local wx=12*#posers
 for i,k in ipairs(posers) do
  k:draw(64-wx/2+(i-1)*12,64,flip_x,flip_y)
 end
 
 for i,m in ipairs(movers) do
  m.kobold:draw(m.x,64+i*16,m.hsp<0)
 end
 
 microgame:draw()
end
-->8
moko={}
moko.__index=moko

function moko:new(head,palette)
 palette=palette
 local k={
  palette=palette,
  head=head,
  
  loop_anim="idle",
  loop_t=0,
  loop_rate=1/16,
  play_anim=nil,
  play_t=0,
  play_rate=1/16,
  play_on_done=nil,
  
  -- extremely internal
  attach={
   far_hand=nil,
   near_hand=nil
   -- todo: rest of body
   -- todo: tail
  },
  anim="idle"
 }
 setmetatable(k,self)
 return k
end

function moko:update()
 if self.play_anim!=nil then
  self.loop_t=0
  self.play_t+=self.play_rate
  if self.play_t>1 then
   self.play_anim=nil
   if self.play_on_done then 
    self.play_on_done()
   end
  end
 else
  self.loop_t+=self.loop_rate
  self.loop_t%=1
 end
end

function moko:loop(anim,rate,continue)
 if self.loop_anim!=anim then
  self.loop_anim=anim
  if not continue then self.loop_t=0 end
 end
 
 self.loop_rate=rate or 1/16
end

function moko:play(anim,rate,on_done)
 if self.play_anim!=anim then
  self.play_anim=anim
  self.play_t=0
 end
 
 self.play_rate=rate or 1/16
 self.play_on_done=on_done
end

function moko:draw(x,y,flip_x,flip_y)
 self._x=flr(x)
 self._y=flr(y)
 self._flip_x=flip_x
 self._flip_y=flip_y
 local palette=self.palette
 
 local p4=palette[4]
 if p4 == nil then p4=palette[1] end
 pal(7,palette[1])
 pal(6,palette[2])
 pal(8,palette[3])
 pal(5,p4)
 
 local anim,t
 if self.play_anim!=nil then
  anim=self.play_anim
  t=self.play_t
 else
  anim=self.loop_anim
  t=self.loop_t
 end
 self._t=flr(t*16)
 self:_anim(anim)(self)
 
 pal()
end

function moko:_anim(a)
 while true do
  local anim_f=self["draw_"..(a or self.anim)]
  if (anim_f) return anim_f
  a="idle"
 end  
end

-- note: these are for both
-- legs, but i plotted
-- the far arm and leg here:
-- https://www.slynyrd.com/blog/2018/8/19/pixelblog-8-intro-to-animation
local _moko_run={
 headx=split"0,0,0,0,0,0,0,0",
 heady=split"-1,0,0,-1,-1,0,0,-1",
 armx=split"-1,-1,0,1,1,1,0,-1",
 army=split"-1,-1,-1,0,0,-1,-1,-1",
 legx=split"2,1,0,-1,-1,-1,0,1",
 legy=split"0,0,0,0,-1,-1,-1,-1"
}
 
function moko:draw_run()
 self:draw_cyc(_moko_run)
end

-- based on run anim, no head bobble
local _moko_walk={
 headx=split"0,0,0,0,0,0,0,0",
 heady=split"0,0,0,0,0,0,0,0",
 armx=split"-1,-1,0,1,1,1,0,-1",
 army=split"-0,0,0,0,0,0,0,0",
 legx=split"1,1,0,-1,-1,-1,0,1",
 legy=split"0,0,0,0,-1,-1,-1,-1"
}

function moko:draw_walk()
 self:draw_cyc(_moko_walk)
end

local _moko_crawl={
 headx=split"1,1,1,1,1,1,1,1",
 heady=split"3,3,3,3,3,3,3,3",
 armx=split"1,0,-2,-2,-2,0,0,1,1",
 army=split"2,2,2,2,1,1,1,1",
 legx=split"0,-1,-3,-3,-3,-1,-1,0,0",
 legy=split"0,0,0,0,-1,-1,-1,-1"
}

function moko:draw_crawl()
 self:draw_cyc(_moko_crawl,self._t/2)
end

local _moko_idle={
 headx=split"0,0,0,0,0,0,0,0",
 heady=split"0,0,0,0,0,0,0,0",
 armx=split"-1,-1,-1,-1,-1,-1,-1,-1",
 army=split"0,0,0,0,0,0,0,0",
 legx=split"0,0,0,0,0,0,0,0",
 legy=split"0,0,0,0,0,0,0,0"
}

function moko:draw_idle()
 self:draw_cyc(_moko_idle)
end

local _moko_crouch={
 headx=split"2,2,2,2,2,2,2,2",
 heady=split"2,2,2,2,2,2,2,2",
 armx=split"-1,-1,-1,-1,-1,-1,-1,-1",
 army=split"1,1,1,1,1,1,1,1",
 legx=split"0,0,0,0,0,0,0,0",
 legy=split"0,0,0,0,0,0,0,0",
 ldx_far=1
}

function moko:draw_crouch()
 self:draw_cyc(_moko_crouch)
end

local _moko_jump={
 headx=split"0,0,1,1,1,1,2,2",
 heady=split"0,0,1,1,1,1,2,1",
 armx=split"0,0,1,3,3,3,1,1",
 army=split"0,0,1,2,2,2,1,1",
 legx=split"0,0,0,0,0,0,0,0",
 legy=split"0,0,0,0,0,0,0,0",
 ldx_far=1,
 non_cyclical=true
}

function moko:draw_jump()
 self:draw_cyc(_moko_jump)
end

function moko:draw_cyc(cy,t)
 t=t or self._t
 local lframe=flr(t%16)\2
 local rframe=(lframe+4)%8
 if cy.non_cyclical then
  rframe=lframe
 end
 lframe+=1
 rframe+=1
 
 self:_draw_smolbox(
  -1+cy.armx[lframe],cy.army[lframe],6,
  self.attach.far_hand
 )
 self:_draw_smolbox(
  -2+cy.legx[lframe]+(cy.ldx_far or 0),
  2+cy.legy[lframe],
  6
 )
 self:_draw_head(-4+cy.headx[lframe],-5+cy.heady[lframe])
 
 self:_draw_smolbox(
  -2+cy.legx[rframe],
  2+cy.legy[rframe],
  5 
 )
 self:_draw_smolbox(
  -2+cy.armx[rframe],
  cy.army[rframe],
  5,
  self.attach.near_hand
 )
end

function moko:_draw_smolbox(x,y,c,attachment)
 local attch_x, attch_y
 if self._flip_x then
  x=self._x-x-1
  attch_x=x-3
 else
  x+=self._x
  attch_x=x-3
 end
 
 if self._flip_y then
  y=self._y-y-1
  attch_y=y-3
 else
  y+=self._y
  attch_y=y-3
 end

 rectfill(x,y,x+1,y+1,c)
 
 if attachment != nil then
  -- save old palette
  memcpy(0x4300,0x5f00,16)
  pal()
  spr(attachment,attch_x,attch_y,1,1,self._flip_x,self._flip_y)
  -- restore it
  memcpy(0x5f00,0x4300,16)
 end
end

function moko:_draw_head(dx,dy)
 if (self._flip_x) dx=-7-dx
 if (self._flip_y) dy=-7-dy
 spr(self.head,
  self._x+dx,
  self._y+dy,
  1,1,
  self._flip_x,self._flip_y
 )
end

function wobb1(x)
 local x=x%1
 if x<0.5 then
  return 0
 else
  return 1
 end
end

function _wobcos(x)
 local x=x%1
 if x<0.25 then
  return -1
 elseif x<0.5 then
  return 0
 elseif x<0.75 then
  return 1
 else
 	return 0
 end
end

function _wobsin(x)
 return _wobcos(x+0.25)
end
-->8
microgame={}

function microgame:init()
 microgame.player={
  x=64,
  y=50,
  xsp=0,
  ysp=0,
  flip_x=false,
  kobold=moko:new(4,{1,0,10})
 }
end

function microgame:update()
  -- control 
 self.player.flying=self.player.y<50
 self.player.crouch_mode=not self.player.flying and btn(⬇️)
 
 local speed=1
 if self.player.crouch_mode then
  speed=0.4
 end
 
 if self.player.flying then
  speed *= 0.25
 end

 if btn(⬆️) then
  if self.player.y==50 then
   self.player.kobold:play("jump",1/8.0,function() 
    self.player.ysp=-4
    self.player.y-=4
   end)   
  elseif self.player.y>25 and self.player.ysp <= 0 then
   self.player.ysp=-4
  end
 end
 
 if btn(⬅️) then
  self.player.xsp-=speed
 end
 
 if btn(➡️) then
  self.player.xsp+=speed
 end
  
 -- action 
 self.player.x+=self.player.xsp
 self.player.y+=self.player.ysp
 
 self.player.ysp+=1
 if not self.player.flying then
  if self.player.crouch_mode then
   self.player.xsp*=0.4
  else
   self.player.xsp*=0.7
  end
 end
 
 if abs(self.player.xsp)<0.1 then
  self.player.xsp=0
 end
 
 --  reaction
 if self.player.x<3 then
  self.player.x=3
  self.player.xsp=0
 end
 
 if self.player.x>125 then
  self.player.x=125
  self.player.xsp=0
 end 

 if self.player.y>50 then
  self.player.y=50
  self.player.ysp=0
 end
 
 -- animation system feedback
 self.player.kobold:update()
 if self.player.flying then
  self.player.kobold:loop("run",2/16.0)
 else
  local flip_x
  if self.player.xsp<0 then
   flip_x=true
  end
  if self.player.xsp>0 then
   flip_x=false
  end
  if flip_x!=nil then
   self.player.flip_x=flip_x
  end
  
  local run_anim="run"
  local idle_anim="idle"
  local thresh=0.3
  if self.player.crouch_mode then
   run_anim="crawl"
   idle_anim="crouch"
   thresh=0.0
  end
  
  if abs(self.player.xsp)>thresh then
   self.player.kobold:loop(run_anim,1/16,true)
  else
   self.player.kobold:loop(idle_anim,1/16,true)
  end
 end
end

function microgame:draw()
 clip(0,0,128,55)
 rectfill(0,0,128,53,2)
 line(0,54,128,54,1)
 circfill(30,10,16,15)
 
 pal(15,7)
 self.player.kobold:draw(
  self.player.x,
  self.player.y,
  self.player.flip_x
 )
end
__gfx__
00070000000000700000800000000000706000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07060700077067080000600000000000776600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700067777000077770000777000777660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0078780000787800007868000078766077776d700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777770007777e0007777000077766607787d700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007770000077700000000000000000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0555b5b5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
