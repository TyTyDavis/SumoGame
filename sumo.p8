pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
--oshidashi! sumo
--by tyler r. davis

function _init()
	palt(0,false)
	palt(11,true)
	--pal(12,14,1)
	--pal(13,8,1)
	pal(15,132,1)
	state="startup"
	winner=" "
	blinkframe=0
	camx=0
	camy=0
	camt=0
	-- camera smoothing settings
	cam_target_x=0
	cam_smooth=0.1  -- cower = smoother (0.1 = 10% movement per frame)
	cam_move_threshold=2  -- minimum change before camera moves
	
	cpup2=true
	p2out_x=163
	p1out_x=-12
	menu={"one player","two players"}
	reset_menu={"rematch","main menu"}
	menu_counter=1
	reset_menu_counter=1
	reset_timer=0
	menu_ready_timer=0
	--set btnp repeat to never
	poke(0x5f5c, 255)
	poke(0x5f5d, 255)
	
	dust_particles={}
	
	gyoji_r=110
	gyoji_l=69
	gyoji_offeset=0
	gyoji_parallax = 0.5
	audience_parallax = 0.15
	fader=9
	flag=false
	menu_arm_r=0
	menu_arm_state="pause" --or up or down
	menu_arm_count=0
	fade_timer=0
	countdown=90
	
	-- Initialize difficulty settings
	difficulty_level = 1 -- 1=easy, 2=normal, 3=hard, 4=expert
	difficulty_scaling = 1.0
	consecutive_losses = 0
	
	p1record={}
	p2record={}
	init_audience()
end


function _update()
	if state=="play" then
		if countdown>-30 and countdown<90 then
			countdown-=1
		else
			countdown=90
		end
		p1:update()
		p2:update()
		update_gyoji()
		update_particles()
		update_music()
		if cpup2 then
			update_cpu_pad()
			update_cpu_movement()
			update_cpu_arms()
		end
		if winner!=" " then
			state="reset"
			reset_timer=0
		end
		elseif state=="match_start" then
		p1.x=40
		p2.x=110
		p1:reset_wrestler()
		p2:reset_wrestler()
		winner=" "
		gyoji_r=110
		gyoji_l=69
		gyoji_offset=0
		audience_offset=0
		countdown-=1
		dust_particles={}
		fader=0
		pal(1)
		pal(15,132,1)
		
		-- Initialize CPU personality when match starts
		if cpup2 then
			init_cpu_personality()
		end
		if countdown==60 then music(1,0,4) end
		if countdown<=0 then
			state="play"
		end
	elseif state=="startup" then
		music(20)
		state="title_card"
	elseif state=="title_card" then
		fade_timer+=1
		if fade_timer>10 and fade_timer<90 then
			if fader>0 and fade_timer%2==0 then
				fader-=1
			end
		
		elseif fade_timer>90 then
			if fader<9 and fade_timer%2==0 then
				fader+=1
			end
			if fader==9 then
				state="main_menu1"
				fade_time=0
			end
		end
	elseif state=="main_menu" or state=="main_menu1" then
		update_particles(100)
		p1record={}
		p2record={}
		update_menu()
	elseif state=="menu" or "reset" then
		if state=="reset" and reset_timer==1 then
			-- Adjust difficulty based on match result when a match ends
			if cpup2 then
				adjust_difficulty()
			end
		elseif state=="reset" and reset_timer>50 then
			update_reset_menu()
		end
		
		if state=="menu" then
			update_menu()
		end
		reset_timer+=1
	end

end


function _draw()
	update_camera()
	camera(camx,camy)
	if state=="title_card" then
		cls(0)
	else
		cls(1)
	end
	--print(state,100,113,7)
	if state=="menu" then
		draw_menu()
	elseif state=="main_menu" or state=="main_menu1" then
		draw_main_menu()
		draw_particles()
	elseif state=="title_card" then
		cprint("a tyler r. davis game", 56, 7)
		cprint("music by cory shane davis", 65,7)
	elseif state=="reset" then
		draw_bg()
		draw_audience()
		draw_gyoji()
		draw_wrestlers()
		draw_reset()
		draw_wins()
	elseif state=="label" then
		draw_label()
	elseif state=="play" or state=="match_start" then
		draw_bg()
		draw_audience()
		draw_gyoji()
		draw_particles()
		draw_wrestlers()
		draw_countdown()
		
		p1out=false
		p2out=false
		if p2.x>=p2out_x then p2out=true end
		if p1.x<=p1out_x then p1out=true end
		--draw_debug()
		draw_percent()
		draw_wins()
		--print(reset_menu_counter,camx+27,camy+20,7)
		--print(p1.oar,camx+84,camy+20,7)
		--print("r: "..movement_strats["retreat"], camx+80, camy+27)
		--print("a: "..movement_strats["advance"], camx+80, camy+34)
		--print("f: "..movement_strats["footsies"], camx+80, camy+41)
		--print_cpu_strats()
		
	end
	if state=="title_card" or state=="main_menu" or state=="main_menu1" or state=="startup" then
		fade(fader)
	end

end
-->8
--rikishi
block_stun=25
slap_stun=5
hit_stun=6
dash=50
grab_dash=15
dash_cool=25
pummel_cool=10
--gcount=1000
gcount=160 --length of grapple
g_cool=25 --grab cooldown
gdist=43 --grab distance
max_g_speed=200 
grapple_push=50 --% added to prc when pushing

oslap_amt=600
islap_amt=500

block_recover=0.01
arm_recover=0.02
hit_recover=0.023

-- slap cooldown settings
max_slaps_before_cooldown = 6 -- max slaps before cooldown
slap_window_frames = 60 -- frames to count slaps within
slap_cooldown_frames = 20 -- cooldown duration in frames
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
	slap_timestamps = {}, -- stores timestamps of recent slaps
	slap_cooldown = 0, -- cooldown timer
	in_slap_cooldown = false, -- whether player is in cooldown
	iag=false,
	oag=false,
	grapple=false,
	gcount=0,
	stun=0,
	lastb={},
	dash_cool=0,
	gstate="ready",
	pummel=false,
	pummel_cool=0,
	update=function(self)
		--collission
		self.canblock=true
		self:handle_colission()
		
		if self.islap=="ready" 
					and self.oslap=="ready" 
					and self.iar>-0.03
					and self.oar>-0.03
		then
			if self.gstate!="grapple" 
			and self.gstate!="grappled" then
				self.block=true
			end
		else
			self.canblock=false
		end
		
		self:handle_block()
		
		if self.recover or self.block or self.knockback>5 then
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
			if button(5,self.p) 
			and button(4,self.p) 
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
				sfx(60)
			end
			if abs(self.dx)<1 and self.gstate=="grab" then
				self.gstate="not ready"
				self.gcool=g_cool
			end
		elseif self.gstate=="not ready" then
			self.gcool-=1
			if self.gcool<=0 then
				self.gstate="ready"
				self.canact=true
				self.canmove=true
			end
		elseif self.gstate=="grappled" then
			if self.iar<0.02 then self.iar+=0.02 end
			if self.oar<0.02 then self.oar+=0.02 end

			self.canact=false
			self.canmove=false
			self.canblock=false
			self.bodycollide=false
			self.br=0
			if buttonp(5,self.p) 
			or buttonp(4,self.p)
			or buttonp(0,self.p)
			or buttonp(1,self.p) then
				other(self.p).gcount-=flr(rnd(3))
				if self.br==0 then
					self.br+=0.02
				elseif self.br>0 then
					self.br-=0.02
				elseif self.br<0 then
					self.br+=0.02
				end
			end
			if abs(self.x-other(self.p).x)>grapple_space+1 then
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
				local grap_speed=min((other(self.p).prc+grapple_push), max_g_speed)
				self.dx=self.dx*(grap_speed/100)
				if self.gcount<gcount-10 and self.pummel_cool<=0 and (buttonp(5,self.p) or buttonp(4,self.p)) then
					self.pummel=true 
					self.gcount-=5
					self.pummel_cool=pummel_cool
					sfx(rnd({61,63}))
					other(self.p).prc+=10
					other(self.p).shake+=2
				end
				if self.pummel_cool>0 then
					self.pummel_cool-=1
				end
				if at_ledge(other(self.p).p) then
					local pushing=false
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
					other(self.p).br=0
					other(self.p).iar=0
					other(self.p).oar=0
					self.knockback=250
				end
		end
	end,
	
	handle_knockback=function(self)
		if self.knockback>10 then
			self.br=-0.02
		elseif self.block==false then
			self.br=0
		end
		if self.p==0 then
			if self.x-self.knockback/20>-10 then
				self.x-=self.knockback/20
			else
				if self.r<0.08 then self.r+=0.01*(self.knockback/100)*(self.prc/100) end
			end
		else
			if self.x+self.knockback/20<162 then
				self.x+=self.knockback/20
			else
				if self.r>-0.08 then self.r-=0.01*(self.knockback/100)*(self.prc/100) end
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
		-- Allow moving away from edge even past the boundary or when recovering
		-- Player 1: Allow moving right (away from edge) even if past boundary
		if (self.p==0 and self.dx>0 and self.x<-5) then
			self.x+=self.dx/5
		-- Player 2: Allow moving left (away from edge) even if past boundary
		elseif (self.p==1 and self.dx<0 and self.x>155) then
			self.x+=self.dx/5
		-- Allow moving away from edge when recovering from rotation
		elseif (self.p==0 and self.r>0 and self.r<0.20 and self.dx>0) then
			-- Player 1 moving right (away from left edge)
			self.x+=self.dx/5
		elseif (self.p==1 and self.r<0 and self.r>-0.20 and self.dx<0) then
			-- Player 2 moving left (away from right edge)
			self.x+=self.dx/5
		elseif not self.bodycollide 
		or (self.gstate=="grapple" 
					and not at_ledge(other(self.p).p)) then
			if self.knockback==0 then
				if (self.p==0 and self.x+self.dx/5>-11) or
				(self.p==1 and self.x+self.dx/5<161) then
					self.x+=self.dx/5
				end
			end
		elseif self.bodycollide and self.gstate!="grappled" and (is_retreat(self) or self.knockback>0) then
			self.x+=self.dx/5
		end
	
		self.dx=self.dx*0.5
		if abs(self.dx)<=0.49 then 
			self.dx=0 
		end
	end,
	
	handle_slaps=function(self)
		-- Update slap cooldown if active
		if self.slap_cooldown > 0 then
			if self.iar<0 then self.islap="hit recover" end
			if self.oar<0 then self.oslap="hit recover" end
			self.slap_cooldown -= 1
			if self.slap_cooldown <= 0 then
				self.in_slap_cooldown = false
				-- Clear slap history when cooldown ends
				self.slap_timestamps = {}
			end
		end
		
		-- Check if player is in cooldown
		if self.in_slap_cooldown then
			-- Can't slap during cooldown
			return
		end
		
		-- Remove old slap timestamps
		local current_time = time()
		local window_time = slap_window_frames / 30 -- convert frames to seconds
		for i = #self.slap_timestamps, 1, -1 do
			if current_time - self.slap_timestamps[i] > window_time then
				deli(self.slap_timestamps, i)
			end
		end
		
		-- Check if player has tried to slap
		local tried_to_slap = false
		
		if self.canact then
			if buttonp(4,self.p) 
			and self.gstate=="ready" then
				self.icount+=1
				if self.islap=="ready" then
					self.islap="slap"
					add(self.slap_timestamps, time())
					tried_to_slap = true
				end
			end
		end
		
		if self.canact then
			if buttonp(5,self.p)
			and self.gstate=="ready" then
				self.ocount+=1
				if self.oslap=="ready" then
					self.oslap="slap"
					add(self.slap_timestamps, time())
					tried_to_slap = true
				end
			end
		end
		
		if tried_to_slap and #self.slap_timestamps >= max_slaps_before_cooldown then
			self.in_slap_cooldown = true
			self.slap_cooldown = slap_cooldown_frames
		end
		if self.oslap=="slap" then
				if self.oar>-0.18 then
					self.oar-=0.17
					if arm_hit(self.p, self.oarmhitxy[1],self.oarmhitxy[2]) then
						if not other(self.p).block then
							sfx(rnd({61,63}))
							other(self.p).prc_target+=flr(13*(self.oar/-0.25))
							self.stun=slap_stun
							self.oslap="hit recover"
						else
							sfx(59)
							self.stun=block_stun
							self.shake+=1
							self.oslap="block recover"
						end
						other(self.p).shake+=abs(self.oar)*5
						other(self.p).knockback+=(abs(self.oar)*oslap_amt)*(other(self.p).prc/100)
						other(self.p).stun=hit_stun
						self.ocount=0
					
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
				self.iar-=0.06
				if arm_hit(self.p, self.iarmhitxy[1],self.iarmhitxy[2]) then
					if not other(self.p).block then
						sfx(rnd({61,63}))
						other(self.p).prc_target+=flr(10*(self.iar/-0.4))
						self.stun=slap_stun
						self.islap="hit recover"
					else
						sfx(59)
						self.stun=block_stun
						self.shake+=1
						self.islap="block recover"
					end
					other(self.p).shake+=abs(self.iar)*5
					other(self.p).knockback+=(abs(self.iar)*islap_amt)*(other(self.p).prc/100)
					other(self.p).stun=hit_stun
					self.icount=0
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
		
		if self.gstate!="grab" 
		and self.gstate!="grapple"
		and self.gstate!="grappled"
		and self.iar<0 
	 	then
			--if (not button(4,self.p)
			if self.islap=="not ready"
			or self.gstate=="not ready"
			then
				self.iar+=arm_recover
			elseif self.islap=="block recover" then
				self.iar+=block_recover
			elseif self.islap=="hit recover" then
				self.iar+=hit_recover*0.8
			end
		end
		if self.gstate!="grab"
		and self.gstate!="grapple"
		and self.gstate!="grappled"
		and self.oar<0 
		then
			--if (not button(5,self.p) 
			if self.oslap=="not ready" 
			or self.gstate=="not ready"
			then
				self.oar+=arm_recover
			elseif self.oslap=="block recover" then
				self.oar+=block_recover
			elseif self.oslap=="hit recover" then
				self.oar+=hit_recover
			end
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
			if buttonp(1,self.p) then
					if self.lastb[1]=="➡️" 
					and self.dash_cool==0 
					and time()-self.lastb[2]<=0.2
					and time()-self.lastb[2]>0.1 
					and (self.p==0 or (self.p==1 and cpup2==false)) 
					and (self.gstate!="grappled" and self.gstate!="grapple") then
						self.dx=dash
						self.dash_cool=dash_cool
					end
					self.lastb={"➡️",time()}
			elseif buttonp(0,self.p) then
				if self.lastb[1]=="⬅️" 
					and self.dash_cool==0
					and time()-self.lastb[2]<=0.2
					and time()-self.lastb[2]>0.1 
					and (self.p==0 or (self.p==1 and cpup2==false))
					and (self.gstate!="grappled" and self.gstate!="grapple") then
						self.dx=-dash
						self.dash_cool=dash_cool
					end
					self.lastb={"⬅️",time()}
			end
			if self.dash_cool>0 then self.dash_cool-=1 end
			if button(1, self.p)
			and (self.gstate!="grappled") 
			then
				if self.dx==0 then self.dx=3 end
				self.move+=1
			elseif button(0, self.p) 
			and (self.gstate!="grappled")
			then
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
		if button(3, self.p) and self.canblock then
			self.block=true
			if self.br<=0.034 then
				self.br+=.017
			end
		end
		
		if not button(3,self.p) then
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
				sfx(62)
				winner="p2"
				add(p2record, 1)
				add(p1record, 0)
				gyoji_r=78
				music(-1,500)
			end
		else
			if self.r<-0.08 and self.r>-0.20 then
				self.r-=0.02
			elseif self.r<-0.20 then
				sfx(62)
				winner="p1"
				add(p1record, 1)
				add(p2record, 0)
				gyoji_l=76
				music(-1,500)
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
		self.islap="ready"
		self.oslap="ready"
		self.slap_timestamps={}
		self.slap_cooldown=0
		self.in_slap_cooldown=false
	end
}

function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
	  copy = {}
	  for orig_key, orig_value in pairs(orig) do
		copy[deepcopy(orig_key)] = deepcopy(orig_value)
	  end
	  setmetatable(copy, deepcopy(getmetatable(orig)))
	else
	  copy = orig
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


function wrnd(tbl)
 --weighted rnd
 --takes a table of keys with
 --values of weights
 local total = 0
 for _, weight in pairs(tbl) do
     total = total + weight
 end

 local rand = rnd(1) * total
 local cumulative = 0
 for key, weight in pairs(tbl) do
  cumulative = cumulative + weight
  if rand <= cumulative then
   return key
  end
	end
	return "none"
end
-->8
--bg/ui
function trifill(x, y, width, height, col)
  -- x, y: position of the right angle
  -- width: horizontal size (positive for right, negative for left)
  -- height: vertical size (positive for down, negative for up)
  -- col: color of the triangle

  -- Determine direction and bounds
  local x1 = x
  local y1 = y
  local x2 = x + width
  local y2 = y + height
  local y_start = y
  local y_end = y + height
  local step = height >= 0 and 1 or -1
  local abs_height = abs(height)
  local abs_width = abs(width)

  -- Iterate over each scanline (y-coordinate)
  for i = 0, abs_height do
    local t = i / abs_height -- Interpolation factor (0 to 1)
    local x_end = flr(x1 + t * (x2 - x1)) -- Linearly interpolate x
    local y_current = y_start + i * step
    -- Draw horizontal line for this scanline
    if width >= 0 then
      line(x1, y_current, x_end, y_current, col)
    else
      line(x_end, y_current, x1, y_current, col)
    end
  end
end

fade_table={
 {0,0,0,0,0,0,0},
 {1,129,129,129,129,0,0},
 {2,130,130,130,128,128,0},
 {3,131,131,129,129,129,0},
 {4,132,132,132,128,128,0},
 {5,133,133,130,128,128,0},
 {6,13,13,5,5,130,128},
 {7,6,134,134,5,133,128},
 {8,136,136,132,130,128,128},
 {9,4,4,132,132,128,128},
 {10,138,4,4,132,128,128},
 {139,139,3,3,129,129,0},
 {12,140,140,131,131,129,129},
 {140,140,131,1,129,129,0},
 {14,134,141,2,133,130,128},
 {132,130,130,128,128,128,0}
}

function fade(i)
  for c=0,15 do
  if flr(i+1)>=8 then
   pal(c,0,1)
  else
   pal(c,fade_table[c+1][flr(i+1)],1)
  end
 end
end

function draw_bg()
	left_edge=3-40-12+8
	right_edge=124+40+12-8
	top_edge=77
	rectfill(left_edge,top_edge,right_edge,128,4)
	oval(3-40,80,124+40,115,7)
	line(50,90,50,97)
	line(77,90,77,97)

	--stands
	line(-100, 20, 300, 20, 5)
	line(-100, 30, 300, 30, 5)
	line(-100, 40, 300, 40, 5)
	line(-100, 50, 300, 50, 5)
	line(-100, 60, 300, 60, 5)
	line(-100, 70, 300, 70, 5)

	--dohyo edges
	rectfill(left_edge,120,right_edge,128,15)
	--right
	trifill(right_edge+1, top_edge,13,14,15)
	rectfill(right_edge+1,top_edge+14,right_edge+14,128,15)
	line(right_edge+1,120,right_edge+14, 128,4)

	--left
	trifill(left_edge-1, top_edge,-13,14,15)
	rectfill(left_edge-1,top_edge+14,left_edge-14,128,15)
	line(left_edge-1,120,left_edge-14, 128,4)
	
	--center steps
	rectfill(64-8, 121, 64+8, 123, 4)
	rectfill(64-8, 125, 64+8, 127, 4)
end
function draw_countdown()
	local y = 20
	if countdown>0 and countdown<90 then
		print("\#1\^b\^t\^w"..(countdown\30)+1,camx+62, y, 7)
	elseif countdown<0 then
		print("\#1\^bはっけよい!", camx+40, y+7, 6)
		print("\#1\^t\^w\^bgo!", camx+52, y-5, 7)
	end
end
function init_audience()
	audience={}
	local stands = {20-8,30-8,40-8,50-8,60-8,70-8}

	for p=1,48 do
		local s=63
		if rnd(20)>17 then s=rnd({31,47}) else s=63 end
		add(audience, {x=(p*8)-50, y=rnd(stands), s=s})
		if rnd(20)>17 then s=rnd({31,47}) else s=63 end
		add(audience, {x=(p*8)-50, y=rnd(stands), s=s})
		s=63
		add(audience, {x=(p*8)-50, y=rnd(stands), s=s})
	end
end

function update_gyoji()
	-- Check if any player pressed X or O
	if (buttonp(4, 0) or buttonp(5, 0) or 
	    buttonp(4, 1) or buttonp(5, 1)) then
		-- Random chance (30%) to switch the sprite
		if rnd(10) < 3 then
			-- Toggle between sprites 69 and 101
			if gyoji_l == 69 then
				gyoji_l = 101
			else
				gyoji_l = 69
			end
		end
	end
end


function draw_gyoji()
	gyoji_offset=camx*gyoji_parallax
	spr(90,55+gyoji_offset,53,3,3)
	--left (screen lefT)
	spr(gyoji_l,43+gyoji_offset,57,2,2)
	--right (screen right)
	spr(gyoji_r,68+gyoji_offset,57,2,2)
end

function draw_audience()
	audience_offset=camx*0.01
	for a in all(audience) do
		spr(a.s, a.x+audience_offset,a.y)
	end
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
	--circfill(camx+92, camy+11,13,8)
	--circfill(camx+35, camy+11,13,8)
	print("\^t\^w"..p2.prc.."\^-t\^w%", camx+84+p2xo,camy+7+p2yo,7)
	print("\^t\^w"..p1.prc.."\^-t\^w%", camx+27+p1xo,camy+7+p1yo,7)
end

function count_wins(tab)
    local ones = 0
    local zeros = 0
    
    for i=1,#tab do
        if tab[i] == 1 then
            ones += 1
        elseif tab[i] == 0 then
            zeros += 1
        end
    end
    
    return ones, zeros
end

function draw_wins()
	local p1x=0
	local p2x=0
	pal(8,13,0)
	if #p1record<7 then
		for r in all(p1record) do 
			if r==1 then
				circfill(camx+3+p1x, 124, 2, 8)
			else
				circ(camx+3+p1x, 124, 2, 8)
			end
			p1x+=6
		end
	else
		local wins,losses = count_wins(p1record)
		circfill(camx+5, 124,2,8)
		print(wins, camx+9, 122, 7)

		circ(camx+22, 124,2,8)
		print(losses, camx+26, 122, 7)
	end
	
	pal(8,8,0)
	if #p2record<7 then
		for r in all(p2record) do 
			if r==1 then
				circfill(camx+124+p2x, 124, 2, 8)
			else
				circ(camx+124+p2x, 124, 2, 8)
			end
			p2x-=6
		end
	else
		local wins,losses = count_wins(p2record)
		circ(camx+119-((#tostr(losses)-1)*4), 124,2,8)
		print(losses, camx+123-((#tostr(losses)-1)*4), 122, 7)

		circfill(camx+101, 124,2,8)
		print(wins, camx+105, 122, 7)
	end
	--print("p2", camx+84,camy+17,7)
	--print("p1", camx+27,camy+17,7)
end

function draw_menu()
	local c=7
	if menu_counter==1 then c=7 else c=5 end
	cprint(menu[1],50,c)
	if menu_counter==2 then c=7 else c=5 end
	cprint(menu[2],60,c)
end

function update_menu()
	fade_timer+=1
	if fader>0 and fade_timer%2==0 and fade_timer>0 then
		fader-=1
	elseif fade_timer<=0 then
		if fade_timer%-2==0 and fader<8 then
			fader+=1
		elseif fader==8 then
			state="match_start"
			sfx(20)
			fade_timer=1
		end
	end
	menu_ready_timer+=1
	if menu_ready_timer>30 then
		if btnp(⬇️) then
			sfx(60)
			menu_counter+=1
			if menu_counter>2 then menu_counter=1 end
		end
		if btnp(⬆️) then
			sfx(60)
			menu_counter-=1
			if menu_counter<1 then menu_counter=2 end
		end
		if menu_counter==1 then cpup2=true else cpup2=false end
		if btnp(❎) then
			music(-1, 1000)
			menu_ready_timer=0
			fade_timer=-90
		end
	end
end

function update_reset_menu()
	if btnp(⬇️) then
		reset_menu_counter+=1
		if reset_menu_counter>2 then reset_menu_counter=1 end
	end
	if btnp(⬆️) then
		reset_menu_counter-=1
		if reset_menu_counter<1 then reset_menu_counter=2 end
	end
	if btn(❎) then
		if reset_menu_counter==1 then
			state="match_start"
		else
			state="main_menu"
			camx=2
			music(21)
		end
		reset_menu_counter=1
	end
end

function draw_reset()
	if winner!=" " then
		cprint(winner.." wins!", 40, 7, "\#0\^b")
		if reset_timer>45 then
			if reset_menu_counter==1 then
				cprint("rematch",50,7,"\#0\^b")
			else
				cprint("rematch",50)
			end
			if reset_menu_counter==2 then
				cprint("main menu",60, 7,"\#0\^b")
			else
				cprint("main menu",60)
			end
		end
	else
		cprint("press ❎ to start", 60)
	end
end

function cprint(s,y,c,extra)
	local c = c or 7
	local extra=extra or ""
	local x = camx+64-#s*2
	print(extra..s,x,y,c)
end

function update_camera()
	local p1c=p1.x-1
	local p2c=p2.x-21
	local center=((p1c+p2c)/2)-62
	
	-- Calculate screen positions of wrestlers
	local p1_screen_x = p1c - camx
	local p2_screen_x = p2c - camx
	
	-- Determine if we need to move the camera
	local need_camera_move = false
	

	cam_target_x = center
	need_camera_move = true

	
	-- Only move the camera if necessary
	if need_camera_move and abs(cam_target_x - camx) > cam_move_threshold then
		camx = camx + (cam_target_x - camx) * cam_smooth
	end
	
	-- Ensure camera doesn't go beyond game boundaries
	-- This keeps the dohyo centered when possible
	local min_cam_x = -50  -- Left boundary
	local max_cam_x = 50   -- Right boundary
	camx = mid(min_cam_x, camx, max_cam_x)
end

function create_particle(x, y, max_height, width, col, dir)
	local p = {
	  x = x,
	  y = y,
	  start_x = x,
	  start_y = y,
	  max_height = max_height,
	  width = width,
	  col = col,
	  -- progress through the arc (0 to 1)
	  age = 0,
	  -- how fast the particle moves through its arc
	  speed = rnd(0.01) + 0.09,
	  -- random direction (left or right)
	  dir = dir --1 or -1
	}
	
	add(dust_particles, p)
	return p
  end

function update_particles(extend)
	local extend = extend or 0
	for i=#dust_particles,1,-1 do
		local p = dust_particles[i]
		
		-- update progress
		p.age += p.speed
		
		-- calculate current position based on arc
		-- using sine wave to create the arc motion
		p.x = p.start_x + (p.width * p.age * p.dir)
		
		-- parabolic trajectory for y
		-- y = 4 * h * (x - x²) where x is 0 to 1
		-- this makes particle go up and then down
		local arc_height = 4 * p.max_height * (p.age - p.age * p.age)
		p.y = p.start_y - arc_height
		
		-- remove particle if it has completed its arc
		-- (progress >= 1 means it has traveled full width and returned to starting height)
		if p.y>p.start_y+extend then
			deli(dust_particles, i)
		end
	end
end

function draw_particles()
	for p in all(dust_particles) do
	  pset(p.x, p.y, p.col)
	end
end



function draw_label()
	rectfill(0,78,165,165,4)
	oval(3,80,128,120,7)
	
	--gyoji
	spr(90,58,54,3,3)
	--left (screen lefT)
	spr(101,46,58,2,2)
	--right (screen right)
	spr(110,71,58,2,2)
	local x,y=camx-13,27
	pal(8,13,0)
	pal(14,140,0)
	pal(13,140,1)
	
	--i leg
	pd_rotate(x+41,y+82,0,7,6,5,false,3)
	--iarm
	pd_rotate(x+45,y+30,0,32,3,5,false, 3)
	--body
	pd_rotate(x,y,0,p1.bodymapx,p1.bodymapy,7.8,false,3)
	--o leg
	pd_rotate(x-30,y+75,0,15,6,7, false, 3)
	--o arm
	pd_rotate(x+13,y+24,0,33,12,6.5,false,3)

	pal(8,8,0)
	pal(14,14,0)
	local x,y=camx+120,27
	--ileg
	pd_rotate(x-21,y+82,0,7,6,5,true,3)
	--iarm
	pd_rotate(x-25,y+30,0,32,3,5,true, 3)
	--body
	pd_rotate(x,y+99,0,p2.bodymapx,p2.bodymapy,7.8,true,3)
	--o leg
	pd_rotate(x+52,y+75,0,15,6,7, true, 3)
	--o arm
	pd_rotate(x+7,y+24,0,33,12,6.5,true,3)
	
	
	local logox,logoy = camx+25, 3
	print("\^w\^tおしネきし", logox+1, logoy, 7)
	print("\^woshidashi!", logox+1, logoy+12,7)
	print("\^w\^tすも", logox+23, logoy+19, 7)
	print("\^wsumo", logox+24, logoy+31,7)


end
function draw_main_menu()
	local x,y=camx+4,27
	if menu_arm_state=="pause" then
		menu_arm_count+=1
		if menu_arm_count>=120 then
			menu_arm_state="up"
			menu_arm_count=0
		end
	elseif menu_arm_state=="up" then
		menu_arm_r-=0.03
		if menu_arm_r<-0.15 then
			menu_arm_state="down"
			for c=0,10 do
				create_particle(x+58,y+39, rnd(50), rnd(50), 7, 1)
			end
		end
	elseif menu_arm_state=="down" then
		menu_arm_r+=0.02
		if menu_arm_r>=0 then
			menu_arm_state="pause"
		end
	end

	
	pal(8,13,0)
	pal(14,140,0)
	pal(13,140,1)
	--i leg
	pd_rotate(x+43,y+82,0,7,6,5,false,3)
	--iarm
	pd_rotate(x+45,y+30,0,32,3,5,false, 3)
	--body
	pd_rotate(x,y,0,p1.bodymapx,p1.bodymapy,7.8,false,3)
	--o leg
	pd_rotate(x-30,y+75,0,15,6,7, false, 3)
	--o arm
	pd_rotate(x+8,y+23,menu_arm_r,33,12,6.5,false,3)
	
	
	local logox,logoy = camx+48, 3
	print("\^w\^tおしネきし", logox+1, logoy, 7)
	print("\^woshidashi!", logox+1, logoy+12,7)
	print("\^w\^tすも", logox+23, logoy+19, 7)
	print("\^wsumo", logox+24, logoy+31,7)


	local p1x,p1y=camx+80,60
	local p2x,p2y=camx+80,80

	rectfill(p1x,p1y,p1x+40,p1y+12,7)
	if menu_counter==1 then
		rect(p1x-1,p1y-1,p1x+41,p1y+13,10)
	end
	print("1 player", p1x+5, p1y+4,0)
	rectfill(p2x,p2y,p2x+40,p2y+12,7)
	if menu_counter==2 then
		rect(p2x-1,p2y-1,p2x+41,p2y+13,10)
	end
	print("2 players", p2x+4, p2y+4,0)
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

	if p1.knockback>5 and p1.r==0 then
		if rnd(2)>1 then
			create_particle(p1.x-21, p1.y+32, rnd(3), rnd(10), 9, -1)
		end
		if rnd(2)>1 then
			create_particle(p1.x+4, p1.y+22, rnd(3), rnd(10), 9, -1)
		end
	end

	if p2.knockback>5 and p2.r==0 then
		if rnd(2)>1 then
			create_particle(p2.x-2, p1.y+32, rnd(3), rnd(10), 9, 1)
		end
		if rnd(2)>1 then
			create_particle(p2.x-27, p1.y+22, rnd(3), rnd(10), 9, 1)
		end
	end
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
-->8
--cpu conditions and personality profiles
strat_buff=30

-- CPU personality profile settings
cpu_personalities = {
	aggressive = {
		arm_strats = {
			grab=150,
			slap=180,
			defend=30,
			none=20,
		},
		movement_strats = {
			advance=200,
			retreat=20,
			footsies=60,
		},
		reaction_time=0.8, -- multiplier, lower = faster
		description="Aggressive attacker"
	},
	defensive = {
		arm_strats = {
			grab=70,
			slap=60,
			defend=200,
			none=50,
		},
		movement_strats = {
			advance=50,
			retreat=130,
			footsies=150,
		},
		reaction_time=0.9,
		description="Defensive counter-fighter"
	},
	balanced = {
		arm_strats = {
			grab=100,
			slap=110,
			defend=80,
			none=90,
		},
		movement_strats = {
			advance=100,
			retreat=80,
			footsies=120,
		},
		reaction_time=1.0,
		description="Balanced fighter"
	},
	tactical = {
		arm_strats = {
			grab=130,
			slap=90,
			defend=100,
			none=60,
		},
		movement_strats = {
			advance=120,
			retreat=110,
			footsies=180,
		},
		reaction_time=0.7,
		description="Tactical fighter"
	}
}

-- Base weights that will be modified by personality and difficulty
arm_strats = {
		grab=100,
		slap=110,
		defend=0,
		none=100,
}

movement_strats = {
		advance=100,
		retreat=20,
		footsies=110,
}

-- Dynamic difficulty adjustment
difficulty_level = 2 -- 1=easy, 2=normal, 3=hard, 4=expert
difficulty_scaling = 1.0 -- Will be adjusted based on player performance
consecutive_losses = 0 -- Track player losses to adjust difficulty


function is_slap_range(c,a)
	if abs(p1.x-p2.x)<70 then
		arm_strats[c]+=a
	end
end

function is_grab_range(c,a)
	if abs(p1.x-p2.x)<70 then
		arm_strats[c]+=a
	end
end

function is_far_away(c,a)
	if abs(p1.x-p2.x)>80 then
		arm_strats[c]+=a
	end
end

function is_close(c,a)
	if abs(p1.x-p2.x)<40 then
		movement_strats[c]+=a
	end
end

function is_far(c,a)
	if abs(p1.x-p2.x)>50 then
		movement_strats[c]+=a
	end
end

function is_near_edge(c,a)
	if p2.x>140 or p1.x<5 then
		movement_strats[c]+=a
	end
end

function is_winning(c,a)
	if p1.prc>80 and p2.prc<p1.prc then
		movement_strats[c]+=a
	end
end

function p1_slapping(c,a)
	if p1.islap=="slap" or p1.oslap=="slap" then
		arm_strats[c]+=a
	end
end

function p1_close_and_slapping(c,a)
	if abs(p1.x-p2.x)<60 and (p1.islap=="slap" or p1.oslap=="slap") then
		arm_strats[c]+=a
	end
end

-- Check if player's attack was just blocked - opportunity to counter-attack
function p1_attack_blocked(c,a)
	if p1.islap=="block recover" or p1.oslap=="block recover" then
		arm_strats[c]+=a
	end
end
function p1_attack_blocked_move(c,a)
	if p1.islap=="block recover" or p1.oslap=="block recover" then
		movement_strats[c]+=a
	end
end

function is_grappling(c,a)
	if p2.gstate=="grapple" then
		movement_strats[c]+=a
	end
end

function p2_grappling(c,a)
	if p2.gstate=="grapple" then
		arm_strats[c]+=a
	end
end

arm_conditions={
	{f=is_slap_range,s="slap",a=50},
	{f=is_grab_range,s="grab",a=30},
	{f=is_far_away,s="none",a=150},
	{f=p1_slapping,s="defend",a=50},
	{f=p1_close_and_slapping,s="defend",a=150},
	{f=p1_attack_blocked,s="slap",a=200}, -- High priority counter-attack after blocking
	{f=p2_grappling,s="slap", a=1000},
}


movement_conditions={
	{f=is_close, s="advance",a=20},
	{f=is_far, s="advance", a=100},
	{f=is_near_edge, s="advance",a=100},
	{f=is_winning, s="advance", a=200},
	{f=p1_attack_blocked_move,s="advance",a=200},
	-- Make CPU advance when slapping to stay in range
	{f=function(c,a) if cpu.arms=="slap" then movement_strats[c]+=a end end, s="advance",a=150}
}

cpu_pad={}
cpu_pad[0]=0 --⬅️
cpu_pad[1]=0 --➡️
cpu_pad[2]=0 --⬆️
cpu_pad[3]=0 --⬇️
cpu_pad[4]=0 --🅾️
cpu_pad[5]=0 --❎

cpu={
	movement="retreat", --or retreat or footsies
	arms="slap", --or slap or defend or none
	no_move=0,
	mstrat_time=1,
	astrat_time=1,
}



function pick_arms_strat()
	for c in all(arm_conditions) do
		c.f(c.s,c.a)
	end
	cpu.astrat_time+=1
	
	if cpu.astrat_time%strat_buff==0 then
		cpu.arms=wrnd(arm_strats)
	end
	if cpu.astrat_time>strat_buff*2 then
		for k,_ in pairs(arm_strats) do
			arm_strats[k]=1
		end
		cpu.astrat_time=1	
	end
	if p2.gstate=="grapple" then
		cpu.arms="slap"
	end
end

function pick_movement_strat()
	for c in all(movement_conditions) do
		c.f(c.s,c.a)
	end
	cpu.mstrat_time+=1
	if cpu.mstrat_time>strat_buff then
		cpu.movement=wrnd(movement_strats)
	end
	for k,v in pairs(movement_strats) do
		if v>5000 then movement_strats[k] = 1000 end
	end

	if p2.gstate=="grapple" then
		cpu.movement="advance"
	end
end

function init_cpu_personality()
	-- Randomly select a personality at match start
	local personalities = {"aggressive", "defensive", "balanced", "tactical"}
	local rand_idx = 1 + flr(rnd(#personalities))
	cpu.personality = personalities[rand_idx]
	
	-- Copy personality base stats to current strategy weights
	local profile = cpu_personalities[cpu.personality]
	for k,v in pairs(profile.arm_strats) do
		arm_strats[k] = v
	end
	for k,v in pairs(profile.movement_strats) do
		movement_strats[k] = v
	end
	
	-- Set reaction delay based on personality
	cpu.reaction_delay = profile.reaction_time * 3
	
	-- Initialize additional CPU properties
	cpu.strat_variance = 1 -- Add some randomness to strategy timing
	cpu.combo_state = 0 -- Track combo progression
	
	-- Adjust for difficulty level
	apply_difficulty_scaling()
end

function adjust_difficulty()
	-- Based on match results, adjust difficulty scaling
	if winner == "p1" then
		consecutive_losses += 1
		difficulty_scaling = min(difficulty_scaling + 0.1, 1.5)
	elseif winner == "p2" then
		consecutive_losses = max(consecutive_losses - 1, 0)
		if consecutive_losses <= 0 then
			difficulty_scaling = max(difficulty_scaling - 0.05, 0.5)
		end
	end
	
	apply_difficulty_scaling()
end

function apply_difficulty_scaling()
	-- Apply the difficulty scaling to various CPU parameters
	cpu.reaction_delay = cpu.reaction_delay / difficulty_scaling
	
	-- Scale strategy weights based on difficulty
	for k,v in pairs(arm_strats) do
		if k == "defend" then
			-- Higher difficulty = better at defending
			arm_strats[k] = v * difficulty_scaling
		end
	end
	
	-- Expert difficulty gets combo awareness
	if difficulty_level >= 3 then
		cpu.combo_state = 1
	end
end

function update_cpu_pad()
	for k,v in pairs(cpu_pad) do
		if v>0 then cpu_pad[k]-=1 end
	end
	if cpu.no_move>0 then cpu.no_move-=1 end
	
	-- Apply reaction delay based on personality and difficulty
	if cpu.reaction_delay > 0 then
		-- Randomly decide if we should delay this frame
		if rnd(10) < cpu.reaction_delay then
			-- Skip updating CPU inputs this frame
			return
		end
	end
end

function button(bt,p)
	if cpup2 and p==1 then
		return cpu_pad[bt]>0
	else
		return btn(bt, p)
	end
end

function buttonp(bt,p)
	if cpup2 and p==1 then
		return cpu_pad[bt]==1
	else
		return btnp(bt, p)
	end
end

function update_cpu_movement()
 cpudx=rnd(10)
 if cpu_pad[0]==0 and cpu_pad[1]==0 and cpu.no_move==0 then
		if cpu.movement=="advance" then
			if cpudx>=5 then cpu_pad[0]=4 end
		elseif cpu.movement=="retreat" then
			if cpudx>=5 then cpu_pad[1]=3 end
		elseif cpu.movement=="footsies" then
			if cpudx>=7 then 
				cpu_pad[0]=5
			elseif cpudx<7 and cpudx>=4 then 
				cpu_pad[1]=5 
			else
				cpu.no_move=5
			end
		else
			--cpu.movement="footsies"
		end
	end
	pick_movement_strat()
end

function update_cpu_arms()
	cpui=rnd(20)
	cpuo=rnd(20)
	if p2.islap=="ready" or p2.oslap=="ready" then
		if cpu.arms=="slap" then
			-- More aggressive slapping - immediately slap when strategy is selected
			-- Alternate between inner and outer slaps to create a barrage
			if p2.islap=="ready" then
				cpu_pad[4]=1
			elseif p2.oslap=="ready" then
				cpu_pad[5]=1
			end
		elseif cpu.arms=="grab" then
			if p2.gstate=="ready" then
				cpu_pad[4]=1
				cpu_pad[5]=1
				cpu.arms="slap"
				arm_strats["grab"]=0
			end
		elseif cpu.arms=="defend" then
			cpu_pad[3]=1
		else
			cpu.arms="none"
		end
	end
	pick_arms_strat()
end
-->8
function print_cpu_strats()
	local y = 20 
	for k,v in pairs(arm_strats) do
		y+=8
		print(k..":"..v,camx+84,y,7)
	end
	print(cpu.astrat_time, camx+84, y+8, 7)
	print(flag, camx+65, y+10, 7)
	y=20
	for k,v in pairs(movement_strats) do
		y+=8
		print(k..":"..v,camx+27,y,7)
	end
	print(cpu.mstrat_time, camx+27, y+8, 7)
end

function update_music()
	for i=0x3100,0x3190,4 do
		--turn on channel 3
		if p2.gstate=="grappled" or p1.gstate=="grappled" then
			poke(i+2,peek(i+2)&0b10111111)
		else
			poke(i+2,peek(i+2)|0b01000000)
		end
		
		if p1.x<-6 or p2.x>157 then
			--turn off melody
			poke(i+3,peek(i+3)|0b01000000)
		else
			poke(i+3,peek(i+3)&0b10111111)
		end
		if p1.x<=-10 or p2.x>161 then
			poke(i+1,peek(i+1)|0b01000000)
		else
			poke(i+1,peek(i+1)&0b10111111)
		end

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
bbbbbbbbbbeeeeeeebbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbccccccccccccbbbbbbbbb888888888bbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbbb666666b
bbbbbbbbbbeeeeeebbbbbbbbbbbeeeeeeeeeeeeebbbbbbbbbbbcccccccccccccccbbbbbbbb888888888bbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbb655556b
bbbbbbbbbbeeeeeebbbbbbbbbbbeeeeeeeeeeebbbbbbbbbbbbbcccccccccccccccbbbbbbb888888888bbbbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbb665666b
bbbbbbbbbbbeeeebbbbbbbbbbbeeeeeeeeeebbbbbbbbbbbbbbcccccccccccccccccbbbbbb888888888bbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbb655556b
bbbbbbbbbbbeeeebbbbbbbbbbbeeeeeeeeeebbbbbbbbbbbbbbccccccccccccccccccbbbb888888888bbbbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbb656566b
bbbbbbbbbbbeeeebbbbbbbbbbbeeeeeeeeeebbbbbbbbbbbbbcccccccccccccccccccbbbb888888888bbbbbbbbbbb888888bbbbbbbbbbbbbbbbbbbbbbb666666b
bbbbbbbbbbeeeeeebbbbbbbbbbeeeeeeeeebbbbbbbbbbbbbbcccccccccccccccccccbbbb888888888bbbbbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbb55555555
bbbbbbbbbbeeeeeeebbbbbbbbbeeeeeeeeebbbbbbbbbbbbbccccccccccccccccccccbbbbb88888888bbbbbbbbbbbb88888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbeeeeeeebbbbbbbbbeeeeeeebbbbbbbbbbbbbbccccccccccccccccccccbbbbb88888888bbbbbbbbbbbbb888bbbbbbbbbbbbbbbbbbbbbbbb666666b
bbbbbbbbbbbbeeeeeebbbbbbbbbeeeeeeebbbbbbbbbbbbbbcccccccccccccccccccbbbbbb888888888bbbbbbbbbbbb88bbbbbbbbbbbbbbbbbbbbbbbbb666566b
bbbbbbbbbbbbbbeeeebbbbbbbbbeeeeeebbbbbbbbbbbbbbbcccccccccccccccccccbbbbbbb8888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb665556b
bbbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeebbbbbbbbbbbbbbbcccccccccccccccccccbbbbbbbb8888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb656566b
bbbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeebbbbbbbbbbbbbbb00cccccccccccccccccbbbbbbbb8888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb656566b
bbbbbbbbbbbbbbbbbbbbbbbbbeeeeeeeebbbbbbbbbbbbbbb000cccccccccccccccbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666666b
bbbbbbbbbbbbbbbbbbbbbbbbeeeeeeeebbbbbbbbbbbbbbbb00000cccccccccccccbbbbbbbbbb88888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555
bbbbbbbbbbbbbbbbbbbbbbbbeeeeeeebbbbbbbbbbbbbbbbb0000000cccccccccccbbbbbbbbbbb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111
bbbbbbbbbbbbbbbbbbbbbbbbbeeeeebbbbbbbbbbbbbbbbbbc00000000ccccccc00bbbbbbbbbbbb8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11555511
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc00000000cccc000bbbbbbbbbbbbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb15555551
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccc0000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb15555551
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccc0000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb15555551
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccc000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11555511
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccc00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb15555551
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccc00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555
bbbbbbbbbe00000000eeeeeee00bbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66333333333333333333366bbbbb
bbbbbbbbbeee00000000eeee000bbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb633333333333333333336bbbbbb
bbbbbbbbbeeeee0000000000000bbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333bbbbbbbbb
bbbbbbbbbeeeeeee0000000000bbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333bbbbbbbbbbb
bbbbbbbbbeeeeeee000000000bbbbbbbbbbbbbbbbbbbbbbbbbb33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbeeeeeee00000000bbbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbeeeee00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbb77777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb0000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbb000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333666333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbb00000ee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333363333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbee00eeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbeeeee0eeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb
bbbbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbb
bbbbbbbbbbbbeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbb
bbbbbbbbbbbeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbb733333337bbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbb
bbbbbbbbbbbeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbb33333bbbbbbbbbbbbbbbbbbbbbbbbbbbb777777777bbbbbbbbbbbbbbbbbbb33333bbbbbbbbbbb
bbbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbb337773bbbbbbbbbbbbbbbbbbbbbbbbbbbb377777773bbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbb
bbbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbb377777bbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333bbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbb
bbbbbbbbbeeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbb377777bbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333bbbbbbbbbbbbbbbbbbb333bbbbbbbbbbb
bbbbbbbbbeeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbb33777bbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333bbbbbbbbbbbbbbbbb333bbbbbbbbbbbb
bbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbb3376bbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333bbbbbbbbbbbbbbb663bbbbbbbbbbbbb
bbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbb6bbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333bbbbbbbbbbbbbbbb6bbbbbbbbbbbbbb
bbbbbbbbbeeeeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbb00eeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbb000eeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbb00000eeeeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333b33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbb0000000eeeeeeeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333bbb3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111117777771111771111771111111111111111117711111111117777777711111111771111111111111111111111111111111111
11111111111111111111111111117777771111771111771111111111111111117711111111117777777711111111771111111111111111111111111111111111
11111111111111111111111111111177111111111111771111111111111177777777771111111111771111111111771111111111111111111111111111111111
11111111111111111111111111111177111111111111771111111111111177777777771111111111771111111111771111111111111111111111111111111111
11111111111111111111111111117777777777111111771111111111111111111177771111111177777777111111771111111111111111111111111111111111
11111111111111111111111111117777777777111111771111111111111111111177771111111177777777111111771111111111111111111111111111111111
11111111111111111111111111771177111111771111771111117711111177777777117711771111117711111111771111117711111111111111111111111111
11111111111111111111111111771177111111771111771111117711111177777777117711771111117711111111771111117711111111111111111111111111
11111111111111111111111111117777111177111111117777771111111111117711111111117777111111111111117777771111111111111111111111111111
11111111111111111111111111117777111177111111117777771111111111117711111111117777111111111111117777771111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111117777111177771177117711777777117777111177777711117777117711771177777711117711111111111111111111111111
11111111111111111111111111771177117711111177117711117711117711771177117711771111117711771111771111117711111111111111111111111111
11111111111111111111111111771177117777771177777711117711117711771177777711777777117777771111771111117711111111111111111111111111
11111111111111111111111111771177111111771177117711117711117711771177117711111177117711771111771111111111111111111111111111111111
11111111111111111111111111777711117777111177117711777777117777771177117711777711117711771177777711117711111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111177111111111177777777111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111177111111111177777777111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111777777777711111111771111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111777777777711111111771111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111177111111111177777777111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111177111111111177777777111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111117777111111111111771111117711111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111117777111111111111771111117711111111111111111111111111111111111111111111111111
11111111111111111111111000000111111111111111111111111177111111111111117777771111111111111111111111111111111111111111111111111111
11111111111111111111111000000111111111111111111111111177111111111111117777771111111111111111111111111111111111111111111111111111
11111111111111111111111000000111111111111111111111111111111111111111111111111111111111111111111111100000011111111111111111111111
11111111111111111000000000000111111111111111111111111111111111111111111111111111111111111111111111100000000000011111111111111111
11111111111111111000000000000111111111111111111111177771177117711777777111177771111111111111111111100000000000011111111111111111
11111111111111111000000000000111111111111111111117711111177117711777777117711771111111111111111111100000000000011111111111111111
11111111111111111000000000000000000000111111111117777771177117711771177117711771111111111100000000000000000000011111111111111111
11111111111111111000000000000000000000111111111111111771177117711771177117711771111111111100000000000000000000011111111111111111
11111111111111111000000000000000000000111111111117777111111777711771177117777111111111111100000000000000000000011111111111111111
11111111111111111000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000011111111111111111
11111111111111111000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000011111111111111111
11111111111111111000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000011111111111111111
11111111111111000000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000011111111111111
11111111111111000000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000011111111111111
11111111111111000000000000000000000000000111111111111111111111111111111111111111111111100000000000000000000000000011111111111111
11111111111111000000000000000cccccc0001111111111111111111111111111111111111111111111111111000eeeeee00000000000000011111111111111
11111111111111000000000000000cccccc0001111111111111111111111111111111111111111111111111111000eeeeee00000000000000011111111111111
11111111111111000000000000000cccccc0001111111111111111111111111111111111111111111111111111000eeeeee00000000000000011111111111111
11111111111cccccc000000ccccccccccccccc1111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee000000eeeeee11111111111
11111111111cccccc000000ccccccccccccccc1111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee000000eeeeee11111111111
11111111111cccccc000000ccccccccccccccc1111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee000000eeeeee11111111111
sssssssccccccccccccc000ccccccccccccccc1111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee000eeeeeeeeeeeee8888888
sssssssccccccccccccc000ccccccccccccccc1111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee000eeeeeeeeeeeee8888888
sssssssccccccccccccc000ccccccccccccccc1111111111111111111111111111111111111111111111111111eeeeeeeeeeeeeee000eeeeeeeeeeeee8888888
sssssssccccccccccccccccccccccccccccccc1111111111111111111111111111011111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
sssssssssssssccccccccccccccccccccccccc1111111111111111111111111110001111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccc1111111111111111111111111116661111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccccccssss111111111111111111116661111111111111118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccccccssss111111111111111113336663333111111111118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccccccssss111111111111111333333633333311111111118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccccccssss111111111111113333333333333331111111118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssssscccccccccccccccccccccccccsssssss111111111133333333333333333111118888888eeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccsssssss111111111333333333333333333311118888888eeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
ssssssssssssssssccccccccccccccccccccccccccccssss111111113377733333333331333311118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
ssssssssssssssssccccccccccccccccccccccccccccssss111111113777773333333331133311118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
ssssssssssssssssccccccccccccccccccccccccccccssss111111113777777333333371133311118888eeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111113377717777777771333111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111111337613777777736631111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111111116133333333333611111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111111111333333333333311111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111111113333333333333331111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111111133333333333333333111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssssscccccccccccccccccccccccccccccccs111111111133333333333333333111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888888
sssssssssssssccccccccccccccccccccccccccccccccccs111111111133333333333333333111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccccccccccccs111111111133333333333333333111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssssssccccccccccccccccccccccccccccccccccs111111111133333333333333333111118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888
sssssssssscccccccccccccccccccccccccccccccccccccssss111111133333333133333333118888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
sssssssssscccccccccccccccccccccccccccccccccccccssss111111133333331113333333118888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
sssssssssscccccccccccccccccccccccccccccccccccccssss444444444444444444444444448888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
sssssssssscccccccccccccccccccccccccccccccccccccssss444444444444444444444444448888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
sssssssssscccccccccccccccccccccccccccccccccccccssss477777777777777777777777778888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ssssssssssccccccccccccccccccccccccccccccccccsssssss744444444444444444444444448888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ssssssssssccccccccccccccccccccccccccccccccccsssssss444444444444444444444444448888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ssssssssssccccccccccccccccccccccccccccccccccsssssss444444444444444444444444448888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ssssssssssccccccccccccccccccccccccccccccccccsssssss444444444444444444444444448888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888
ssssssscccccccccccccccccccccccccccccccccccccssssssssss444444444444444444448888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
ssssssscccccccccccccccccccccccccccccccccccccssssssssss444444444444444444448888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
ssssssscccccccccccccccccccccccccccccccccccccssssssssss444444444444444444448888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
ssssssscccccccccccccccccccccccccccccccccccccssssssssss444444444444444444448888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
ssssssscccccccccccccccccccccccccccccccccccccssssssssss444444444444444444448888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
ssssssscccccccccccccccccccccccccccccccccccccssssssssss444444444444444444448888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888
ssssccccccccccccccccccccccccccccccccccccccccsssssssssssss444444444444448888888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssssccccccccccccccccccccccccccccccccccccccccsssssssssssss444444444444448888888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
sssscccccccccccccccccccccccccccccccccccccssssssssssssssss444444444444448888888888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssssccccccccccccccccccccccccccccccccccccc4sssssssssssssss444444444444448888888888888884eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssssccccccccccccccccccccccccccccccccccccc4sssssssssssssss444444444444448888888888888884eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssssccccccccccccccccccccccccccccccccccccc4sssssssssssssss444444444444448888888888888884eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssssccccccccccccccccccccccccccccccccccccc4444sssssssssssssss444444448888888888888884444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssssccccccccccccccccccccccccccccccccccccc4444sssssssssssssss444444448888888888888884444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888
ssss0000ccccccccccccccccccccccccccccccccc4444sssssssssssssss444444448888888888888884444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00008888
ssss0000ccccccccccccccccccccccccccccccccc4444ssssssssssssssssss448888888888888888884444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00008888
ssss0000ccccccccccccccccccccccccccccccccc4444ssssssssssssssssss448888888888888888884444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00008888
ssss0000000000ccccccccccccccccccccc0000004444ssssssssssssssssss448888888888888888884444000000eeeeeeeeeeeeeeeeeeeee00000000008888
ssss0000000000ccccccccccccccccccccc0000004444444sssssssssssssss448888888888888884444444000000eeeeeeeeeeeeeeeeeeeee00000000008888
ssss0000000000ccccccccccccccccccccc0000004444444sssssssssssssss448888888888888884444444000000eeeeeeeeeeeeeeeeeeeee00000000008888
ssss0000000000000000cccccccccccc0000000004444444sssssssssssssss448888888888888884444444000000000eeeeeeeeeeee00000000000000008888
ssssssscc00000000000cccccccccccc0000000004444444sssssssssssssss448888888888888884444444000000000eeeeeeeeeeee00000000000008888888
ssssssscc00000000000cccccccccccc0000000004444444sssssssssssssss448888888888888884444444000000000eeeeeeeeeeee00000000000008888888
ssssssscc000000000000000000000000000000004444444sssssssssssssss44888888888888888444444400000000000000000000000000000000008888888
sssssssssssss00000000000000000000000000004444444444sssssssss44444444888888888444444444400000000000000000000000000008888888888888
sssssssssssss00000000000000000000000000004444444444sssssssss44444444888888888444444444400000000000000000000000000008888888888888
sssssssssssss0000000000000000000000000ccc4444444444sssssssss444444448888888884444444444eee00000000000000000000000008888888888888
ssssssssssssssss0000000000000000000000ccc4444444444ssssss444444444444448888884444444444eee00000000000000000000008888888888888888
ssssssssssssssss0000000000000000000000cccccc4444444ssssss444444444444448888884444444eeeeee00000000000000000000008888888888888888
ssssssssssssssss0000000000000000000ccccccccc4444444ssssss444444444444448888884444444eeeeeeeee00000000000000000008888888888888888
ssssssssssssssssccccc00000000000000ccccccccc4444444444444444444444444444444444444444eeeeeeeee0000000000000000eee8888888888888888
ssssssssssssssssccccc00000000000000cccccccccccc4444444444444444444444444444444444eeeeeeeeeeee0000000000000000eee8888888888888888
ssssssssssssssssccccc00000000000ccccccccccccccc4444444444444444444444444444444444eeeeeeeeeeeeeee0000000000000eee8888888888888888
ssssssssssssssssccccc00000000000ccccccccccccccc4444444444444444444444444444444444eeeeeeeeeeeeeee0000000000000eee8888888888888888
ssssssssssssssssccccc00000000000cccccccccccccccccc7744444444444444444444444444eeeeeeeeeeeeeeeeee0000000000000eee8888888888888888
ssssssssssssssssccccc00000000ccccccccccccccccccccc4477777777777777777777777777eeeeeeeeeeeeeeeeeeeee0000000000eee8888888888888888
sssssssssssssccccc4444444444cccccccccccccccccccccc4444444444444444444444444444eeeeeeeeeeeeeeeeeeeee0000000000000eee8888888888888
sssssssssssssccccc4444444444ccccccccccccccccccccccccc4444444444444444444444eeeeeeeeeeeeeeeeeeeeeeee0000000000000eee8888888888888
sssssssssssssccccc4444444444ccccccccccccccccccccccccc4444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeee444444444444eee8888888888888
ssssssssssccccc4444444444444ccccccccccccccccccccccccc4444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeee444444444444444eee8888888888
ssssssssssccccc44444444444444444cccccccccccccccccccccccc4444444444444444eeeeeeeeeeeeeeeeeeeeeeee4444444444444444444eee8888888888
ssssssssssccccc44444444444444444cccccccccccccccccccccccc4444444444444444eeeeeeeeeeeeeeeeeeeeeeee4444444444444444444eee8888888888
sssssssccccc44444444444444444444cccccccccccccccccccccccc4444444444444444eeeeeeeeeeeeeeeeeeeeeeee4444444444444444444444eee8888888

__map__
0607080c0c0c0c0c0d0d0c0c0c0c0c0d0d0d0d0e484868686868484848481e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1617180c0c0c0c0c0d0d0c0c0c0c0c0d0d0d1d1e484850515253484848592e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2627280c0c0c0c0c0d0d0c0d0d0d0d0d0d0d2d2e484860616263484848592e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3637380c0c0c0c0c0d0d0d3c0c0c0c0c3b3c3d3e484870717273484848592e1e0b0c0d0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c340c0c0c0c0c0c0c1e1e1e061e2e2e2e2e2e404142432e2e2e592e1e1b1c1d1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48484848340c0c0c0c0c0c0c1e1e1e1e1e2e2e2e2e2e2e2e2e2e2e2e2e2e2e1e2b2c2d2e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48484834340c0c01020c0c0c1e1e25030405062e2e2e2e2e2e2e2e2e2e2e2e1e3b3c3d3e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48483434340c0c11120c0c0c1e34351314150d2e2e2e2e2e2e2e2e2e2e2e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48483434340c0c21220c0c0c0c0c0c2324250d2e2e2e2e1e1e1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0048480000000000000000000000003334350d1e1e1e1e1e1e1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000090a0d0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000191a0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000292a0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000393a3b3c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
a40100001700018000180001700020000230002500027000000000200006000080000c0000f00013000170001d000220002660026600286001d50000500000000000000000000000000000000000000000000000
0110000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000007300073070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
930a00003701039010370103901037010390103701039010370203902037020390203702039020370203902037030390303703039030370303903037030390303704039040370403904037050390503705039050
c81400002d1102d1152b1102b115261102611528110281152b1102b11528110281152411024115261102611528110281152611026115241102411521110241102811528115261152611524110241122411224112
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7140000000730c003000030000000043000000000300000000730000000003000000004300000000030000000073000000000300000000430000000003000000007300003000430000300000000000004300000
a714000000000000002b623000002b623000032b6230000000000000002b6230000000000000002b623000002b6252b6252b62300000000002b6252b62300000000002b6252b623000002b623000002b6252b623
a71400002b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b6252b625
a7140000000732d6252d625000732d6252d625000732d625000732d6252d625000732d6252d625000732d625000732d6252d625000732d6252d625000732d6252d625000732d6252d625246752b605246752b605
a70a00002d625000002b6252b6252b625000002d625000002b6252b6252b62500000246751f645246751f6452d625000002b6252b6252b625000002d625000002b6252b6252b62500000246751f645246751f645
bf0a00000001524615246152461524625246252462524625246352463524635246352464524645246452464524655246552465524655246652466524665246652467524675246752467524675246752467524675
a70a00002b6152b6152b6152b6152b6252b6252b6252b6252b6352b6352b6352b6352b6452b6452b6452b6452b6552b6552b6552b6552b6652b6652b6652b6652b6752b6752b6752b6752d6752d6752d6752d675
c51400000974009745000000000009740097450c7400c7450e7400e7450e7400e7450c7400c745107401074515745000001574515745157451574513745137451074010740107421074200000000000000000000
c51400000e7200e72500000000000e7200e7250c7200c7250e7200e72510720107250c725000000c7250000009725097250972509725097250972507725077250972009720097220972209725000000472507725
920100000b75205752007023870238702377023770237702377023770237702367023670236702367023670236702357023570235702357023570236702367023670236702357023570235702007020070200702
930200000f25013250152501c20014200152001520015200152001520015200152000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
990100000f65100001000010f6510060100001000010f6512a6010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000100001465100001000010c65100001000010360103650000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
490100002c65100601006011b671146010d601006010b631006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
__music__
00 32797344
00 32797344
01 32333439
00 3233343a
00 32333439
00 3233343a
00 32337344
00 32337344
00 32333439
02 3233343a
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 32337970
01 32333930
02 32333a30
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 32797344
00 32797344
01 32333439
02 3233343a
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 32797344
00 32393304
01 32333439
02 3233343a
01 32333930
02 32333a30
03 35333436

