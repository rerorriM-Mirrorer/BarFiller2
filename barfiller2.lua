--[[    BSD License Disclaimer
        Copyright © 2015, Morath86
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of BarFiller nor the names of its contributors
              may be used to endorse or promote products derived from this
              software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
        ARE DISCLAIMED. IN NO EVENT SHALL Morath86 BE LIABLE FOR ANY DIRECT,
        INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
        SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
        HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
        STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
        IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
        POSSIBILITY OF SUCH DAMAGE.

        Skin-test adaptation and draggable layout by Awake, October 2026.
]]
_addon.name='BarFiller2'
_addon.author='Morath86; BarFiller2 additions: Awake'
_addon.version='0.2.12-bf2-complete1'
_addon.commands={'bf','bf2','barfiller2'}
_addon.language='english'

config=require('config')
file=require('files')
packets=require('packets')
texts=require('texts')
images=require('images')
require('statics') -- bundled stock-compatible EXP counters and legacy configuration
local chat=require('chat')
local TrustGauge=require('trust_gauge')
local NativeDigits=require('native_digits')
local LevelArt=require('level_art')

-- BarFiller2 reads its own config and ships with all necessary support files.
-- Existing BarFiller preferences can be copied manually when desired; no migration
-- script or reads/writes to the original BarFiller directory are required.
defaults.TrustSkin={Color='gold'}
defaults.TrustLayout={X=-1,Y=20,Width=420,Edit=true,Locked=false,Scale=1,
    LevelStyle='hybrid',ShowTNL=false,ShowRate=false,LevelDelay=0,GoldLabel=true,GainSparkles=true,LevelDigits='text',Test9DefaultsApplied=false,
    ArrivalFade=5.5,LevelRamp=2,LevelPresentation='goldonly',
    AutoHide=true,HideSeconds=60,JobBold=false,LevelFontSize=15,
    ScaleProfile='compact',Test11DefaultsApplied=false,Test12DefaultsApplied=false}
settings=config.load(defaults)
settings.TrustSkin=settings.TrustSkin or {Color='gold'}
settings.TrustLayout=settings.TrustLayout or {}
local layout=settings.TrustLayout
for k,v in pairs(defaults.TrustLayout) do
    if layout[k]==nil then layout[k]=v end
end
-- One-time Test 9 preset migration: existing Test 8 settings.xml may still
-- retain earlier experimental choices. Establish this requested default once,
-- then preserve any user toggles and font choices on future reloads.
if layout.Test9DefaultsApplied~=true then
    layout.LevelDigits='text'
    layout.GoldLabel=true
    layout.GainSparkles=true
    layout.LevelStyle='hybrid'
    layout.Test9DefaultsApplied=true
end
if layout.LevelDigits~='native' and layout.LevelDigits~='text' then
    layout.LevelDigits='text'
end
-- One-time Test 11 migration. Preserve physical widget size on upgrade;
-- 1.0 compact means the old 0.75 scale, without unexpectedly shrinking
-- anyone already playing at .7/.75/.8 when this ZIP is installed.
if layout.Test11DefaultsApplied~=true then
    local old=tonumber(layout.Scale) or 1
    layout.Scale=math.max(.65,math.min(8/3,old/.75))
    layout.ScaleProfile='compact'
    layout.LevelPresentation='goldonly'
    layout.Test11DefaultsApplied=true
end
-- The 5.5-second duration and other approved choices replace Test 11's
-- experimental defaults once. Subsequent saved user choices are preserved.
if layout.Test12DefaultsApplied~=true then
    layout.ArrivalFade=5.5
    if tonumber(layout.LevelRamp)==.85 then layout.LevelRamp=2 end
    if layout.JobBold==true then layout.JobBold=false end
    if tonumber(layout.LevelFontSize)==13 then layout.LevelFontSize=15 end
    if settings.TrustSkin.Color=='blue' then settings.TrustSkin.Color='gold' end
    layout.Test12DefaultsApplied=true
end
if settings.TrustSkin.Color~='blue' and settings.TrustSkin.Color~='gold' then
    settings.TrustSkin.Color='gold'
end
-- Imported settings may contain absolute paths to the STOCK BarFiller textures.
-- Retarget only known stock asset paths; preserve any unrelated custom image paths.
for key,filename in pairs({Background='bar_bg.png',Foreground='bar_fg.png',RestedBonus='moon.png'}) do
    local texture=settings.Images and settings.Images[key] and settings.Images[key].Texture
    if texture and type(texture.Path)=='string' then
        local path=texture.Path:lower():gsub('\\','/')
        if path:find('/barfiller/',1,true) and path:sub(-#filename)==filename then
            texture.Path=windower.addon_path..filename
        end
    end
end
-- Controller-first: dragging is available by default; explicit //bf lock persists.
layout.Edit=not layout.Locked
config.save(settings)

background_image=images.new(settings.Images.Background)
foreground_image=images.new(settings.Images.Foreground)
rested_bonus_image=images.new(settings.Images.RestedBonus)
exp_text=texts.new(settings.Texts.Exp)
local gauge=TrustGauge.new(windower.addon_path..'assets/slider/',settings.TrustSkin.Color)
local native=NativeDigits.new(windower.addon_path..'assets/native/')
local level_art=LevelArt.new(windower.addon_path..'assets/native/')
gauge:set_gain_sparkles(layout.GainSparkles)
gauge:set_arrival_duration(layout.ArrivalFade)
gauge:set_level_ramp(layout.LevelRamp)
ready=false
chunk_update=false
debug=false
local old_initialize=initialize
local old_hide=hide
local old_show=show
local x,y=0,20
local width=420
local scale=1
local widget_opacity=1
local last_stroke_step=nil
local last_frame=nil
local last_activity=os.clock()
local manually_hidden=false
local last_job,last_level,last_actual_level=nil,nil,nil
local waiting_new_level_packet=false
local preview_until=0
local preview_state=nil
local level_before_total=nil
local pending_save=nil
local flash_previous={job=0,pct=0,level=0}
local flash_drift={job=0,pct=0,level=0}

local function say(s) windower.add_to_chat(8,'BarFiller2: '..s) end
local function ui_dimensions()
    local s=windower.get_windower_settings() or {}
    return tonumber(s.ui_x_res or s.x_res) or 800,tonumber(s.ui_y_res or s.y_res) or 600
end
local function bound(v,lower,upper) return math.max(lower,math.min(upper,v)) end
local function nonnegative_finite(value)
    return type(value)=='number' and value==value and
        value~=math.huge and value~=-math.huge and value>=0
end
local function comma(n)
    local a=tostring(math.max(0,math.floor(tonumber(n) or 0)))
    return (a:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,',''))
end
local function make_text(size,right,red,green,blue,bold,italic)
    return texts.new('',{
        pos={x=0,y=0},padding=0,bg={visible=false,alpha=0},
        flags={right=right or false,bottom=false,bold=bold or false,
               italic=italic or false,draggable=false},
        text={font='Arial',fonts={'Arial','Verdana'},size=size,
              red=red,green=green,blue=blue,alpha=255,
              stroke={width=1,alpha=220,red=12,green=11,blue=14}}
    })
end
local job_text=make_text(12,false,255,249,235,true,true)
-- JOB/SUB can be unbolded independently of the Lv. prefix and level number.
local lv_prefix_text=make_text(12,false,255,249,235,true,true)
local lv_flash_text=make_text(12,false,255,255,250,true,true)
local lv_echo_text=make_text(12,false,255,255,250,true,true)
job_text:bold(layout.JobBold)
-- LevelDigits='text' restores the same rendered Arial bold italic digits as
-- JOB/SUB Lv. while preserving the old/new number crossfade and white veils.
local level_digits_text=make_text(12,false,255,249,235,true,true)
local level_digit_flash=make_text(12,false,255,255,250,true,true)
local level_digit_echo=make_text(12,false,255,255,250,true,true)
local level_digit_veil=make_text(12,false,255,255,250,true,true)
local level_old_text=make_text(12,false,255,249,235,true,true)
local level_old_echo=make_text(12,false,255,255,250,true,true)
for _,t in ipairs({level_digit_flash,level_digit_echo,level_digit_veil,
                    level_old_echo}) do
    t:stroke_width(1)
    t:stroke_color(247,247,239)
    t:stroke_alpha(85)
    t:alpha(0); t:hide()
end
level_old_text:stroke_width(1)
level_old_text:stroke_color(232,221,200)
level_old_text:stroke_alpha(35)
level_old_text:alpha(0);level_old_text:hide() -- luminous previous-level copy

local pct_text=make_text(12,true,255,249,235,true,true)
local exp_total_text=make_text(10,true,189,152,98,false,false)
local extra_text=make_text(10,false,174,139,88,false,false)
local level_text=make_text(14,false,255,249,220,true,false)
level_text:font('Times New Roman','Georgia','Times')
level_text:italic(false)
level_text:stroke_width(2)
level_text:stroke_color(89,70,40)
local level_under=images.new({pos={x=0,y=0},visible=false,
    size={width=1,height=1},color={alpha=255,red=255,green=249,blue=220},
    texture={path=windower.addon_path..'assets/slider/white_destination.png',fit=true},
    repeatable={x=1,y=1},draggable=false})
-- The level numeral is separate from JOB/SUB so it can grow around its center.

local exp_glow_text=make_text(10,true,255,254,248,false,false)
local extra_glow_text=make_text(10,false,255,254,248,false,false)
local drag_text=make_text(10,false,255,230,174,true,false)
-- Additional lightly blurred-looking text strokes, laid over the original text.
-- Their alpha is driven from the same motion clock as the bar.
local job_flash_text=make_text(12,false,255,255,250,true,true)
local job_echo_text=make_text(12,false,255,255,250,true,true)
job_flash_text:bold(layout.JobBold)
job_echo_text:bold(layout.JobBold)
local pct_flash_text=make_text(12,true,255,255,250,true,true)
local pct_echo_text=make_text(12,true,255,255,250,true,true)
-- Less-heavy alpha ghosts. Upper-left strongest, percentage narrower,
-- captions have roughly half the upper glow stroke opacity.
for _,t in ipairs({job_flash_text,job_echo_text,lv_flash_text,lv_echo_text,
                    pct_flash_text,pct_echo_text,exp_glow_text,extra_glow_text}) do
    local caption=(t==exp_glow_text or t==extra_glow_text)
    t:stroke_width(caption and 1 or (t==job_flash_text and 2 or 1))
    t:stroke_color(247,247,237)
    t:stroke_alpha(caption and 65 or (t==pct_flash_text and 110 or 125))
    t:alpha(0)
end
level_text:text('Level Up!!')


local function labels_visible(visible)
    -- Crisp rendered JOB/SUB Lv. and percent; genuine DAT digits only.
    job_text:visible(visible)
    lv_prefix_text:visible(visible)
    pct_text:visible(visible);exp_total_text:visible(visible)
    if visible and layout.LevelDigits=='native' then native:show()
    else native:hide() end
    if visible then level_art:show() else level_art:hide() end
    level_digits_text:visible(visible and layout.LevelDigits=='text')
    for _,t in ipairs({level_digit_flash,level_digit_echo,level_digit_veil,
        level_old_text,level_old_echo}) do t:visible(false) end
    extra_text:visible(visible and (layout.ShowTNL or layout.ShowRate))
    level_text:hide()
    drag_text:hide()
    for _,t in ipairs({job_flash_text,job_echo_text,lv_flash_text,lv_echo_text,
        pct_flash_text,pct_echo_text,exp_glow_text,extra_glow_text}) do t:visible(false) end
    level_under:hide()
end
local function positioning()
    local res_x,res_y=ui_dimensions()
    local max_user_scale=layout.ScaleProfile=='compact' and 8/3 or 2
    local user_scale=bound(tonumber(layout.Scale) or 1,.65,max_user_scale)
    scale=user_scale*(layout.ScaleProfile=='compact' and .75 or 1)
    width=bound(math.floor((tonumber(layout.Width) or 420)*scale+.5),
        math.floor(140*scale),math.max(math.floor(140*scale),res_x))
    if tonumber(layout.X)==nil or tonumber(layout.X)<0 then
        x=math.floor((res_x-width)/2)
    else
        x=bound(math.floor(layout.X),0,math.max(0,res_x-width))
    end
    y=bound(math.floor(tonumber(layout.Y) or 20),13,math.max(13,res_y-52*scale))
    gauge:move(x,y,width,scale)
    -- Scale all regular text, too. The native pixels use their own
    -- atlas scale multiplied by this global widget scale.
    for _,entry in ipairs({
        {job_text,12},{lv_prefix_text,12},{pct_text,12},{exp_total_text,10},{extra_text,10},
        {level_digits_text,layout.LevelFontSize},{level_digit_flash,layout.LevelFontSize},
        {level_digit_echo,layout.LevelFontSize},{level_digit_veil,layout.LevelFontSize},
        {level_old_text,layout.LevelFontSize},{level_old_echo,layout.LevelFontSize},
        {level_text,14},{exp_glow_text,10},{extra_glow_text,10},{drag_text,10},
        {job_flash_text,12},{job_echo_text,12},{lv_flash_text,12},
        {lv_echo_text,12},{pct_flash_text,12},
        {pct_echo_text,12}}) do
        entry[1]:size(math.max(7,math.floor(entry[2]*scale+.5)))
    end
    job_text:pos(x+math.floor(8*scale+.5),y-math.floor(11*scale)) -- Level prefix and digits are placed after measured text in render_labels.
    -- Windower texts.flags.right anchors X relative to the screen's right
    -- edge, not the widget. Supply a negative screen-relative coordinate.
    pct_text:pos(x+width-math.floor(7*scale)-res_x,y-math.floor(11*scale))
    exp_total_text:pos(x+width-math.floor(7*scale)-res_x,y+math.floor(17*scale))
    extra_text:pos(x+math.floor(8*scale),y+math.floor(17*scale))
    -- Crisp serif Level Up!! belongs ON the gauge, not above it.
    level_text:pos(x+math.floor(width/2)-35,y-5)
    drag_text:pos(x+math.floor(8*scale),y+math.floor(37*scale))
    job_flash_text:pos(x+math.floor(8*scale+.5),y-math.floor(11*scale))
    job_echo_text:pos(x+math.floor(8*scale+.5),y-math.floor(11*scale))
    pct_flash_text:pos(x+width-math.floor(7*scale)-res_x,y-math.floor(11*scale))
    pct_echo_text:pos(x+width-math.floor(7*scale)-res_x,y-math.floor(11*scale))
    exp_glow_text:pos(x+width-math.floor(7*scale)-res_x,y+math.floor(17*scale))
    extra_glow_text:pos(x+math.floor(8*scale),y+math.floor(17*scale))
    -- Retain the original rested-bonus icon, anchored to the new widget.
    rested_bonus_image:pos(x+width+math.floor(3*scale),y-math.floor(7*scale))
    local rested_size=(settings.Images.RestedBonus and settings.Images.RestedBonus.Size) or {}
    rested_bonus_image:size(
        math.max(1,math.floor((tonumber(rested_size.Width) or 32)*scale+.5)),
        math.max(1,math.floor((tonumber(rested_size.Height) or 32)*scale+.5)))
end
local function arrange_at(nx,ny)
    local res_x,res_y=ui_dimensions()
    local new_x=bound(math.floor(nx+.5),0,math.max(0,res_x-width))
    local new_y=bound(math.floor(ny+.5),13,math.max(13,res_y-52*scale))
    layout.X,layout.Y=new_x,new_y
    positioning()
    pending_save=os.clock()+.6 -- save after movement settles, not every frame
end
-- The handle is a secondary drag region. The bar track itself is also
-- draggable in edit mode, and its new position is sampled before each draw.
drag_text:draggable(false)
drag_text:register_event('drag',function(_,new_x,new_y)
    if not layout.Edit then return end
    arrange_at(new_x-math.floor(8*scale),new_y-math.floor(37*scale))
end)
local function set_edit(enabled)
    layout.Edit=enabled and true or false
    layout.Locked=not layout.Edit
    gauge.middle:draggable(layout.Edit)
    drag_text:draggable(false)
    labels_visible(ready)
    config.save(settings);pending_save=nil
    say(layout.Edit and 'dragging ON; //bf move toggles it, //bf lock disables.'
                    or 'dragging OFF; position saved. //bf move to enable.')
end
-- Update the underlying character/level identity, independently from the
-- visible numbers. All animated readouts are produced AFTER the gauge draws.
-- Effective level changes with Level Sync; the jobs table is expected to
-- contain permanent levels. Confirm this on a synced client before relying
-- on it fully. This guard avoids celebrating the sync host's cap increase.
local function permanent_level(info)
    local abbr=type(info.main_job)=='string' and info.main_job:upper() or ''
    return type(info.jobs)=='table' and tonumber(info.jobs[abbr]) or nil
end
local function update_labels()
    local info=windower.ffxi.get_player()
    if not info then return end
    local job=tostring(info.main_job or '---'):upper()
    local effective=tonumber(info.main_job_level) or 0
    local actual=permanent_level(info)
    if last_job==job and last_actual_level and actual
        and actual>last_actual_level then
        level_before_total=tonumber(xp.total) or 0
        gauge:level_up(last_actual_level,actual,layout.LevelDelay)
        waiting_new_level_packet=true
    end
    last_job,last_level,last_actual_level=job,effective,actual
end
local function put_text(t,value)
    if t:text()~=value then t:text(value) end
end
local function mix(c,target,p)
    return math.floor(c+(target-c)*bound(p,0,1)+.5)
end
local function measured(t,fallback)
    if t.extents then
        local ok,w=pcall(function() return t:extents() end)
        if ok and tonumber(w) and w>0 then return w end
    end
    return fallback
end
local function render_labels(now)
    if not ready then return end
    local info=windower.ffxi.get_player()
    if not info then return end
    local job=tostring(info.main_job or '---'):upper()
    local sub=info.sub_job and tostring(info.sub_job):upper() or nil
    local level=tonumber(info.main_job_level) or 0
    local age=gauge:level_age(now)
    local shown_fraction=gauge.drawn_value or 0
    local total=tonumber(xp.total) or 0
    local real_level=level
    if preview_state and preview_state.kind=='label' then
        job,sub,level='WAR','NIN',21
    end
    if preview_state then
        if preview_state.kind=='gain' then
            total=10000
        elseif preview_state.kind=='level' then
            total=age and 10000 or 12000
            level=age and preview_state.from or preview_state.to
        end
    end
    if age then
        if not preview_state then total=level_before_total or total end
        level=gauge:level_revealed(now) and (gauge.level_to or real_level)
              or (gauge.level_from or real_level)
    end
    local display_exp=math.floor(shown_fraction*total+.5)
    local pct=total>0 and string.format('%.1f%%',shown_fraction*100) or '--%'
    local identity=job..(sub and ('/'..sub) or '')
    local title=identity..' Lv.'
    put_text(job_text,identity)
    put_text(lv_prefix_text,' Lv.')
    put_text(pct_text,pct)
    put_text(job_flash_text,identity)
    put_text(job_echo_text,identity)
    put_text(lv_flash_text,' Lv.')
    put_text(lv_echo_text,' Lv.')
    put_text(pct_flash_text,pct)
    put_text(pct_echo_text,pct)
    put_text(exp_total_text,total>0 and
        (comma(display_exp)..' / '..comma(total)..' EXP') or 'EXP -- / --')
    local parts={}
    if layout.ShowTNL then
        parts[#parts+1]=comma(math.max(0,total-display_exp))..' TNL'
    end
    if layout.ShowRate then
        parts[#parts+1]=string.format('%.1fk EXP/hr',(tonumber(xp.rate) or 0)/1000)
    end
    put_text(extra_text,table.concat(parts,'   ·   '))
    extra_text:visible(ready and #parts>0)
    -- These second copies always hold the CURRENT values even as their
    -- independent ten-second afterglow decays around later EXP gains.
    put_text(exp_glow_text,exp_total_text:text())
    put_text(extra_glow_text,extra_text:text())

    -- Shared light clock: crisp title plus native digit sprites; percentage
    -- remains regular rendered text with thinner pale ghost copies.
    local level_flash=gauge:level_intensity(now)
    local normal_flash=0
    if gauge.flash_started then
        normal_flash=1-bound((now-gauge.flash_started)/gauge.duration,0,1)
    end
    local tail=gauge:upper_ghost_tail(now)
    -- Save JOB and LEVEL ghost flashes for actual level-ups. Ordinary gains
    -- get only the percent shimmer, not distracting white copies of the title.
    local job_brightness=math.max(level_flash,tail)
    local pct_brightness=math.max(level_flash,tail)
    local function drift(key,intensity)
        local previous=flash_previous[key] or 0
        if intensity>previous+.0001 or intensity<=.001 then
            flash_drift[key]=0 -- rise always starts at original position
        elseif intensity<previous-.0001 then
            flash_drift[key]=math.floor(2*scale*(1-intensity)+.5)
        end
        flash_previous[key]=intensity
        return flash_drift[key] or 0
    end
    local job_drift=drift('job',job_brightness)
    local left_anchor=x+math.floor(8*scale+.5)
    local prefix_x=left_anchor+math.floor(measured(job_text,#identity*7*scale)+.5)
    lv_prefix_text:pos(prefix_x,y-math.floor(11*scale))
    lv_prefix_text:color(255,mix(249,255,job_brightness*.42),
        mix(235,255,job_brightness*.55))
    local pct_drift=drift('pct',pct_brightness)
    job_text:color(255,mix(249,255,job_brightness*.42),mix(235,255,job_brightness*.55))
    pct_text:color(255,mix(249,255,pct_brightness),mix(235,255,pct_brightness))
    local res_x=ui_dimensions()
    local pct_anchor=x+width-math.floor(7*scale)-res_x
    job_flash_text:pos(x+math.floor(8*scale+.5),y-math.floor(11*scale)-job_drift)
    local job_flash_alpha=math.floor(186*job_brightness+.5)
    job_flash_text:alpha(math.floor(job_flash_alpha*widget_opacity+.5))
    job_flash_text:visible(ready and job_flash_alpha>0)
    lv_flash_text:pos(prefix_x,y-math.floor(11*scale)-job_drift)
    lv_flash_text:alpha(math.floor(job_flash_alpha*widget_opacity+.5))
    lv_flash_text:visible(ready and job_flash_alpha>0)
    -- Additional light copies glide at a different rate, rejoining the
    -- crisp base exactly when the next flash begins rising.
    job_echo_text:pos(x+math.floor(8*scale+.5),y-math.floor(11*scale)-math.floor(job_drift*.55+.5))
    local job_echo_alpha=math.floor(105*math.sqrt(job_brightness)+.5)
    job_echo_text:alpha(math.floor(job_echo_alpha*widget_opacity+.5))
    job_echo_text:visible(ready and job_echo_alpha>0)
    lv_echo_text:pos(prefix_x,y-math.floor(11*scale)-math.floor(job_drift*.55+.5))
    lv_echo_text:alpha(math.floor(job_echo_alpha*widget_opacity+.5))
    lv_echo_text:visible(ready and job_echo_alpha>0)
    pct_flash_text:pos(pct_anchor,y-math.floor(11*scale)-pct_drift)
    local pct_flash_alpha=math.floor(194*pct_brightness+.5)
    pct_flash_text:alpha(math.floor(pct_flash_alpha*widget_opacity+.5))
    pct_flash_text:visible(ready and pct_flash_alpha>0)
    pct_echo_text:pos(pct_anchor,y-math.floor(11*scale)-math.floor(pct_drift*.52+.5))
    local pct_echo_alpha=math.floor(93*math.sqrt(pct_brightness)+.5)
    pct_echo_text:alpha(math.floor(pct_echo_alpha*widget_opacity+.5))
    pct_echo_text:visible(ready and pct_echo_alpha>0)
    -- Glyph-width measurement lets either digit mode follow the end of
    -- crisp 'Lv.' with a stable baseline even for different job names.
    local prefix_width=measured(lv_prefix_text,4*7*scale)
    local digit_x=prefix_x+math.floor(prefix_width+.5)+math.floor(2*scale+.5)
    local digit_y=y-math.floor(11*scale)-math.floor(scale+.5)
    local ember=gauge:caption_ember(now)
    gauge:draw_level_sparkles(digit_x,digit_y,level,ember,scale)
    if layout.LevelDigits=='native' then
        level_digits_text:hide()
        for _,t in ipairs({level_digit_flash,level_digit_echo,level_digit_veil,
            level_old_text,level_old_echo}) do t:hide() end
        native:show()
        native:draw({level=level,previous=gauge.level_from,
            age=age,flash=job_brightness,drift=job_drift,ember=ember,
            x=digit_x,y=y-math.floor(2*scale),scale=scale,opacity=widget_opacity})
    else
        native:hide()
        local txt=tostring(math.max(0,math.floor(tonumber(level) or 0)))
        put_text(level_digits_text,txt)
        put_text(level_digit_flash,txt)
        put_text(level_digit_echo,txt)
        put_text(level_digit_veil,txt)
        local changing=age and age>=1.67 and age<2.45 and
            gauge.level_from and tonumber(gauge.level_from)~=tonumber(level)
        local phase=changing and bound((age-1.67)/.78,0,1) or 1
        level_digits_text:pos(digit_x,digit_y)
        level_digits_text:color(255,mix(249,255,job_brightness*.42),
            mix(235,255,job_brightness*.55))
        level_digits_text:alpha(math.floor(255*(changing and (.23+.77*phase) or 1)*widget_opacity+.5))
        level_digits_text:visible(ready)
        -- The white highlight over the *new* number lasts as long as the
        -- lower amber caption's 16-second return, but stays very subtle.
        level_digit_flash:pos(digit_x,digit_y-job_drift)
        local long_white=math.floor(54*ember+.5)
        local num_flash_alpha=math.max(long_white,math.floor(178*job_brightness+.5))
        level_digit_flash:alpha(math.floor(num_flash_alpha*widget_opacity+.5))
        level_digit_flash:visible(ready and num_flash_alpha>0)
        level_digit_echo:pos(digit_x,digit_y-math.floor(job_drift*.52+.5))
        local echo_alpha=math.floor(105*math.sqrt(job_brightness)+.5)
        level_digit_echo:alpha(math.floor(echo_alpha*widget_opacity+.5))
        level_digit_echo:visible(ready and echo_alpha>0)
        local veil_alpha=changing and math.floor(130*math.sin(math.pi*phase)+.5) or 0
        level_digit_veil:pos(digit_x,digit_y-math.floor((1-phase)*2*scale+.5))
        level_digit_veil:alpha(math.floor(veil_alpha*widget_opacity+.5))
        level_digit_veil:visible(ready and veil_alpha>0)
        if changing then
            local previous=tostring(math.max(0,math.floor(tonumber(gauge.level_from) or 0)))
            put_text(level_old_text,previous)
            put_text(level_old_echo,previous)
            local current_w=measured(level_digits_text,#txt*7*scale)
            local old_w=measured(level_old_text,#previous*7*scale)
            local old_x=digit_x+math.floor((current_w-old_w)/2+.5)
            level_old_text:pos(old_x,digit_y)
            level_old_text:color(255,249,236)
            level_old_text:alpha(math.floor(152*(1-phase)^1.15*widget_opacity+.5))
            level_old_text:visible(ready and phase<1)
            level_old_echo:pos(old_x,digit_y-math.floor(2*phase*scale+.5))
            level_old_echo:alpha(math.floor(125*(1-phase)*widget_opacity+.5))
            level_old_echo:visible(ready and phase<1)
        else
            level_old_text:hide();level_old_echo:hide()
        end
    end
    level_art:show()
    local show_gold=layout.GoldLabel
    local goldonly=layout.LevelPresentation=='goldonly'
    local art_style=layout.LevelStyle
    if preview_state and preview_state.kind=='level' then
        if preview_state.gold~=nil then show_gold=preview_state.gold end
        if preview_state.goldonly then goldonly=true end
        if preview_state.gold==false then goldonly=false end
        if preview_state.goldonly or preview_state.gold==false then
            -- Test gold independently, even when native style was selected.
            art_style='hybrid'
        end
    end
    level_art:draw(x+math.floor(width/2),y+math.floor(7*scale),
        age,gauge.level_duration,level_flash,art_style,scale,show_gold,widget_opacity)
    -- HYBRID: crisp serif underlined message first, late gold label second.
    -- Native bitmap popup remains an explicit alternate style only.
    local suppress_crisp=goldonly and show_gold and art_style~='native'
    if preview_state and preview_state.kind=='level' then
        if preview_state.goldonly then suppress_crisp=true end
        if preview_state.gold==false then suppress_crisp=false end
        if preview_state.gold==true and not preview_state.goldonly then suppress_crisp=false end
    end
    if not suppress_crisp and (art_style=='hybrid' or art_style=='gold') and
        age and age>=.05 and age<gauge.level_duration then
        local quiet=1-bound((age-2.52)/.48,0,1)
        local bounce=math.sin(age*22)*1.15*(1-age/3)
        local alpha=math.floor((.4+.6*level_flash)*quiet*250+.5)
        local text_width=70*scale
        if level_text.extents then
            local ok,w=pcall(function() return level_text:extents() end)
            if ok and tonumber(w) and w>0 then text_width=w end
        end
        local center=x+width/2
        local ty=y+math.floor(4*scale+bounce*scale+.5)
        level_text:pos(math.floor(center-text_width/2+.5),ty-math.floor(10*scale))
        level_text:color(mix(220,255,level_flash),
            mix(165,250,level_flash),mix(77,235,level_flash))
        level_text:alpha(math.floor(alpha*widget_opacity+.5))
        level_text:visible(ready and alpha>2)
        level_under:pos(math.floor(center-text_width/2+.5),ty+math.floor(7*scale))
        level_under:size(math.max(1,math.floor(text_width+.5)),
            math.max(1,math.floor(1.5*scale+.5)))
        level_under:alpha(math.floor(alpha*.82*widget_opacity+.5))
        level_under:visible(ready and alpha>2)
    else
        level_text:hide();level_under:hide()
    end

    -- Base text brightens directly by color; no separate white overlay.
    local gain_tint=normal_flash*.16
    local slow=math.max(ember^.8, gain_tint)
    exp_total_text:color(mix(189,240,slow),mix(152,205,slow),mix(98,140,slow))
    extra_text:color(mix(174,232,slow),mix(139,194,slow),mix(88,134,slow))
    exp_glow_text:alpha(0); exp_glow_text:visible(false)
    extra_glow_text:alpha(0); extra_glow_text:visible(false)
    -- All ordinary labels share the same widget visibility fade; no timers
    -- are interrupted, and each effect's own alpha remains independent.
    for _,t in ipairs({job_text,lv_prefix_text,pct_text,exp_total_text,extra_text}) do
        t:alpha(math.floor(255*widget_opacity+.5))
    end
    -- Windower's text stroke alpha is independent of text fill alpha.
    -- Fade both so dark outlines never outlive text during auto-hide.
    -- Avoid repeating ~20 stroke calls per frame when opacity is unchanged.
    local stroke_step=math.floor(255*widget_opacity+.5)
    if stroke_step~=last_stroke_step then
        last_stroke_step=stroke_step
        local function fade_strokes(list,base)
            local alpha=math.floor(base*widget_opacity+.5)
            for _,t in ipairs(list) do t:stroke_alpha(alpha) end
        end
        fade_strokes({job_text,lv_prefix_text,pct_text,exp_total_text,extra_text,
            level_digits_text,level_text,drag_text},220)
        fade_strokes({level_old_text},35)
        fade_strokes({level_digit_flash,level_digit_echo,level_digit_veil,
            level_old_echo},85)
        fade_strokes({job_flash_text,job_echo_text,lv_flash_text,lv_echo_text,
            pct_echo_text},125)
        fade_strokes({pct_flash_text},110)
        fade_strokes({exp_glow_text,extra_glow_text},65)
    end
    rested_bonus_image:alpha(math.floor(255*widget_opacity+.5))

end

local function show_new()
    positioning()
    gauge:show()
    background_image:hide();foreground_image:hide();exp_text:hide()
    gauge.middle:draggable(layout.Edit)
    labels_visible(true)
    update_labels()
    render_labels(os.clock())
end
function initialize()
    old_initialize() -- preserve the stock EXP packet counters and rested status
    gauge:reset()
    last_job,last_level,last_actual_level=nil,nil,nil
    waiting_new_level_packet=false
    preview_until=0
    preview_state=nil
    level_before_total=nil
    flash_previous={job=0,pct=0,level=0}
    flash_drift={job=0,pct=0,level=0}
    widget_opacity=1;last_stroke_step=nil;last_frame=nil;last_activity=os.clock();manually_hidden=false
    gauge:set_opacity(1)
    gauge:set_gain_sparkles(layout.GainSparkles)
    gauge:set_arrival_duration(layout.ArrivalFade)
    gauge:set_level_ramp(layout.LevelRamp)
    show_new()
    if xp.total and xp.total>0 then gauge:set_progress(xp.current/xp.total,true) end
end
function show()
    old_show()
    show_new()
end
function hide()
    old_hide()
    gauge:hide()
    native:hide();level_art:hide()
    labels_visible(false)
    if pending_save then config.save(settings);pending_save=nil end
end
local function details(which,value)
    local function set(field)
        if value=='on' then layout[field]=true
        elseif value=='off' then layout[field]=false
        else layout[field]=not layout[field] end
    end
    if which=='tnl' then set('ShowTNL')
    elseif which=='rate' then set('ShowRate')
    elseif which=='on' then layout.ShowTNL,layout.ShowRate=true,true
    elseif which=='off' then layout.ShowTNL,layout.ShowRate=false,false
    else
        say('details: TNL '..(layout.ShowTNL and 'on' or 'off')..', EXP/hr '..(layout.ShowRate and 'on' or 'off'))
        return
    end
    config.save(settings)
    update_labels()
    render_labels(os.clock())
    say('details: TNL '..(layout.ShowTNL and 'on' or 'off')..', EXP/hr '..(layout.ShowRate and 'on' or 'off'))
end
local function preview(which,mode)
    if not ready then say('Log in first to preview animations.');return end
    local now=os.clock()
    local info=windower.ffxi.get_player()
    local lvl=info and tonumber(info.main_job_level) or 30
    gauge:reset()
    -- Shorthand variants share the same complete 22.5s level-up preview.
    if which=='goldonly' or which=='nogold' or which=='gold' then
        mode=which;which='level'
    end
    if which=='gain' then
        preview_state={kind='gain'}
        gauge:set_progress(.35,true)
        gauge:set_progress(.73)
        preview_until=now+5.5+(tonumber(layout.ArrivalFade) or 1.5)+2
    elseif which=='level' then
        preview_state={kind='level',from=lvl,to=lvl+1}
        if mode=='gold' then preview_state.gold=true end
        if mode=='nogold' then preview_state.gold=false end
        if mode=='goldonly' then
            preview_state.gold=true
            preview_state.goldonly=true
        end
        gauge:set_progress(.88,true)
        level_before_total=10000
        gauge:level_up(lvl,lvl+1,layout.LevelDelay)
        gauge.after_level_progress=2200/12000
        -- Long user-selected fade times should never be cut off by preview.
        preview_until=now+math.max(22.5,12.5+(tonumber(layout.ArrivalFade) or 5.5))+
            (tonumber(layout.LevelRamp) or 2)+(tonumber(layout.LevelDelay) or 0)
    elseif which=='label' or which=='job' then
        preview_state={kind='label'}
        gauge:set_progress((xp.total>0) and xp.current/xp.total or .43,true)
        preview_until=now+6.0
    else
        say('preview gain|level [gold|nogold|goldonly]|goldonly|nogold|label');return
    end
    say('previewing '..(mode=='goldonly' and 'gold-only level' or (mode=='nogold' and 'no-gold level' or which))..' animation (EXP data unchanged).')
end

-- Shared NPCmirror WORKFLOW conventions: short, ordered chat-only help.
-- Reuse Windower chat coloring instead of painting full lines one color.
local function help_line(cmd, description, section)
    local prefix=('//bf'):color(200)
    local arrow=(' -> '):color(200)
    local syntax=(cmd and #cmd>0 and ' '..cmd or ''):color(207)
    local hint=(description or ''):color(0)
    windower.add_to_chat(0, (section and section:color(167)..' ' or '')..
        prefix..syntax..arrow..hint)
end
local function show_help()
    windower.add_to_chat(0, ('BarFiller2  '.._addon.version):color(167))
    help_line('', 'Reveal the bar; show this compact guide')
    help_line('help', 'All commands and examples')
    help_line('status', 'Progress and display settings')
    help_line('preview gain|goldonly|level|nogold', 'Preview without changing EXP')
    help_line('skin blue|gold', 'Choose the gauge color')
    help_line('scale <factor>', 'Resize; 1 = compact default')
    help_line('move', 'Toggle dragging; lock disables it')
    help_line('autohide on|off|<seconds>', 'Idle visibility timer')
    help_line('gainfade <seconds>', 'White arrival fade; default 5.5')
    help_line('restart / unload', 'Reload or unload BarFiller2')
end
local function show_quick_help()
    -- Bare //bf is the everyday reveal action: avoid flooding game chat.
    windower.add_to_chat(0, ('BarFiller2'):color(167)..
        (' -> bar revealed  |  '):color(140)..
        ('//bf help'):color(207)..(' commands  |  '):color(0)..
        ('//bf status'):color(207)..(' details'):color(0))
end
local function show_full_help()
    show_help()
    windower.add_to_chat(0, ('Additional commands'):color(167))
    help_line('show / hide / auto', 'Reveal, hide or resume timed visibility')
    help_line('lock / unlock / pos reset', 'Position controls')
    help_line('width <px> / scaleprofile compact|legacy', 'Sizing options')
    help_line('details [tnl|rate] [on|off]', 'Extra EXP readouts')
    help_line('leveldigits text|native / levelsize <points>', 'Level number typography')
    help_line('levelpresentation goldonly|full', 'Level-up art')
    help_line('levelstyle native|gold|hybrid', 'Level-up artwork style')
    help_line('goldlabel on|off / sparkles on|off', 'Animation toggles')
    help_line('levelramp <seconds> / leveldelay <seconds>', 'Level-up timing')
    help_line('jobbold on|off', 'JOB/SUB lettering weight')
    help_line('preview label|level [gold|nogold|goldonly]', 'More previews')
    help_line('clear / reload / restart / unload', 'Lifecycle actions')
end
local function show_status()
    local opacity=math.floor(widget_opacity*100+.5)
    local elapsed=math.max(0,os.clock()-last_activity)
    local bar_ready=ready and 'ready' or 'not logged in'
    local state=layout.AutoHide and (opacity==0 and 'auto-hidden' or
        (opacity<100 and 'fading' or 'visible')) or 'always visible'
    say(('v%s | %s | %s (%d%%) | job %s Lv.%s'):format(_addon.version,bar_ready,state,opacity,
        tostring(last_job or '---'),tostring(last_level or '--')))
    say(('skin %s | scale %.2f (%s) | digits %s (%spt) | gold %s | sparkles %s'):format(
        settings.TrustSkin.Color, tonumber(layout.Scale) or 1,layout.ScaleProfile,
        layout.LevelDigits,tostring(layout.LevelFontSize),layout.GoldLabel and 'on' or 'off',
        layout.GainSparkles and 'on' or 'off'))
    say(('gain fade %.2fs | level ramp %.2fs | autohide %s (%.1fs; idle %.1fs) | pos %d,%d'):format(
        tonumber(layout.ArrivalFade) or 0,tonumber(layout.LevelRamp) or 0,
        layout.AutoHide and 'on' or 'off',tonumber(layout.HideSeconds) or 60,
        elapsed,x,y))
end
local function reveal_bar()
    manually_hidden=false
    last_activity=os.clock()
    if not ready then
        local info=windower.ffxi.get_info()
        if info and info.logged_in then show() end
    end
    if ready then
        -- Do not reset EXP state or preview. Only refresh visibility timer.
        if widget_opacity<=0 then widget_opacity=0 end
    else
        say('The bar will appear after character login.')
    end
end

windower.register_event('load',function()
    local info=windower.ffxi.get_info()
    if info and info.logged_in then initialize() end
end)
windower.register_event('login',initialize)
windower.register_event('logout',hide)
windower.register_event('addon command',function(command,...)
    local a={...}
    local c=(command or ''):lower()
    if c=='' then
        reveal_bar();show_quick_help()
    elseif c=='help' or c=='h' then
        show_full_help()
    elseif c=='status' then
        show_status()
    elseif c=='show' then
        reveal_bar();say('bar revealed; idle timer refreshed.')
    elseif c=='hide' then
        -- Manual concealment does not delete the data or interrupt animation.
        manually_hidden=true
        widget_opacity=0
        say('bar hidden; //bf to reveal.')
    elseif c=='auto' then
        layout.AutoHide=true
        manually_hidden=false
        last_activity=os.clock()
        config.save(settings)
        say('automatic visibility enabled; '..tostring(layout.HideSeconds)..'s idle delay.')
    elseif c=='skin' then
        local color=(a[1] or ''):lower()
        if color=='blue' or color=='gold' then
            settings.TrustSkin.Color=color
            config.save(settings)
            gauge:set_color(color)
        end
        say('skin '..settings.TrustSkin.Color..' (//bf skin blue|gold)')
    elseif c=='edit' or c=='move' then set_edit(not layout.Edit)
    elseif c=='lock' then set_edit(false)
    elseif c=='unlock' then set_edit(true)
    elseif c=='pos' then
        if (a[1] or ''):lower()=='reset' then
            layout.X,layout.Y=-1,20
            positioning();config.save(settings)
            say('position reset to top-center.')
        else say('position '..tostring(x)..', '..tostring(y)..' (//bf pos reset)') end
    elseif c=='width' then
        local w=tonumber(a[1])
        if w then
            layout.Width=bound(math.floor(w),140,800)
            positioning();config.save(settings)
        end
        say('width '..tostring(width)..' px (//bf width 420)')
    elseif c=='scale' then
        local new_scale=tonumber(a[1])
        if new_scale then
            layout.Scale=bound(new_scale,.65,layout.ScaleProfile=='compact' and 8/3 or 2)
            positioning();config.save(settings)
        end
        say(string.format('scale %.2fx (//bf scale 1)',scale))
    elseif c=='levelstyle' then
        local style=(a[1] or ''):lower()
        if style=='native' or style=='gold' or style=='hybrid' then
            layout.LevelStyle=style;config.save(settings)
        end
        say('level style '..tostring(layout.LevelStyle)..' (native|gold|hybrid)')
    elseif c=='leveldigits' then
        local mode=(a[1] or ''):lower()
        if mode=='text' or mode=='native' then
            layout.LevelDigits=mode; config.save(settings)
            labels_visible(ready)
            render_labels(os.clock())
        end
        say('level digits '..layout.LevelDigits..' (text|native)')
    elseif c=='goldlabel' then
        local mode=(a[1] or ''):lower()
        if mode=='on' then layout.GoldLabel=true
        elseif mode=='off' then layout.GoldLabel=false end
        config.save(settings)
        say('gold label '..(layout.GoldLabel and 'on' or 'off'))
    elseif c=='sparkles' then
        local mode=(a[1] or ''):lower()
        if mode=='on' then layout.GainSparkles=true
        elseif mode=='off' then layout.GainSparkles=false end
        gauge:set_gain_sparkles(layout.GainSparkles)
        config.save(settings)
        say('gain sparkles '..(layout.GainSparkles and 'on' or 'off'))
    elseif c=='details' then details((a[1] or ''):lower(),(a[2] or ''):lower())
    elseif c=='gainfade' then
        local seconds=tonumber(a[1])
        if a[1] and not nonnegative_finite(seconds) then
            say('gainfade expects a finite number of seconds >= 0.');return
        end
        if seconds then layout.ArrivalFade=seconds;config.save(settings) end
        gauge:set_arrival_duration(layout.ArrivalFade)
        say(string.format('gain arrival fade %.2fs (//bf gainfade 5.5; 0 = instant)',layout.ArrivalFade))
    elseif c=='levelramp' then
        local seconds=tonumber(a[1])
        if a[1] and not nonnegative_finite(seconds) then
            say('levelramp expects a finite number of seconds >= 0.');return
        end
        if seconds then layout.LevelRamp=seconds;config.save(settings) end
        gauge:set_level_ramp(layout.LevelRamp)
        say(string.format('level anticipation %.2fs (//bf levelramp 2)',layout.LevelRamp))
    elseif c=='levelpresentation' then
        local mode=(a[1] or ''):lower()
        if mode=='goldonly' or mode=='full' then
            layout.LevelPresentation=mode;config.save(settings)
        end
        say('level presentation '..layout.LevelPresentation..' (goldonly|full)')
    elseif c=='jobbold' then
        local mode=(a[1] or ''):lower()
        if mode=='on' then layout.JobBold=true
        elseif mode=='off' then layout.JobBold=false end
        job_text:bold(layout.JobBold)
        job_flash_text:bold(layout.JobBold)
        job_echo_text:bold(layout.JobBold)
        config.save(settings)
        say('JOB/SUB bold '..(layout.JobBold and 'on' or 'off'))
    elseif c=='levelsize' then
        local points=tonumber(a[1])
        if a[1] and (not nonnegative_finite(points) or points<1) then
            say('levelsize expects finite points >= 1.');return
        end
        if points then layout.LevelFontSize=math.floor(points+.5)
            positioning();config.save(settings) end
        say('level digits font size '..tostring(layout.LevelFontSize)..'pt')
    elseif c=='autohide' then
        local arg=(a[1] or ''):lower()
        if arg=='on' then layout.AutoHide=true
        elseif arg=='off' then layout.AutoHide=false
        elseif arg~='' then
            local seconds=tonumber(arg)
            if not nonnegative_finite(seconds) then
                say('autohide expects on, off, or finite seconds >= 0.');return
            end
            layout.HideSeconds=seconds
        end
        last_activity=os.clock()
        config.save(settings)
        say('auto-hide '..(layout.AutoHide and 'on' or 'off')..
            ' after '..tostring(layout.HideSeconds)..'s idle')
    elseif c=='scaleprofile' then
        local profile=(a[1] or ''):lower()
        if profile=='legacy' or profile=='compact' then
            if profile~=layout.ScaleProfile then
                local physical=(tonumber(layout.Scale) or 1)*
                    (layout.ScaleProfile=='compact' and .75 or 1)
                local divisor=profile=='compact' and .75 or 1
                layout.Scale=bound(physical/divisor,.65,profile=='compact' and 8/3 or 2)
                layout.ScaleProfile=profile
                positioning();config.save(settings)
            end
        end
        say('scale profile '..layout.ScaleProfile..' (compact: 1 = old .75; legacy: 1 = old 1)')
    elseif c=='leveldelay' then
        local delay=tonumber(a[1])
        if a[1] and not nonnegative_finite(delay) then
            say('leveldelay expects a finite number of seconds >= 0.');return
        end
        if delay then layout.LevelDelay=delay;config.save(settings) end
        say(string.format('level-up start delay %.2fs',layout.LevelDelay))
    elseif c=='preview' then preview((a[1] or ''):lower(),(a[2] or ''):lower())
    elseif c=='clear' or c=='c' then initialize()
    elseif c=='visible' or c=='v' then if ready then hide() else show() end
    elseif c=='reload' or c=='r' or c=='restart' then
        if pending_save then config.save(settings);pending_save=nil end
        say('restarting BarFiller2.')
        windower.send_command('lua r barfiller2')
    elseif c=='unload' or c=='u' then
        if pending_save then config.save(settings);pending_save=nil end
        say('unloading BarFiller2.')
        windower.send_command('lua u barfiller2')
    else
        say('Unknown command: '..c)
        show_full_help()
    end
end)
windower.register_event('incoming chunk',function(id,original,modified,injected,blocked)
    if injected or not ready or (id~=0x2D and id~=0x61) then return end
    local p=packets.parse('incoming',original)
    if not p then return end
    if preview_state then
        preview_state=nil;preview_until=0
        gauge:reset()
        if xp.total>0 then gauge:set_progress(xp.current/xp.total,true) end
    end
    if id==0x2D then
        exp_msg(p['Param 1'],p['Message'])
    else
        xp.current=p['Current EXP'] or xp.current
        xp.total=p['Required EXP'] or xp.total
        xp.tnl=xp.total-xp.current
        chunk_update=true
        if waiting_new_level_packet then
            waiting_new_level_packet=false
            if xp.total>0 then gauge:set_progress(xp.current/xp.total) end
        end
    end
end)
windower.register_event('prerender',function()
    if not ready then return end
    -- In edit mode, read the primitive that images.lua has already moved,
    -- then relocate the entire widget using a single saved anchor.
    if layout.Edit then
        local dx=gauge.middle:pos_x()-(x+math.floor(8*scale+.5))
        local dy=gauge.middle:pos_y()-y
        if dx~=0 or dy~=0 then arrange_at(x+dx,y+dy) end
    end
    local now=os.clock()
    if pending_save and now>pending_save then
        config.save(settings);pending_save=nil
    end
    if chunk_update then
        xp.rate=analyze_points_table(xp.registry)
        update_strings() -- Stock EXP tracker remains hidden.
        chunk_update=false
    end
    update_labels()
    if preview_state then
        if now>=preview_until then
            preview_until=0;preview_state=nil
            gauge:set_progress((xp.total>0) and xp.current/xp.total or 0,true)
        end
    elseif not waiting_new_level_packet and xp.total>0 then
        gauge:set_progress(xp.current/xp.total)
    end
    -- Timers keep advancing even when auto-hidden. Reopen automatically on
    -- fresh EXP, celebration or preview; count 60s only after all fade tails.
    if gauge:animation_busy(now) or preview_state then last_activity=now end
    local desired=not manually_hidden and (not layout.AutoHide or (now-last_activity)<layout.HideSeconds) and 1 or 0
    local dt=last_frame and bound(now-last_frame,0,.1) or 0
    last_frame=now
    if desired>widget_opacity then
        widget_opacity=bound(widget_opacity+dt/.22,0,1)
    elseif desired<widget_opacity then
        widget_opacity=bound(widget_opacity-dt/.9,0,1)
    end
    gauge:set_opacity(widget_opacity)
    gauge.middle:draggable(layout.Edit and widget_opacity>.05)
    gauge:draw()
    render_labels(now) -- Numbers and tints sample the bar's displayed fraction.
    if exp_text:visible() then exp_text:hide() end
end)

windower.register_event('level up',function(level)
    if preview_state then preview_state=nil;preview_until=0;gauge:reset() end
    local info=windower.ffxi.get_player()
    if not info then return end
    local actual=permanent_level(info)
    if actual then
        -- Only confirmed permanent job-level increases celebrate. The sync
        -- cap can rise when the designated party member levels up, but other
        -- party members' permanent jobs do not increase.
        update_labels()
    else
        -- Compatibility fallback where Windower provides no jobs table:
        -- this event alone cannot reliably distinguish Level Sync changes.
        local prior=last_level or math.max(1,(tonumber(level) or 1)-1)
        local next_level=tonumber(level) or (prior+1)
        if next_level>prior then
            level_before_total=tonumber(xp.total) or 0
            gauge:level_up(prior,next_level,layout.LevelDelay)
            waiting_new_level_packet=true
        end
        last_level=next_level
    end
end)
windower.register_event('level down',function(level)
    update_labels()
end)
windower.register_event('zone change',function() mog_house() end)
