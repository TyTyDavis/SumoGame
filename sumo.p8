pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
--sumo game
--[[
todo:
something is wrong with deepcopy
its messing up references to things
]]--

function _init()
	palt(0,false)
	palt(11,true)
	--pal(12,14,1)
	--pal(13,8,1)
	state="play"
	winner=" "
	blinkframe=0
	camx=2
	camy=0
	camt=0
	
	reset_timer=0
	--set btnp repeat to never
	poke(0x5f5c, 255)
	poke(0x5f5d, 255)
end


function _update()
	if state=="play" then
		p1:update()
		p2:update()
		if winner!=" " then
			state="reset"
			reset_timer=0
		end
		elseif state=="match_start" then
		p1.x=40
		p2.x=110
		p1:reset_wrestler()
		p2:reset_wrestler()
		state="play"
		winner=" "
	elseif state=="menu" or "reset" then
		if state=="menu" or reset_timer>60 then
			if btn(❎) then
				state="match_start"
			end
		end
		reset_timer+=1
	end
end


function _draw()
	update_camera()
	camera(camx,camy)
	cls(1)
	draw_bg()
	--print(state,100,113,7)
	if state=="menu" then
		draw_menu()
	elseif state=="reset" then
		draw_wrestlers()
		draw_reset()
	elseif state=="play" then
		draw_wrestlers()
		p1out=false
		p2out=false
		if p2.x>=163 then p2out=true end
		if p1.x<=-12 then p1out=true end
		--draw_debug()
		draw_percent()
		--print(p1.gstate,camx+27,camy+20,7)
		--print(tostr(at_ledge(1)),camx+84,camy+20,7)
	end
end
-->8
--rikishi
block_stun=10
dash=50
grab_dash=25
dash_cool=25
gcount=1000
--gcount=75 --length of grapple
g_cool=60 --grab cooldown
gdist=40 --grab distance
--% added to prc when pushing
grapple_push=30
p1={
	p=0,
	x = 40, --body center
	y=71, --body center
	shake=0,
	
	recover=false,
	block=false,
	
	canact=true,
	canblock=true,
	
	dx=0,
	mx=0,
	move=0,
	knockback=0,
	
	r=0, --whole body rotation
	br=0, --torso
	oar=0, --outer arm
	iar=0, --inner arm
	
	prc=0,
	prc_target=0,
	
	f=false, --sprite flip
	p2oao=0,
	p2olo=0,
	p2iao=0,
	p2ilo=0,
	bodymapx=0,
	bodymapy=0,
	iarmhitxy={0,0},
	oarmhitxy={0,0},
	bodycollide=false,
	ibuff=false,
	obuff=false,
	ocount=0,
	icount=0,
	islap="ready",
	oslap="ready",
	iag=false,
	oag=false,
	grapple=false,
	gcount=0,
	stun=0,
	lastb={},
	dash_cool=0,
	gstate="ready",
	pummel=false,
	update=function(self)
		--collission
		self:handle_colission()
		
		if self.islap=="ready" 
					and self.oslap=="ready" 
					and self.iar>-0.03
					and self.oar>-0.03
		then
			if self.gstate!="grapple" 
			and self.gstate!="grappled" then
				self.canblock=true
			end
		else
			self.canblock=false
		end
		
		self:handle_block()
		
		if self.recover or self.block or self.knockback>0 then
			self.canact=false
			self.dx=0
		elseif self.stun>0 then
			self.stun-=1
			self.canact=false
		else
			self.canact=true
		end
		
		self:handle_move_input()
		
		self:handle_grab()
		
		self:handle_slaps()
	
		self:lower_arms()
	
		self:handle_movement()
	
		self:handle_knockback()
		
		self:handle_topple()
	end,
	
	handle_grab=function(self)
		local grapple_space=38
		if self.canact then
			if btnp(❎,self.p) 
			and btnp(🅾️,self.p) 
			and self.gstate=="ready"
			then
				self.gstate="grab"
				if self.p==0 then
					self.dx=grab_dash
				else
					self.dx=-grab_dash
				end
				self.canact=false
			end
		end
		if self.gstate=="grab" then
			self.canact=false
			self.canmove=false
			if self.oar>-0.10 then
				self.oar-=0.05
			end
			if self.iar>-0.19 then
				self.iar-=0.05
			end
			if abs(self.x-other(self.p).x)<=gdist then
				self.dx=0
				self.gstate="grapple"
				self.gcount=gcount
				other(self.p).gstate="grappled"
			end
			if abs(self.dx)<1 and self.gstate=="grab" then
				self.gstate="not ready"
				self.gcool=g_cool
			end
		elseif self.gstate=="not ready" then
			self.gcool-=1
			if self.gcount<=0 then
				self.gstate="ready"
				self.canact=true
				self.canmove=true
			end
		elseif self.gstate=="grappled" then
			self.canact=false
			self.canmove=false
			self.canblock=false
			if btnp(❎,self.p) 
			or btnp(🅾️,self.p)
			or btnp(⬅️,self.p)
			or btnp(➡️,self.p) then
				other(self.p).gcount-=flr(rnd(3))
			end
			if abs(self.x-other(self.p).x)>grapple_space then
				if self.p==0 then 
					self.x+=2 
				else
					self.x-=2
				end
			else
				if self.p==0 then
					self.x=other(self.p).x-grapple_space
				else
					self.x=other(self.p).x+grapple_space
				end
			end
		elseif self.gstate=="grapple" then
				-- self.r+=0.01*(self.knockback/100)
				self.gcount-=1
				self.dx=self.dx*((other(self.p).prc+grapple_push)/100)
				if self.gcount<gcount-10 and (btnp(❎,self.p) or btnp(🅾️,self.p)) then
					self.pummel=true
					self.gcount-=5
					sfx(rnd({61,63}))
					other(self.p).prc+=10
					other(self.p).shake+=2
				end
				--★
				if at_ledge(other(self.p).p) then
					local pushing=true
					if self.p==0 and self.dx>0 then pushing=true end
					if self.p==1 and self.dx<0 then pushing=true end
					if pushing then
						local direction=-1
						if self.p==1 then direction=1 end
						other(self.p).r+=direction*(0.01*other(self.p).prc/100)
						
					else
						local other = other(self.p)
						if other.r<0 then other.r+=0.01 end
						if other.r>0 then other.r-=0.01 end
						if abs(other.r)<=0.04 then other.r=0 end
					end
				end
				
				if self.pummel then
					if self.oar>-0.20 then
						self.oar-=0.05
					else
						self.pummel=false
					end
				else
					if self.oar<-0.12 then self.oar+=0.01 end
				end
				if self.iar>-0.16 then
					self.iar-=0.03
				end
				if self.oar>-0.10 then
					self.oar-=0.01
				end
				if self.gcount<=0 then
					self.gcool=g_cool
					self.gstate="not ready"
					other(self.p).gstate="not ready"
					other(self.p).gcool=g_cool
					self.knockback=250
				end
		end
	end,
	
	handle_knockback=function(self)
		if self.knockback>10 then
			self.br=-0.02
		else
			self.br=0
		end
		if self.p==0 then
			if self.x-self.knockback/20>-10 then
				self.x-=self.knockback/20
			else
				if self.r<0.08 then self.r+=0.01*(self.knockback/100) end
			end
		else
			if self.x+self.knockback/20<162 then
				self.x+=self.knockback/20
			else
				if self.r>-0.08 then self.r-=0.01*(self.knockback/100) end
			end
		end
	
		self.knockback=self.knockback*.6
	
		if self.knockback<0.05 then
			self.knockback=0
		end
		if self.knockback<=0 and self.gstate!="grappled" then
			if self.r<0 then self.r+=0.01 end
			if self.r>0 then self.r-=0.01 end
			if abs(self.r)<=0.04 then self.r=0 end
		end
	end,
	
	handle_movement=function(self)
		if not self.bodycollide 
		or (self.gstate=="grapple" 
					and not at_ledge(other(self.p).p)) then
			if self.knockback==0 then
				self.x+=self.dx/5
			end
		elseif self.bodycollide and self.gstate!="grappled" and self.gstate!="grapple" and (is_retreat(self) or self.knockback>0) then
			self.x+=self.dx/5
		end
	
		self.dx=self.dx*0.5
		if abs(self.dx)<=0.49 then 
			self.dx=0 
		end
	end,
	
	handle_slaps=function(self)
		if self.canact then
			if btnp(🅾️,self.p) 
			and self.gstate=="ready" then
				self.icount+=1
				if self.islap=="ready" then
					self.islap="slap"
				end
			end
		end
		if self.canact then
			if btnp(❎,self.p)
			and self.gstate=="ready" then
				self.ocount+=1
				if self.oslap=="ready" then
					self.oslap="slap"
				end
			end
		end
		if self.oslap=="slap" then
				if self.oar>-0.19 then
					self.oar-=0.1
					if arm_hit(self.p, self.oarmhitxy[1],self.oarmhitxy[2]) then
						if not other(self.p).block then
							sfx(rnd({61,63}))
							other(self.p).prc_target+=flr(10*(self.oar/-0.19))
						else
							self.stun+=block_stun
							self.shake+=1
						end
						other(self.p).shake+=abs(self.oar)*5
						other(self.p).knockback+=(abs(self.oar)*300)*(other(self.p).prc/100)
						self.ocount=0
						self.oslap="not ready"
					end
				else
					self.oslap="not ready"
					self.ocount=0
				end
		end
		if self.oar>0 then 
					self.ocount=0
					self.oslap="ready"
		end
				
		if self.islap=="slap" then
			if self.iar>-0.19 then
				self.iar-=0.1
				if arm_hit(self.p, self.iarmhitxy[1],self.iarmhitxy[2]) then
					if not other(self.p).block then
						sfx(rnd({61,63}))
						other(self.p).prc_target+=flr(10*(self.iar/-0.19))
					else
						self.stun+=block_stun
						self.shake+=1
					end
					other(self.p).shake+=abs(self.iar)*5
					other(self.p).knockback+=(abs(self.iar)*300)*(other(self.p).prc/100)
					self.icount=0
					self.islap="not ready"
				end
			else
				self.islap="not ready"
				self.icount=0
			end
		end
		
		if self.iar>0 then 
			self.icount=0
			self.islap="ready"
		end
	end,
	
	lower_arms=function(self)
		if (not btn(🅾️,self.p) 
		or self.islap=="not ready"
		or self.gstate=="not ready")
		and self.gstate!="grab" 
		and self.gstate!="grapple"
		and self.gstate!="grappled"
		and self.iar<0 
		and self.stun<=0  then
			self.iar+=0.02
		end
		if (not btn(❎,self.p) 
		or self.oslap=="not ready" 
		or self.gstate=="not ready") 
		and self.gstate!="grab"
		and self.gstate!="grapple"
		and self.gstate!="grappled"
		and (self.oar<0 
		and self.stun<=0)  then
			self.oar+=0.02
		end
	end,
	
	handle_colission=function(self)
		if self.p==0 then
			local iax, iay=point_on_circle(self.x, self.y, 10, .12 - self.br)
			local oax, oay= point_on_circle(self.x, self.y, 7,.39 - self.br)
			a = b
			self.oarmhitxy[1],self.oarmhitxy[2]=point_on_circle(oax, oay, 28,.78-self.oar)
			self.iarmhitxy[1],self.iarmhitxy[2]=point_on_circle(iax, iay, 17,.82-self.iar)
		elseif self.f then
			local iax, iay=point_on_circle(self.x-37, self.y, 10, .12 - self.br)
			local oax, oay=point_on_circle(self.x-10, self.y, 7,.39 - self.br)

			self.oarmhitxy[1],self.oarmhitxy[2]=point_on_circle(oax, oay, 24,.72+self.oar)
			self.iarmhitxy[1],self.iarmhitxy[2]=point_on_circle(iax, iay, 17,.68+self.iar)
		end
		if oval_collide() then
			self.bodycollide = true
		else
			self.bodycollide = false
		end
	end,
	
	handle_move_input=function(self)
		if self.canact then
			if btnp(➡️,self.p) then
					if self.lastb[1]=="➡️" 
					and self.dash_cool==0 
					and time()-self.lastb[2]<=0.2
					and time()-self.lastb[2]>0.1 then
						self.dx=dash
						self.dash_cool=dash_cool
					end
					self.lastb={"➡️",time()}
			elseif btnp(⬅️,self.p) then
				if self.lastb[1]=="⬅️" 
					and self.dash_cool==0
					and time()-self.lastb[2]<=0.2
					and time()-self.lastb[2]>0.1 then
						self.dx=-dash
						self.dash_cool=dash_cool
					end
					self.lastb={"⬅️",time()}
			end
			if self.dash_cool>0 then self.dash_cool-=1 end
			if btn(➡️, self.p) then
				if self.dx==0 then self.dx=3 end
				self.move+=1
			elseif btn(⬅️, self.p) then
				if self.dx==0 then self.dx=-3 end
				self.move+=1
				--self.r+=.005
			else
				self.move=0
			end
		end
		
		if self.move==20 then self.move = 0 end
	end,
	handle_block=function(self)
		if btn(⬆️, self.p) and self.canblock then
			self.block=true
			if self.br>=-0.024 then
				self.br-=.011
			end
		end
		
		if not btn(⬆️,self.p) then
			self.block=false
			if self.br<0 then
				self.br+=.009
			end
		end
	end,
	handle_topple=function(self)
		if self.p==0 then
			if self.r>0.08 and self.r<0.20 then
				self.r+=0.02
			elseif self.r>0.20 then
				winner="p1"
			end
		else
			if self.r<-0.08 and self.r>-0.20 then
				self.r-=0.02
			elseif self.r<-0.20 then
				winner="p2"
			end
		end
	end,
	reset_wrestler=function(self)
		self.lastb={0,0}
		self.knockback=0
		self.dx=0
		self.dash_cool=0
		self.r=0
		self.prc=0
		self.prc_target=0
		self.iar=0
		self.oar=0
		self.br=0
		self.gstate="ready"
	end
}

function deepcopy(orig)
 local copy = {}
 for orig_key, orig_value in pairs(orig) do
  copy[orig_key] = orig_value
 end
 return copy
end	

function other(p)
	if p==0 then
		return p2
	else
		return p1
	end
end

function at_ledge(p)
	if p==0 then
		if p1.x<-11 then return true end
	elseif p==1 then
		if p2.x>162 then return true end
	end
	return false
--	if p==0 and p1.x<=-9 then
--		return true
--	end
--	if p==1 and p2.x>=150 then
--		return true
--	end
--	return false
end

function arm_hit(p, x, y)
	otherp=other(p)
	if p==0 then
		return in_oval(otherp.x-24,otherp.y,8,30,x,y)
	else
		return in_oval(otherp.x,otherp.y,8,30,x,y)
	end
end

function is_retreat(p)
	if p.p==0 and p.dx<0 then
		return true
	end
	if p.p==1 and p.dx>0 then
		return true
	end
	return false
end

p2 = deepcopy(p1)

p2.x=110
p2.p=1
p2.f=true
p2.p2oao=-11
p2.p2iao=-35
p2.p2ilo=-38
p2.bodymapx=24
p2.bodymapy=5
p2.iarmhitxy={0,0}
p2.oarmhitxy={0,0}
p2.grapple=false
p2.shake=0
p2.gstate="ready"

-->8
--helpers
--[[
circle
				0.25
0.5					0.0
				0.75
]]--

--rotation
--97 tokens with scaling and arbitrary size
--credit theroboz
function pd_rotate(x,y,rot,mx,my,w,f,scale)
  scale=scale or 1
  w*=scale*4

  local cs, ss = cos(rot)*.125/scale,sin(rot)*.125/scale
  local sx, sy = mx+cs*-w, my+ss*-w
  hx=w
  if f then
  	hx = -w
  end
	
  local halfw = -w
  for py=y-w, y+w do
    tline(x-hx, py, x+hx, py, sx-ss*halfw, sy+cs*halfw, cs, ss)
    halfw+=1
  end
end


function point_on_circle(center_x, center_y, radius, angle)
  --local angle_radians = angle_percentage * 2 * 3.14159  -- convert to radians
  local x = center_x + radius * cos(angle)
  local y = center_y + radius * sin(angle)
  return x, y
end

function in_circle(x, y, circle_x, circle_y, radius)
	circle_x=circle_x or circx
	circle_y=circle_y or circy
	radius=radius or circr
	distance = sqrt((x - circle_x)^2 + (y - circle_y)^2)
 return distance <= radius
end

function in_oval(cx,cy,rx,ry,x,y)
 local dx = (x - cx) / rx
 local dy = (y - cy) / ry
 return dx * dx + dy * dy <= 1
end

function oval_collide()
 local cx2 = p2.x-24
 local cy2 = p2.y
 local rx = 8
 local ry = 30
 local cx1 = p1.x
 local cy1 = p1.y
 local dx = cx2 - cx1
 local dy = cy2 - cy1

 local combined_rx = rx*2
 local combined_ry = ry*2

 local scaled_dx = dx / combined_rx
 local scaled_dy = dy / combined_ry
 return scaled_dx * scaled_dx + scaled_dy * scaled_dy <= 1
end
-->8
--bg/ui
function draw_bg()
	rectfill(-100,75,128+100,128,4)
	oval(3-40,80,124+40,115,7)
	line(50,90,50,97)
	line(77,90,77,97)
end

function draw_percent()
	local p1xo=0
	local p1yo=0
	if p1.prc_target>0 then
		p1.prc+=1
		p1.prc_target-=1
		p1xo=1-rnd(2)
		p1yo=1-rnd(2)
	end
	
	local p2xo=0
	local p2yo=0
	if p2.prc_target>0 then
		p2.prc+=1
		p2.prc_target-=1
		p2xo=1-rnd(2)
		p2yo=1-rnd(2)
	end
	print("\^t\^w"..p2.prc.."\^-t\^w%", camx+84+p2xo,camy+7+p2yo,7)
	print("\^t\^w"..p1.prc.."\^-t\^w%", camx+27+p1xo,camy+7+p1yo,7)
end

function draw_menu()
	cprint("press ❎ to start",50)
end

function draw_reset()
	cprint(winner.." wins!", 50)
	if reset_timer>60 then
		cprint("press ❎ to rematch", 60)
	end
end

function cprint(s,y,c)
	local c = c or 7
	local x = camx+64-#s*2
	print(s,x,y,7)
end

function update_camera()
	local p1c=p1.x-1
	local p2c=p2.x-21
	camx=((p1c+p2c)/2)-62
end

function draw_debug()
	bcx=p1.x
	bcy=p1.y
	--circ(p1.x,p1.y,10,8)
	--pset(p1.x,p1.y,8)
	
	local iax, iay = point_on_circle(p1.x, p1.y, 10, .12 - p1.br)
	local oax, oay = point_on_circle(p1.x, p1.y, 7,.39 - p1.br)
	--pset(iax,iay,14)
	--pset(oax,oay,14)
	--circ(oax,oay,19,10)
	--pset(oax,oay,10)
	--outer arm collide point
	local ohx, ohy = point_on_circle(oax, oay, 24,.78-p1.oar)
	local ihx, ihy = point_on_circle(iax, iay, 17,.82-p1.iar)
	
	--pset(ohx,ohy,0)
	--circ(iax,iay,19,10)
	
	--pset(ihx,ihy,0)
	
	local iax2, iay2 = point_on_circle(p2.x-37, p2.y, 10, .12 - p2.br)
	local oax2, oay2 = point_on_circle(p2.x-10, p2.y, 7,.39 - p2.br)
	--pset(iax2,iay2,14)
	--pset(oax2,oay2,14)
	--circ(oax2,oay2,24,10)
	--pset(oax2,oay2,10)
	local ohx2, ohy2 = point_on_circle(oax2, oay2, 24,.72+p2.oar)
	local ihx2, ihy2 = point_on_circle(iax2, iay2, 17,.68+p2.iar)
	--pset(ohx2,ohy2,0)
	--circ(iax2,iay2,17,10)
	--pset(ihx2,ihy2,0)
	p1icolor=0
	p1ocolor=0
	if in_oval(p2.x-24,p2.y,10,30,p1.iarmhitxy[1],p1.iarmhitxy[2]) then
		p1icolor=10
	end
	if in_oval(p2.x-24,p2.y,10,30,p1.oarmhitxy[1],p1.oarmhitxy[2]) then
		p1ocolor=10
	end
	pset(p1.iarmhitxy[1],p1.iarmhitxy[2],p1icolor)
	pset(p1.oarmhitxy[1],p1.oarmhitxy[2],p1ocolor)
	pset(p2.iarmhitxy[1],p2.iarmhitxy[2],0)
	pset(p2.oarmhitxy[1],p2.oarmhitxy[2],0)

	--body colliders
	oval_col=9
	if p1.bodycollide then oval_col=7 end
	oval(p1.x-10,p1.y-15,p1.x+11,p1.y+16,oval_col)
	oval(p2.x-34,p2.y-15,p2.x-13,p2.y+16,oval_col)
	pset(p1.x, p2.y,9)
	pset(p2.x-24,p2.y,9)
end


-->8
--draw wrestlers
function calculate_legs(p)
	if p.move>10 then
		ol=2
		il=0
	elseif p.move~=0 then
		ol=0
		il=2
	else
		ol = 0
		il = 0
	end
	return ol,il
end


function draw_wrestlers()
	p1x=flr(p1.x)
	p2x=flr(p2.x)
	local p1xshake=1-rnd(2)
	local p1yshake=1-rnd(2)
	p1xshake=p1xshake*p1.shake
	p1yshake=p1yshake*p1.shake
	
	local p2xshake=1-rnd(2)
	local p2yshake=1-rnd(2)
	p2xshake=p2xshake*p2.shake
	p2yshake=p2yshake*p2.shake
	
	local p1cx=p1x-1
	local p1cy=p1.y+25
	local p2cx=p2x-21
	local p2cy=p2.y+25
	
	local p1ol, p1il=calculate_legs(p1)
	local p2ol, p2il=calculate_legs(p2)

	local p2fl=-1
	local p2xo=p2x-18+(p2.br*160)
	local p2yo=p2.y+14
 


	local	p1fl=1
	local	p1xo=p1x-11+(p1.br*160)
	local	p1yo=p1.y-19


--p1 inner
	camera(camx, camy+p1yshake)
	pal(8,13,0)
	--leg
	local p1ilx,p1ily = point_on_circle(p1cx, p1cy, 20, .23+p1.r)
	pd_rotate(p1ilx+p1il,p1ily,0-p1.r,7,6,5)
	local p1iax, p1iay = point_on_circle(p1cx, p1cy, 33, .21 - (p1.br/2)+p1.r)
	--arm
	pd_rotate(p1iax-1,p1iay,p1.iar-p1.r,32,3,5,p1.f)
	--body

	camera(camx, camy)
	pal(12,12,0)
	

--p2 inner
	camera(camx, camy+p2yshake)
	pal(8,8,0)
	pal(14,14,0)
	local p2ilx,p2ily = point_on_circle(p2cx, p2cy, 20, .27+p2.r)
	pd_rotate(p2ilx+p2il,p2ily,0+p2.r,7,6,5,true)
	local p2iax, p2iay = point_on_circle(p2cx, p2cy, 32.1, .29 + (p2.br/2)+p2.r)
	pd_rotate(p2iax,p2iay,p2.iar+p2.r,32,3,6.5,p2.f)

	local p2bx, p2by = point_on_circle(p2cx-(p2.br/160),p2cy,12,.20+p2.r)
	pd_rotate(p2bx,p2by,p2.br+p2.r,p2.bodymapx,p2.bodymapy,7.8,p2.f)
	pal(14,14,0)
--p2 outer
		local p1bx, p1by = point_on_circle(p1cx+(p1.br*160),p1cy,45,.285+p1.r)
	pd_rotate(p1bx,p1by,p1.br-p1.r,p1.bodymapx,p1.bodymapy,7.8,p1.f)
	local p2olx,p2oly = point_on_circle(p2cx, p2cy, 27, .11+p2.r)
	pd_rotate(p2olx+p2ol, p2oly,0+p2.r,15,6,7, true)
	local p2oax, p2oay = point_on_circle(p2cx, p2cy, 36,.22 + (p2.br/2)+p2.r)
	pd_rotate(p2oax,p2oay,p2.oar+p2.r,33,12,6.5,p2.f)
	camera(camx, camy)
	
--p1 outer
	camera(camx, camy+p1yshake)
	pal(8,13,0)
	pal(14,140,0)
	local p1olx,p1oly = point_on_circle(p1cx, p1cy, 27, .385+p1.r)
	pd_rotate(p1olx+p1ol, p1oly,0-p1.r,15,6,7)
	local p1oax, p1oay = point_on_circle(p1cx, p1cy, 32,.29 - (p1.br/2)+p1.r)
	pd_rotate(p1oax+p1.p2oao,p1oay-4,p1.oar-p1.r,33,12,6.5,p1.f)
	pal(13,140,1)
	camera(camx, camy)
	
	p1.shake=p1.shake*0.5
	if p1.shake<0.05 then
		p1.shake=0
	end
	
	p2.shake=p2.shake*0.5
	if p2.shake<0.05 then
		p2.shake=0
	end
end
__gfx__
00000000beeebbbbbbbbbbbbbbbbbbbbbeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888bbbbbb8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000eeeeebbbbbbbbbbbbbbbbbbbeeeeeeeeebbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbb888888bbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00700700eeeeeebbbbbbbbbbbbbbbbbeeeeeeeeeeebbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbb8888888bbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00077000eeeeeeebbbbbbbbbbbbbbbeeeeeeeeeeeeebbbbbbbbbbbbbbb0000000bbbbbbbbbbb888888888bbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00077000eeeeeeeebbbbbbbbbbbbbeeeeeeeeeeeeeeeebbbbbbbbbbbbb00000000bbbbbbbbbb888888888bbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00700700beeeeeeeebbbbbbbbbbbbeeeeeeeeeeeeeeeebbbbbbbbbbbb000000000bbbbbbbbbb888888888bbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000beeeeeeeebbbbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbbb00000cc0bbbbbbbbbb8888888888bbb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbeeeeeeebbbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbbbcc00cccccbbbbbbbbb8888888888bbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeeeeebbbbbbbbbbbeeeeeeeeeeeeeebbbbbbbbbbbbccccc0cccccbbbbbbbbb888888888bbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeeeeebbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbccccccccccccbbbbbbbbb888888888bbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeeeebbbbbbbbbbbeeeeeeeeeeeeebbbbbbbbbbbcccccccccccccccbbbbbbbb888888888bbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeeeebbbbbbbbbbbeeeeeeeeeeebbbbbbbbbbbbbcccccccccccccccbbbbbbb888888888bbbbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbeeeebbbbbbbbbbbeeeeeeeeeebbbbbbbbbbbbbbcccccccccccccccccbbbbbb888888888bbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbeeeebbbbbbbbbbbeeeeeeeeeebbbbbbbbbbbbbbccccccccccccccccccbbbb888888888bbbbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbeeeebbbbbbbbbbbeeeeeeeeeebbbbbbbbbbbbbcccccccccccccccccccbbbb888888888bbbbbbbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeeeebbbbbbbbbbeeeeeeeeebbbbbbbbbbbbbbcccccccccccccccccccbbbb888888888bbbbbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeeeeebbbbbbbbbeeeeeeeeebbbbbbbbbbbbbccccccccccccccccccccbbbbb88888888bbbbbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbeeeeeeebbbbbbbbbeeeeeeebbbbbbbbbbbbbbccccccccccccccccccccbbbbb88888888bbbbbbbbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbeeeeeebbbbbbbbbeeeeeeebbbbbbbbbbbbbbcccccccccccccccccccbbbbbb888888888bbbbbbbbbbbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbeeeebbbbbbbbbeeeeeebbbbbbbbbbbbbbbcccccccccccccccccccbbbbbbb8888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeebbbbbbbbbbbbbbbcccccccccccccccccccbbbbbbbb8888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeebbbbbbbbbbbbbbb00cccccccccccccccccbbbbbbbb8888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeeebbbbbbbbbbbbbbb000cccccccccccccccbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbeeeeeeeebbbbbbbbbbbbbbbb00000cccccccccccccbbbbbbbbbb88888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbeeeeeeebbbbbbbbbbbbbbbbb0000000cccccccccccbbbbbbbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbeeeeebbbbbbbbbbbbbbbbbbc00000000ccccccc00bbbbbbbbbbbb8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc00000000cccc000bbbbbbbbbbbbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccc0000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccc0000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccc000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccc00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccc00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbe00000000eeeeeee00bbbbbbbbbbbbbbb666888888888bb888888bbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbeee00000000eeee000bbbbbbbbbbbbbbbbb888888888bbb88888bbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbeeeee0000000000000bbbbbbbbbbbbbbbbb88888888bbbb8888bbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeee0000000000bbbbbbbbbbbbbbbbbb8888888bbbbb888bbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeee000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeee00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbeeeee00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb0000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbb000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbb00000ee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbee00eeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbeeeee0eeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbb00eeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbb000eeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbb00000eeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbbbbb0000000eeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888777777888eeeeee888eeeeee888eeeeee888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88778877788ee888ee88ee888ee88ee8e8ee88888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8777787778eeeee8ee8eeeee8ee8eee8e8ee88888e88888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8777787778eee888ee8eeee88ee8eee888ee8888eee8888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8777787778eee8eeee8eeeee8ee8eeeee8ee88888e88888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee8777888778eee888ee8eee888ee8eeeee8ee888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8777777778eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888
11d11d1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d11d1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d11d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd1d1d1ddd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116616661611166611111666116616611616116611661611161116661661166611111eee1ee11ee111111ee111ee1eee1111116616661611166611111666
1111161116111611161111111616161616161616161116161611161111611616161111111e1e1e1e1e1e11111e1e1e1e11e11111161116111611161111111161
1111166616611611166111111661161616161666161116161611161111611616166111111eee1e1e1e1e11111e1e1e1e11e11111166616611611166111111161
1111111616111611161111111616161616161116161116161611161111611616161111111e1e1e1e1e1e11111e1e1e1e11e11111111616111611161111111161
1111166116661666161111711666166116661666116616611666166616661666166611111e1e1e1e1eee11111e1e1ee111e11111166116661666161111711666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161611111111116616661611166611111661161611171ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
16161171177716111611161116111111161616161171111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
1161177711111666166116111661111116161161117111cc11111111111111111111111111111111111111111111111111111111111111111111111111111111
16161171177711161611161116111111161616161171111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
161611111111166116661666161111711666161617111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee111ee1eee11111166166616111666111116661166166116161166116616111611166616611666111111ee1eee11111166166616111666111116661666
11111e1e1e1e11e11111161116111611161111111616161616161616161116161611161111611616161111111e1e1e1e11111611161116111611111111611616
11111e1e1e1e11e11111166616611611166111111661161616161666161116161611161111611616166111111e1e1ee111111666166116111661111111611666
11111e1e1e1e11e11111111616111611161111111616161616161116161116161611161111611616161111111e1e1e1e11111116161116111611111111611616
11111e1e1ee111e11111166116661666161111711666166116661666116616611666166616661666166611111ee11e1e11111661166616661611117116661616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1666161116661111166116161117111111111cc111111eee1ee11ee11111116616661611166611111666111111111ccc1171111111ee1eee1111117111661666
16111611161111111616161611711777111111c111111e1e1e1e1e1e1111161116111611161111111616177717771c1c111711111e1e1e1e1111171116111611
166116111661111116161161171111111ccc11c111111eee1e1e1e1e1111166616611611166111111666111111111c1c111711111e1e1ee11111171116661661
16111611161111111616161611711777111111c111111e1e1e1e1e1e1111111616111611161111111611177717771c1c111711111e1e1e1e1111171111161611
1666166616111171166616161117111111111ccc11111e1e1e1e1eee1111166116661666161111711611111111111ccc117111111ee11e1e1111117116611666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d1111dd1d1d11111ddd11dd1d1d1ddd1dd111dd11111ddd1d1d1ddd1d1d11111111111111111111111111111111111111111111111111111111111111111111
1d111d1d1d1d11111ddd1d1d1d1d11d11d1d1d1111111d1d1d1d1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111
1d111d1d1d1d11111d1d1d1d1d1d11d11d1d1d1111111ddd1d1d1ddd1ddd11111111111111111111111111111111111111111111111111111111111111111111
1d111d1d1ddd11111d1d1d1d1ddd11d11d1d1d1d11111d1d1ddd1d1d111d11111111111111111111111111111111111111111111111111111111111111111111
1ddd1dd11ddd11111d1d1dd111d11ddd1d1d1ddd11111d1d1ddd1d1d1ddd11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161611111111116616661611166611111661161611171ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
111116161171177716111611161116111111161616161171111c1111111111111111111111111111111111111111111111111111111111111111111111111111
11111161177711111666166116111661111116161161117111cc1111111111111111111111111111111111111111111111111111111111111111111111111111
111116161171177711161611161116111111161616161171111c1111111111111111111111111111111111111111111111111111111111111111111111111111
1171161611111111166116661666161111711666161617111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11dd1d1d111111dd1ddd1d1d1ddd1ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d111d1d11111d1d11d11d1d1d111d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd1ddd11111d1d11d11ddd1dd11dd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111d1d1d11111d1d11d11d1d1d111d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1dd11d1d11111dd111d11d1d1ddd1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1111111666161611661616111116161666116616661166166611111ccc11111111111111111111111111111111111111111111111111111111111111111111
1e1111111616161616111616111116161611161111611616161617771c1c11111111111111111111111111111111111111111111111111111111111111111111
1e1111111666161616661666111116161661161111611616166111111c1c11111111111111111111111111111111111111111111111111111111111111111111
1e1111111611161611161616111116661611161111611616161617771c1c11111111111111111111111111111111111111111111111111111111111111111111
1eee11111611116616611616166611611666116611611661161611111ccc11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118888
11111ddd1d1d1ddd11dd11111d1d1ddd1d111d1111111d1d1ddd1d1d1ddd11111ddd11dd11111ddd1ddd11111ddd1ddd1d1d1ddd1ddd1ddd1ddd1ddd1dd18888
111111d11d1d11d11d1111111d1d11d11d111d1111111d1d1d1d1d1d1d11111111d11d1d11111d1d1d1111111d1d1d111d1d1d1d11d111d111d11d111d1d8888
111111d11ddd11d11ddd11111d1d11d11d111d1111111ddd1ddd1d1d1dd1111111d11d1d11111dd11dd111111dd11dd11d1d1dd111d111d111d11dd11d1d8888
111111d11d1d11d1111d11111ddd11d11d111d1111111d1d1d1d1ddd1d11111111d11d1d11111d1d1d1111111d1d1d111ddd1d1d11d111d111d11d111d1d8888
111111d11d1d1ddd1dd111111ddd1ddd1ddd1ddd11111d1d1d1d11d11ddd111111d11dd111111ddd1ddd11111d1d1ddd1ddd1d1d1ddd11d111d11ddd1d1d8888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16661171116616661611166611111666117111111666161611111171116616661611166611111661161617171171116616661611166611111166166616661666
16161711161116111611161111111616111711111666161617771711161116111611161111111616161611711711161116111611161111111611116116161666
16611711166616611611166111111666111711111616116111111711166616611611166111111616116117771711166616611611166111111666116116661616
16161711111616111611161111111611111711111616161617771711111616111611161111111616161611711711111616111611161111111116116116161616
16161171166116661666161111711611117111711616161611111171166116661666161111711666161617171171166116661666161111711661116116161616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116616661611166611111666161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711777161116111611161111111666161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17771111166616611611166111111616116111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711777111616111611161111111616161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111166116661666161111711616161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161611111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161617771c1c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
116111111c1c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161617771c1c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161611111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282288228888282228222822288888888888888888888888888888888888882228222828282228882822282288222822288866688
82888828828282888888888288288828882888828882828288888888888888888888888888888888888888828882828282828828828288288282888288888888
82888828828282288888822288288828882882228882822288888888888888888888888888888888888882228822822282828828822288288222822288822288
82888828828282888888828888288828882882888882828288888888888888888888888888888888888882888882888282828828828288288882828888888888
82228222828282228888822282228222828882228882822288888888888888888888888888888888888882228222888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__map__
0607080c0c0c0c0c0d0d0c0c0c0c0c0d0d0d0d0e746668686868666666665600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1617180c0c0c0c0c0d0d0c0c0c0c0c0d0d0d1d1e746650515253666666595600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2627280c0c0c0c0c0d0d0c0d0d0d0d0d0d0d2d2e746660616263666666595600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3637380c0c0c0c0c0d0d0d3c0c0c0c0c3b3c3d3e7466707172736666665956000b0c0d0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c340c0c0c0c0c0c0c1e1e1e06565656565656404142435656565956001b1c1d1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76767676340c0c0c0c0c0c0c1e1e1e1e565656565656565656565656565656002b2c2d2e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76767634340c0c01020c0c0c1e1e2503040506565656565656565656565656003b3c3d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76763434340c0c11120c0c0c1e34351314150d56565656565656565656560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76763434340c0c21220c0c0c0c0c0c2324250d56565656000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0076760000000000000000000000003334350d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000090a0d0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000191a0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000292a0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000393a3b3c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
140100000060213602000020060200600006000660004600156002060021600026002260023600246001750024600256002660026600286001d50000500000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
990100000f65100001000010f6510060100001000010f6512a6010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000100001465100001000010c65100001000010360103650000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
490100002c65100601006011b671146010d601006010b631006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
