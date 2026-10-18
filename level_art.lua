-- Awake: BarFiller Test 11. Gold-only sequence unchanged; widget-opacity fade added.
-- Four staggered copies of the same GOLD image, all zooming and fading to
-- the SAME final scale, plus the very last expanding echo. No jitter.
-- Gold is stylized/generated art, not an extracted FFXI DAT texture.
-- The optional 'native' style uses genuine 51.DAT menu2fon sprites.
local images=require('images')
local art={};local methods={};methods.__index=methods
local function clamp(v) return math.max(0,math.min(1,v)) end
-- Only one LevelArt instance per Windower addon; reset for every draw.
local draw_opacity=1
local function smooth(v) v=clamp(v);return v*v*(3-2*v) end
local function mk(path)
    return images.new({pos={x=0,y=0},visible=false,size={width=1,height=1},
        texture={path=path,fit=true},color={alpha=255,red=255,green=255,blue=255},
        draggable=false,repeatable={x=1,y=1}})
end
function art.new(path)
    local self={native=mk(path..'levelup_native.png'),
        native_ghost=mk(path..'levelup_native_ghost.png'),
        visible=false,golds={},steady=mk(path..'levelup_gold.png'),ghost=mk(path..'levelup_gold.png')}
    for i=1,4 do self.golds[i]=mk(path..'levelup_gold.png') end
    return setmetatable(self,methods)
end
function methods:hide()
    self.visible=false
    self.native:hide();self.native_ghost:hide();self.ghost:hide();self.steady:hide()
    for _,g in ipairs(self.golds) do g:hide() end
end
function methods:show() self.visible=true end
local function put(obj,enabled,cx,cy,w,h,alpha)
    if not enabled or alpha<=0 then obj:hide();return end
    obj:pos(math.floor(cx-w/2+.5),math.floor(cy-h/2+.5))
    obj:size(math.max(1,math.floor(w+.5)),math.max(1,math.floor(h+.5)))
    obj:alpha(math.floor(clamp(alpha)*255*draw_opacity+.5))
    obj:visible(true)
end
function methods:draw(cx,cy,age,duration,intensity,style,scale,show_gold,opacity)
    draw_opacity=clamp(tonumber(opacity) or 1)
    if not self.visible or not age or age<0 or age>=duration then
        self.native:hide();self.native_ghost:hide();self.ghost:hide();self.steady:hide()
        for _,g in ipairs(self.golds) do g:hide() end
        return
    end
    scale=scale or 1
    local is_native=style=='native'
    local base_y=cy-math.floor(1.5*scale+.5)
    local native_alpha=(.34+.66*intensity)*(1-clamp((age-2.17)/.42))
    local native_bounce=math.sin(age*20)*.9*math.max(0,1-age/duration)
    put(self.native,is_native,cx,base_y+native_bounce*scale,
        102*scale,24*scale,native_alpha)

    -- Early ghost copies are faint; each successive overlapping copy is
    -- stronger. All grow from full label size to a 1.90x fading echo.
    -- Pulse intensity multiplies opacity but does not make the base invisible.
    local starts={.06,.52,.98,1.45}
    local strengths={.32,.49,.68,.91}
    local lifetimes={1.35,1.38,1.40,1.42}
    local allow_gold=show_gold~=false and not is_native
    for i,obj in ipairs(self.golds) do
        local t=age-starts[i]
        local life=lifetimes[i]
        local active=allow_gold and t>=0 and t<life
        local progress=clamp(t/life)
        local expansion=1+.90*smooth(progress)
        local fade=(1-smooth(progress))^1.15
        local appear=clamp(t/.09)
        local alpha=strengths[i]*fade*appear*(.52+.48*intensity)
        put(obj,active,cx,base_y,116*scale*expansion,23*scale*expansion,alpha)
    end
    -- A smaller, stationary gold core grows brighter, then fades with the
    -- last expanding echo. It doesn't compete with the zooming trail.
    local steady_in=smooth(age/1.85)
    local steady_out=1-smooth((age-2.08)/math.max(.1,duration-2.08))
    put(self.steady,allow_gold,cx,base_y,105*scale,21*scale,
        .76*steady_in*steady_out*(.68+.32*intensity))
    -- The final capstone follows the SAME zoom trajectory and endpoint.
    local ghost_start=2.08
    local t=age-ghost_start
    local life=math.max(.1,duration-ghost_start)
    local p=clamp(t/life)
    local active=allow_gold and t>=0 and t<life
    local alpha=(1-smooth(p))*(.55+.45*intensity)
    put(self.ghost,active,cx,base_y,116*scale*(1+.90*smooth(p)),
        23*scale*(1+.90*smooth(p)),alpha)

    if is_native then
        local np=clamp((age-2.46)/math.max(.05,duration-2.46))
        put(self.native_ghost,age>=2.46,cx,base_y,
            102*scale*(1+.90*smooth(np)),24*scale*(1+.90*smooth(np)),
            (1-smooth(np))*(.42+.58*intensity))
    else
        self.native_ghost:hide()
    end
end
function methods:destroy()
    self.native:destroy();self.native_ghost:destroy();self.ghost:destroy();self.steady:destroy()
    for _,g in ipairs(self.golds) do g:destroy() end
end
return art
