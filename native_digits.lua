-- Awake: lightweight level numeral renderer for BarFiller Test 7.
-- Only 0-9 are extracted from menu/menu2fon. JOB/SUB and Lv. stay crisp text.
-- A subtle long-fading white veil can persist on the new level digits while
-- the lower amber captions cool back toward brown.
local images=require('images')
local dims=require('native_dimensions')
local M={};local methods={};methods.__index=methods
local function clip(n) return math.max(0,math.min(1,n or 0)) end
local function make(path)
    return images.new({pos={x=0,y=0},visible=false,size={width=1,height=1},
        texture={path=path,fit=true},color={alpha=255,red=255,green=255,blue=255},
        draggable=false,repeatable={x=1,y=1}})
end
local function slot(path)
    local s={cache={}}
    for _,type in ipairs({'base','flash','bloom','burst','echo','veil'}) do
        s[type]=make(path..'digit_0_edge.png')
    end
    return s
end
function M.new(path)
    local self=setmetatable({path=path,visible=false,slots={},old={}},methods)
    for i=1,3 do self.slots[i]=slot(path);self.old[i]=slot(path) end
    return self
end
function methods:show() self.visible=true end
function methods:hide()
    self.visible=false
    for _,group in ipairs({self.slots,self.old}) do
        for _,s in ipairs(group) do
            for _,type in ipairs({'base','flash','bloom','burst','echo','veil'}) do
                s[type]:hide()
            end
        end
    end
end
local function put(self,s,layer,digit,cx,cy,scale,opacity,light)
    local obj=s[layer]
    if not self.visible or not digit or opacity<=.004 then obj:hide();return end
    local path=self.path..'digit_'..digit..(light and '_light.png' or '_edge.png')
    if s.cache[layer]~=path then obj:path(path);s.cache[layer]=path end
    local dim=dims['digit_'..digit]
    local iw=(dim[1]+2)*scale
    local ih=(dim[2]+2)*scale
    obj:pos(math.floor(cx-iw/2+.5),math.floor(cy-ih/2+.5))
    obj:size(math.max(1,math.floor(iw+.5)),math.max(1,math.floor(ih+.5)))
    obj:alpha(math.floor(clip(opacity)*255*(self.opacity or 1)+.5))
    obj:visible(true)
end
local function layout(value,scale)
    local digits=tostring(math.max(0,math.floor(tonumber(value) or 0)))
    local widths={};local total=0
    for i=1,#digits do
        local digit=digits:sub(i,i)
        local info=dims['digit_'..digit]
        local w=math.floor((info[1]+2)*scale+.5)
        widths[i]=w;total=total+w+(i<#digits and math.max(1,math.floor(scale*.45+.5)) or 0)
    end
    return digits,widths,total
end
function methods:draw(info)
    self.opacity=clip(info.opacity or 1)
    local scale=math.max(.5,(tonumber(info.scale) or 1)*1.17)
    local baseline_x=tonumber(info.x) or 0
    local center_y=tonumber(info.y) or 0
    local flash=clip(info.flash)
    local drift=tonumber(info.drift) or 0
    local age=info.age
    local phase=age and clip((age-1.67)/.78) or nil
    local ember=clip(info.ember or 0)
    local in_morph=age and age>=1.67 and age<2.45 and info.previous and
        tonumber(info.previous)~=tonumber(info.level)
    local digits,widths,total=layout(info.level,scale)
    local px=baseline_x
    for i=1,#digits do
        local d=digits:sub(i,i)
        local s=self.slots[i]
        local cx=px+widths[i]/2
        local p=(in_morph and phase) or 1
        put(self,s,'base',d,cx,center_y,scale,.18+.82*p,false)
        local lasting=math.max(flash*.84, ember*.26)
        put(self,s,'flash',d,cx,center_y-drift,scale,lasting,true)
        -- A narrower, translucent interaction between base and moving flash.
        put(self,s,'bloom',d,cx,center_y-drift*.45,scale*1.12,math.max(flash*.32, ember*.14),true)
        if in_morph then
            -- The white burst contracts while the colored echo expands.
            put(self,s,'burst',d,cx,center_y,scale*(1.52-.52*p),(1-p)^.65,true)
            put(self,s,'echo',d,cx,center_y,scale*(1+.52*p),.65*(1-p)^1.15,false)
            -- Fifth light layer: small rising ivory echo between the two.
            put(self,s,'veil',d,cx,center_y-(1-p)*2*scale,
                scale*(.92+.16*p),.58*math.sin(math.pi*p),true)
        else
            s.burst:hide();s.echo:hide();s.veil:hide()
        end
        px=px+widths[i]+math.max(1,math.floor(scale*.45+.5))
    end
    for i=#digits+1,#self.slots do
        for _,l in ipairs({'base','flash','bloom','burst','echo','veil'}) do self.slots[i][l]:hide() end
    end
    -- Previous-level digits linger as a sixth transient silhouette, aligned
    -- about the same center even when 9 becomes 10 or 99 becomes 100.
    if in_morph then
        local old,oldwidths,oldtotal=layout(info.previous,scale)
        local ox=baseline_x+(total-oldtotal)/2
        for i=1,#old do
            local s=self.old[i];local d=old:sub(i,i)
            put(self,s,'base',d,ox+oldwidths[i]/2,center_y,
                scale*(1+.19*phase),.77*(1-phase)^1.3,false)
            put(self,s,'flash',d,ox+oldwidths[i]/2,center_y-2*phase*scale,
                scale*(1+.35*phase),.55*(1-phase),true)
            for _,l in ipairs({'bloom','burst','echo','veil'}) do s[l]:hide() end
            ox=ox+oldwidths[i]+math.max(1,math.floor(scale*.45+.5))
        end
        for i=#old+1,#self.old do
            for _,l in ipairs({'base','flash','bloom','burst','echo','veil'}) do self.old[i][l]:hide() end
        end
    else
        for _,s in ipairs(self.old) do
            for _,l in ipairs({'base','flash','bloom','burst','echo','veil'}) do s[l]:hide() end
        end
    end
end
function methods:destroy()
    for _,group in ipairs({self.slots,self.old}) do
        for _,s in ipairs(group) do
            for _,l in ipairs({'base','flash','bloom','burst','echo','veil'}) do s[l]:destroy() end
        end
    end
end
return M
