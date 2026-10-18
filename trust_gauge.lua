-- Awake: Trust-style EXP gauge motion study, Test 12.
-- Immediate creeping fill toward the white destination, subtle gain-edge sparkles,
-- arriving-white flash, and longer warm afterglow.
-- Text rendering stays in barfiller.lua and uses this gauge's single clock.
-- Original Trust textures: CyriteGameStudios/Trust, assets/backgrounds.
local images = require('images')
local gauge = {}
local methods = {}
methods.__index = methods

local function clamp(v) return math.max(0, math.min(1, v)) end
local function ease(v) v=clamp(v); return 1-(1-v)^3 end
local function gain_curve(v) v=clamp(v); return v*v*(3-2*v) end
local function cosine_out(v) return (1+math.cos(math.pi*clamp(v)))/2 end
local function valid_seconds(seconds)
    return type(seconds)=='number' and seconds==seconds and
        seconds~=math.huge and seconds~=-math.huge and seconds>=0
end
local function gaussian(t, center, radius)
    local distance=(t-center)/radius
    return math.exp(-0.5*distance*distance)
end
local function image(path)
    return images.new({pos={x=0,y=0},visible=false,size={width=1,height=16},
        color={alpha=255,red=255,green=255,blue=255},
        texture={path=path,fit=true},repeatable={x=1,y=1},draggable=false})
end

-- EXP fill creeps immediately; a separate level-up ramp reaches 100% first.
local GAIN_DURATION=5.5
local GAIN_WAIT=0.0
local LEVEL_DURATION=3.0
local EMBER_DURATION=16.0
-- Distinct pulses with room for longer bursts later in the celebration.
local LEVEL_PULSES={
    {.37,.024,.45}, {.46,.024,.55}, {.55,.023,.62},
    {.72,.038,.61}, {.88,.037,.71}, {1.04,.041,.79},
    {1.21,.045,.78}, {1.41,.055,.86}, {1.67,.065,.95},
    {2.05,.085,1.00}, {2.48,.112,1.00}
}

function gauge.new(base_path,color,clock)
    local self=setmetatable({base_path=base_path,color=color or 'blue',
        clock=clock or os.clock,x=0,y=0,width=420,scale=1,visible=false,known=false,
        value=0,target=0,drawn_value=0,duration=GAIN_DURATION,
        level_duration=LEVEL_DURATION,started=nil,flash_started=nil,
        level_started=nil,level_from=nil,level_to=nil,
        after_level_progress=nil,ember_started=nil,show_gain_sparkles=true,
        arrived_at=nil,upper_ghost_end=nil,level_spark_events={},
        arrival_duration=5.5,level_ramp_duration=2,level_trigger_at=nil,
        gain_glow_start=0,gain_glow_to_full=false,
        level_ramp_end=nil,opacity=1,pending_levels={}},methods)
    -- Primitive construction order determines the layers in Windower.
    self.left=image(base_path..'track_left.png')
    self.middle=image(base_path..'track_middle.png')
    self.right=image(base_path..'track_right.png')
    self.destination=image(base_path..'white_destination.png')
    self.fill=image(base_path..'fill_'..self.color..'.png')
    self.glow=image(base_path..'glow_'..self.color..'.png')
    self.glow_path=base_path..'glow_'..self.color..'.png'
    self.sweep=image(base_path..'sweep.png')
    self.stars={}
    for i=1,11 do self.stars[i]=image(base_path..'sparkle_cross.png') end
    -- Each glint is TWO overlapping arms with independently scalable lengths.
    -- The four glints reappear in staggered cycles; no objects are allocated
    -- during prerender, an important property for multibox Windower clients.
    self.gain_sparkles={}
    for i=1,4 do
        self.gain_sparkles[i]={
            h=image(base_path..'sparkle_gain_arm_h.png'),
            v=image(base_path..'sparkle_gain_arm_v.png'),
        }
    end
    self.level_sparkles={}
    for event=1,3 do
        self.level_sparkles[event]={}
        for i=1,5 do
            self.level_sparkles[event][i]={
                h=image(base_path..'sparkle_gain_arm_h.png'),
                v=image(base_path..'sparkle_gain_arm_v.png')
            }
        end
    end
    return self
end
function methods:reset()
    self.known=false
    self.value,self.target,self.drawn_value=0,0,0
    self.started,self.flash_started=nil,nil
    self.level_started,self.after_level_progress=nil,nil
    self.level_from,self.level_to,self.ember_started=nil,nil,nil
    self.arrived_at,self.upper_ghost_end=nil,nil
    self.gain_glow_start,self.gain_glow_to_full=0,false
    self.level_trigger_at,self.level_ramp_end=nil,nil
    self.level_spark_events={}
    self.pending_levels={}
end
function methods:move(x,y,width,scale)
    self.x,self.y=math.floor(x or self.x),math.floor(y or self.y)
    self.width=math.max(48, math.floor(width or self.width))
    self.scale=math.max(.5, math.min(2.25, tonumber(scale) or self.scale))
    self:draw()
end
function methods:set_color(color)
    if color~='blue' and color~='gold' then return end
    self.color=color
    self.fill:path(self.base_path..'fill_'..color..'.png')
    self:draw()
end
function methods:set_opacity(alpha) self.opacity=clamp(tonumber(alpha) or 1) end
function methods:set_arrival_duration(seconds)
    local value=tonumber(seconds)
    if valid_seconds(value) then self.arrival_duration=value end
end
function methods:set_level_ramp(seconds)
    local value=tonumber(seconds)
    if valid_seconds(value) then self.level_ramp_duration=value end
end
-- Reading the current brightness before an interrupted animation guarantees
-- continuity: a second EXP packet does not turn a glowing bar dark.
function methods:gain_glow_at(now)
    if self.started then
        local p=clamp((now-self.started)/self.duration)
        local start=self.gain_glow_start or 0
        local goal=self.gain_glow_to_full and 255 or 168
        return start+(goal-start)*p^.78
    end
    if self.arrived_at then
        if self.arrival_duration==0 then return 0 end
        local p=clamp((now-self.arrived_at)/self.arrival_duration)
        return 255*cosine_out(p)
    end
    return 0
end
function methods:animation_busy(now)
    now=now or self.clock()
    if self.started or self.arrived_at or self.level_started or self.upper_ghost_end then return true end
    if self.ember_started and self:caption_ember(now)>0 then return true end
    for _,event in ipairs(self.level_spark_events) do
        if now<event.ember_end+1.4 then return true end
    end
    return false
end
function methods:set_gain_sparkles(enabled)
    self.show_gain_sparkles=enabled and true or false
end
function methods:advance(now)
    if not self.started then return end
    local elapsed=now-self.started
    local t=clamp((elapsed-GAIN_WAIT)/(self.duration-GAIN_WAIT))
    self.value=self.from+(self.target-self.from)*gain_curve(t)
    if t>=1 then
        self.value,self.started=self.target,nil
        self.arrived_at=now -- The arrival flash begins at the reached destination.
    end
end
function methods:set_progress(progress,immediate)
    if type(progress)~='number' or progress~=progress then return end
    progress=clamp(progress)
    if self.level_started then
        -- Late EXP packet during level celebration: remember final fraction.
        self.after_level_progress=progress
        return
    end
    if not self.known or immediate then
        self.known=true
        self.value,self.target,self.started,self.flash_started=progress,progress,nil,nil
        self.arrived_at=nil
        self.gain_glow_start,self.gain_glow_to_full=0,false
        self.drawn_value=progress
        return
    end
    if math.abs(progress-self.target)<.000001 then return end
    local now=self.clock()
    self:advance(now)
    if progress>self.target then
        -- Carry the current opacity into the next gain. If the previous
        -- arrival is still cooling, let renewed EXP build toward full white
        -- without ever resetting to zero or stepping down to 66%.
        local carry=self:gain_glow_at(now)
        local was_cooling=self.arrived_at~=nil
        self.gain_glow_start=carry
        self.gain_glow_to_full=(self.gain_glow_to_full or was_cooling) and carry>0
        self.arrived_at=nil
        -- Interruptions must NOT restart the multi-second anticipation.
        -- Otherwise frequent EXP gains would leave the displayed fill frozen.
        if self.started then
            if now-self.started>=GAIN_WAIT then
                -- Already moving: continue immediately toward the new total
                -- from the CURRENT visible fraction, with no jump backwards.
                self.from=self.value
                self.started=now-GAIN_WAIT
            end
            self.target=progress
        else
            self.from,self.target,self.started=self.value,progress,now
            self.flash_started=now
        end
    else
        -- Losing EXP / switching jobs should never look like taking damage.
        self.value,self.target,self.started,self.flash_started=progress,progress,nil,nil
        self.arrived_at=nil
        self.gain_glow_start,self.gain_glow_to_full=0,false
        self.drawn_value=progress
    end
end
function methods:level_up(from_level,to_level,delay)
    if self.level_started then
        -- Preserve genuine consecutive levels instead of dropping the second
        -- celebration. The packet bridge still needs live validation.
        if #self.pending_levels<3 then
            table.insert(self.pending_levels,{from=from_level,to=to_level,delay=delay})
        end
        return
    end
    local now=self.clock()
    self:advance(now)
    self.level_origin=self.value
    self.level_trigger_at=now
    local ramp=math.max(0,self.level_ramp_duration-.15)
    self.level_ramp_end=now+ramp+math.max(0,tonumber(delay) or 0)
    self.level_started=self.level_ramp_end+.15
    self.level_from,self.level_to=from_level,to_level
    self.after_level_progress=nil
    self.ember_started=self.level_started+.6
    table.insert(self.level_spark_events,{start=self.level_started+1.67,
        ember_end=self.level_started+self.level_duration+EMBER_DURATION,
        level=to_level})
    while #self.level_spark_events>3 do table.remove(self.level_spark_events,1) end
    self.upper_ghost_end=self.level_started+self.level_duration
    self.started,self.flash_started,self.arrived_at=nil,nil,nil
    self.gain_glow_start,self.gain_glow_to_full=0,false
end
function methods:level_active() return self.level_started~=nil end
function methods:level_age(now)
    return self.level_started and (now or self.clock())-self.level_started or nil
end
function methods:level_revealed(now)
    local age=self:level_age(now)
    return age and age>=1.67 or false
end
function methods:level_intensity(now)
    local age=self:level_age(now)
    if not age or age<0 or age>=self.level_duration then return 0 end
    local peak=0
    for _,pulse in ipairs(LEVEL_PULSES) do
        peak=math.max(peak,pulse[3]*gaussian(age,pulse[1],pulse[2]))
    end
    return clamp(peak)
end
-- Separate two-second ghost tail: the old code stopped at three seconds,
-- abruptly hiding JOB/Lv/% glow even while the lower captions were warming.
-- Begin the support glow before the pulse clock ends for continuity.
function methods:upper_ghost_tail(now)
    if not self.upper_ghost_end then return 0 end
    local t=(now or self.clock())-self.upper_ghost_end
    if t < -.8 then return 0 end
    if t < 0 then return .28*ease((t+.8)/.8) end
    if t >= 2 then self.upper_ghost_end=nil; return 0 end
    return .28*(1-ease(t/2))
end
function methods:caption_ember(now)
    if not self.ember_started then return 0 end
    local elapsed=(now or self.clock())-self.ember_started
    if elapsed<0 then return 0 end
    -- Hold the pale highlight through the level celebration itself.
    elapsed=math.max(0, elapsed-(self.level_duration-.6))
    if elapsed>=EMBER_DURATION then self.ember_started=nil;return 0 end
    -- Long AFTERGLOW following the full celebration, even if XP arrives.
    return (1-elapsed/EMBER_DURATION)^1.25
end
function methods:show()
    self.visible=true
    self:draw() -- Reassert all sizes after asynchronous texture loading.
end
function methods:hide()
    self.visible=false
    for _,v in ipairs({self.left,self.middle,self.right,self.destination,
        self.fill,self.glow,self.sweep}) do v:hide() end
    for _,v in ipairs(self.stars) do v:hide() end
    for _,v in ipairs(self.gain_sparkles) do v.h:hide(); v.v:hide() end
    for _,group in ipairs(self.level_sparkles) do
        for _,v in ipairs(group) do v.h:hide();v.v:hide() end
    end
end
function methods:draw()
    local now=self.clock()
    self:advance(now)
    local age=self:level_age(now)
    if age and age>=self.level_duration then
        -- New level begins empty, then fills naturally to leftover EXP.
        local next_progress=clamp(self.after_level_progress or 0)
        self.level_started,self.after_level_progress=nil,nil
        self.level_trigger_at,self.level_ramp_end=nil,nil
        self.value,self.target,self.drawn_value=0,0,0
        self.started,self.flash_started=nil,nil
        self.known=true
        if next_progress>0 then self:set_progress(next_progress) end
        age=nil
        if #self.pending_levels>0 then
            local queued=table.remove(self.pending_levels,1)
            self:level_up(queued.from,queued.to,queued.delay)
            age=self:level_age(now)
        end
    end
    local x,y,w=self.x,self.y,self.width
    local scale=self.scale
    local cap=math.floor(8*scale+.5)
    local ht=math.floor(16*scale+.5)
    local inner=w-2*cap
    self.left:pos(x,y);self.left:size(cap,ht)
    self.middle:pos(x+cap,y);self.middle:size(inner,ht)
    self.right:pos(x+w-cap,y);self.right:size(cap,ht)

    local fraction=self.value
    local pending=age and age<0
    if pending and self.level_trigger_at and self.level_ramp_end then
        local span=self.level_ramp_end-self.level_trigger_at
        local ramp_t=span<=0 and 1 or clamp((now-self.level_trigger_at)/span)
        fraction=self.level_origin+(1-self.level_origin)*gain_curve(ramp_t)
    elseif age and age>=0 then
        -- The ramp has ALREADY reached full before the celebration begins;
        -- don't jump backward to level_origin at the first gold-label frame.
        fraction=1
    end
    self.drawn_value=clamp(fraction)
    local fill_width=math.floor(inner*self.drawn_value+.5)
    local destination_width=math.floor(inner*self.target+.5)
    if age then destination_width=inner end
    self.destination:pos(x+cap,y)
    self.destination:size(math.max(1,destination_width),ht)
    self.fill:pos(x+cap,y)
    self.fill:size(math.max(1,fill_width),ht)
    self.glow:pos(x+cap,y)
    self.glow:size(math.max(1,age and inner or fill_width),ht)

    local glow_alpha=0
    if age then
        local path=self.base_path..'glow_gold.png'
        if self.glow_path~=path then self.glow:path(path);self.glow_path=path end
        local release=0
        if self.level_ramp_end and now>=self.level_ramp_end then
            release=255*(1-ease((now-self.level_ramp_end)/.52))
        end
        if pending then
            local span=self.level_ramp_end-self.level_trigger_at
            local approach=span<=0 and 1 or clamp((now-self.level_trigger_at)/span)
            glow_alpha=math.floor(math.max(168*approach^.78,release)+.5)
        else
            glow_alpha=math.floor(math.max(245*self:level_intensity(now),release)+.5)
        end
    else
        local path=self.base_path..'glow_'..self.color..'.png'
        if self.glow_path~=path then self.glow:path(path);self.glow_path=path end
        if self.started or self.arrived_at then
            -- The first gain builds to 66%; a subsequent gain during the
            -- arrival fade resumes from the visible opacity toward white.
            glow_alpha=math.floor(self:gain_glow_at(now)+.5)
            if self.arrived_at and (self.arrival_duration==0 or
                now-self.arrived_at>=self.arrival_duration) then
                self.arrived_at=nil
            end
        end
        if self.flash_started and now-self.flash_started>=self.duration then
            self.flash_started=nil
        end
    end
    local visual=self.opacity
    if age then
        self.destination:alpha(math.floor(230*visual+.5))
    elseif self.started then
        local p=clamp((now-self.started)/3.9)
        self.destination:alpha(math.floor(210*ease(p)*visual+.5))
    else
        self.destination:alpha(0)
    end
    self.left:alpha(math.floor(255*visual+.5))
    self.middle:alpha(math.floor(255*visual+.5))
    self.right:alpha(math.floor(255*visual+.5))
    self.fill:alpha(math.floor(255*visual+.5))
    self.glow:alpha(math.floor(glow_alpha*visual+.5))
    self.left:visible(self.visible)
    self.middle:visible(self.visible)
    self.right:visible(self.visible)
    self.destination:visible(self.visible and destination_width>fill_width and
        (self.started~=nil or age~=nil))
    self.fill:visible(self.visible and fill_width>0)
    self.glow:visible(self.visible and glow_alpha>0)

    -- EXP glints, now drifting LEFT behind the advancing gold edge.
    -- The original vertical bob and staggered sine alpha are preserved.
    -- 3/4 lengthen horizontally; 1/4 lengthens vertically. Each stretches
    -- while dissolving, so no springy return or size wobble is visible.
    local gain_sparkle_time=nil
    local sparkle_arrival_fade=1
    if not age then
        if self.started and self.target>self.value then
            gain_sparkle_time=clamp((now-self.started)/self.duration)
        elseif self.arrived_at then
            local linger=now-self.arrived_at
            if linger>=0 and linger<.52 then
                -- Let already-visible specks settle after the bar arrives.
                gain_sparkle_time=1+linger/self.duration
                sparkle_arrival_fade=cosine_out(linger/self.arrival_duration)
            end
        end
    end
    for i,glint in ipairs(self.gain_sparkles) do
        local active=self.visible and self.show_gain_sparkles and
            gain_sparkle_time~=nil and fill_width>0
        if active then
            local phase=(gain_sparkle_time*3.6+i*.31)%1
            local envelope=math.max(0,math.sin(phase*math.pi))^1.3
            local alpha=math.floor(250*envelope*sparkle_arrival_fade+.5)
            active=alpha>0
            if active then
                local base_x=x+cap+fill_width+math.floor((i-2.5)*3.5*scale)
                -- Newly born at the front, older glints peel away leftward.
                local cx=base_x-math.floor(29*scale*phase+.5)
                local cy=y+math.floor(ht/2+math.sin(gain_sparkle_time*9+i*2)*4*scale)
                local stretch=ease(phase)
                local vertically=(i%4)==0
                local length_long=math.floor((15+19*stretch)*math.max(.9,scale)+.5)
                local length_short=math.floor((8+4*stretch)*math.max(.9,scale)+.5)
                local hw=vertically and length_short or length_long
                local vh=vertically and length_long or length_short
                -- Two sprites maintain a hairline center, with a faint halo
                -- baked into the PNG assets rather than extra draw objects.
                local line_thickness=math.max(3,math.floor(3*scale+.5))
                glint.h:pos(cx-math.floor(hw/2),cy-math.floor(line_thickness/2))
                glint.h:size(math.max(1,hw),line_thickness)
                glint.h:alpha(math.floor(alpha*visual+.5))
                glint.v:pos(cx-math.floor(line_thickness/2),cy-math.floor(vh/2))
                glint.v:size(line_thickness,math.max(1,vh))
                glint.v:alpha(math.floor(alpha*visual+.5))
            end
        end
        glint.h:visible(active and true or false)
        glint.v:visible(active and true or false)
    end

    -- A horizontal bright sweep over the actual gauge, not above it.
    local sweep_active=age and age>=.24 and age<=2.68
    if sweep_active then
        local progress=clamp((age-.24)/2.44)
        local sweep_width=math.floor(44*scale+.5)
        local sx=x+cap+math.floor((inner-sweep_width)*progress)
        self.sweep:pos(sx,y)
        self.sweep:size(sweep_width,ht)
        self.sweep:alpha(math.floor(235*math.sin(progress*math.pi)^.45*visual+.5))
    end
    self.sweep:visible(self.visible and sweep_active or false)

    -- Placeholder star sprites until native FFXI level-up assets are sourced.
    local flash=self:level_intensity(now)
    for i,star in ipairs(self.stars) do
        local start=LEVEL_PULSES[i][1]-.06
        local lifetime=.48
        local p=age and clamp((age-start)/lifetime) or 0
        local active=age and age>=start and age<start+lifetime
        if active then
            local relative=.12+.76*((i*37)%101)/101
            local yy=y+ht/2+math.sin(i*3.1+p*math.pi)*5*scale
            local size=math.max(2,math.floor((9+10*(1-p))*scale))
            star:pos(x+cap+math.floor(inner*relative),math.floor(yy-size/2))
            star:size(size,size)
            local glow=math.max(.28,flash)
            star:alpha(math.floor(220*glow*math.sin(p*math.pi)*visual+.5))
        end
        star:visible(self.visible and active or false)
    end
end
-- Level-number glints use a different clock from EXP gain and the next
-- level celebration. Keep active until the ember completely cools, then fade.
function methods:draw_level_sparkles(cx,cy,level,ember,scale)
    local now=self.clock()
    -- Prune finished effects without touching newer celebrations.
    while self.level_spark_events[1] and
        now>=self.level_spark_events[1].ember_end+1.4 do
        table.remove(self.level_spark_events,1)
    end
    for event_index,group in ipairs(self.level_sparkles) do
        local event=self.level_spark_events[event_index]
        local age=event and (now-event.start) or -1
        local active=event and age>=0 and now<event.ember_end+1.4
        local fade=1
        if active and now>event.ember_end then
            fade=1-ease((now-event.ember_end)/1.4)
        end
        for i,glint in ipairs(group) do
            local show=active and fade>0
            if show then
                local phase=(age*.54+i*.217)%1
                local pulse=math.sin(phase*math.pi)^1.1
                local alpha=math.floor(245*pulse*fade+.5)
                local spread=math.max(12,math.floor((12+#tostring(event.level)*4)*scale))
                local xx=cx+math.floor(spread*((i*31)%7)/7+.5)-3
                local yy=cy+math.floor(math.sin(age*1.5+i*2.1)*5*scale+.5)
                local stretch=ease(phase)
                local horizontal=i%4~=0
                local longer=math.floor((13+16*stretch)*math.max(.9,scale)+.5)
                local shorter=math.floor((7+3*stretch)*math.max(.9,scale)+.5)
                local w=horizontal and longer or shorter
                local h=horizontal and shorter or longer
                local th=math.max(3,math.floor(3*scale+.5))
                glint.h:pos(xx-math.floor(w/2),yy-math.floor(th/2))
                glint.h:size(w,th);glint.h:alpha(math.floor(alpha*self.opacity+.5))
                glint.v:pos(xx-math.floor(th/2),yy-math.floor(h/2))
                glint.v:size(th,h);glint.v:alpha(math.floor(alpha*self.opacity+.5))
                show=alpha>0
            end
            glint.h:visible(show and true or false)
            glint.v:visible(show and true or false)
        end
    end
end
function methods:destroy()
    for _,v in ipairs({self.left,self.middle,self.right,self.destination,
        self.fill,self.glow,self.sweep}) do v:destroy() end
    for _,v in ipairs(self.stars) do v:destroy() end
    for _,v in ipairs(self.gain_sparkles) do v.h:destroy(); v.v:destroy() end
    for _,group in ipairs(self.level_sparkles) do
        for _,v in ipairs(group) do v.h:destroy();v.v:destroy() end
    end
end
return gauge
