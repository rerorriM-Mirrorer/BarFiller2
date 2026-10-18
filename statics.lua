--[[
    BarFiller legacy-support module for independently installable BarFiller2.
    Adapted from Windower/Lua addons/barfiller/statics.lua (dev),
    original work copyright (c) 2015 Morath86, BSD 3-Clause.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    * Redistributions of source code retain the copyright notice,
      these conditions and disclaimer.
    * Redistributions in binary form reproduce that notice, these
      conditions and disclaimer in documentation or other materials.
    * Neither the name BarFiller nor its contributors may be used to endorse
      or promote derived products without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING MERCHANTABILITY AND
    FITNESS FOR A PARTICULAR PURPOSE, ARE DISCLAIMED. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES (INCLUDING LOSS
    OF USE, DATA, PROFITS, OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING FROM THE USE OF THIS SOFTWARE,
    EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    The legacy counter/rendering setup is retained because BarFiller2 builds
    its gauge on top of the stock functions. The stock EXP bar is hidden by
    BarFiller2 after initialization; do not delete these functions casually.
]]

defaults = {}
local base = windower.addon_path
local function legacy_image(path,x,y,w,h,fit)
    return {
        Pos={X=x,Y=y}, Visible=true,
        Texture={Path=base..path, Fit=fit},
        Color={Alpha=255,Red=255,Green=255,Blue=255},
        Size={Width=w,Height=h},
        Repeatable={X=1,Y=1},Draggable=false
    }
end
defaults.Images = {
    Background=legacy_image('bar_bg.png',164,6,472,5,true),
    Foreground=legacy_image('bar_fg.png',166,6,1,5,false),
    RestedBonus=legacy_image('moon.png',636,6,32,32,true),
}
defaults.Images.Background.Pos.AllowDecenter=false

defaults.Texts = {Exp={
    Pos={X=159,Y=13},
    Background={Alpha=0,Red=0,Green=0,Blue=0,Visible=false},
    Flags={Right=false,Bottom=false,Bold=false,Draggable=false,Italic=false},
    Padding=0,
    Text={Size=10,Font='Montserrat',Fonts={'Ubuntu Mono','sans-serif'},
        Alpha=255,Red=253,Green=252,Blue=250,
        Stroke={Width=1,Alpha=127,Red=136,Green=97,Blue=18}}
}}
defaults.ShowDetails={MainJob=true,SubJob=true,Level=true,ExperiencePoints=true,
    ToNextLevel=true,Percent=true,Rate=true}

-- Stock references deliberately remain globally named: BarFiller2 captures
-- initialize/hide/show and calls the helpers on EXP packet updates.
function load_images()
    background_image:pos(settings.Images.Background.Pos.X,settings.Images.Background.Pos.Y)
    background_image:path(settings.Images.Background.Texture.Path)
    background_image:repeat_xy(settings.Images.Background.Repeatable.X,
        settings.Images.Background.Repeatable.Y)
    background_image:draggable(settings.Images.Background.Draggable)
    background_image:show()
    foreground_image:pos(settings.Images.Foreground.Pos.X,settings.Images.Foreground.Pos.Y)
    foreground_image:path(settings.Images.Foreground.Texture.Path)
    foreground_image:fit(settings.Images.Foreground.Texture.Fit)
    foreground_image:draggable(settings.Images.Foreground.Draggable)
    foreground_image:show()
    rested_bonus_image:pos(settings.Images.RestedBonus.Pos.X,settings.Images.RestedBonus.Pos.Y)
    rested_bonus_image:visible(settings.Images.RestedBonus.Visible)
    rested_bonus_image:path(settings.Images.RestedBonus.Texture.Path)
    rested_bonus_image:draggable(settings.Images.RestedBonus.Draggable)
    mog_house()
    position_images()
end
function load_text_box()
    exp_text:pos(settings.Texts.Exp.Pos.X,settings.Texts.Exp.Pos.Y)
    exp_text:bg_alpha(settings.Texts.Exp.Background.Alpha)
    exp_text:bg_visible(settings.Texts.Exp.Background.Visible)
    exp_text:font(settings.Texts.Exp.Text.Font,unpack(settings.Texts.Exp.Text.Fonts))
    exp_text:size(settings.Texts.Exp.Text.Size)
    exp_text:color(settings.Texts.Exp.Text.Red,settings.Texts.Exp.Text.Green,
        settings.Texts.Exp.Text.Blue)
    exp_text:stroke_alpha(settings.Texts.Exp.Text.Stroke.Alpha)
    exp_text:stroke_color(settings.Texts.Exp.Text.Stroke.Red,
        settings.Texts.Exp.Text.Stroke.Green,settings.Texts.Exp.Text.Stroke.Blue)
    exp_text:stroke_width(settings.Texts.Exp.Text.Stroke.Width)
    exp_text:show()
end
function initialize()
    xp={registry={},total=0,rate=0,current=0,tnl=0}
    player={job='',sub='',lvl='',exp='',tnl='',phr='',pct=''}
    load_images()
    load_text_box()
    calc_new_width()
    update_strings()
    ready=true
end
function update_strings()
    info=windower.ffxi.get_player()
    player.job=string.upper(info.main_job)
    player.sub=info.sub_job and '('..string.lower(info.sub_job)..') ' or '(---) '
    player.lvl='Lv'..info.main_job_level..'  '
    player.exp='EXP '..xp.current..'/'..xp.total..' '
    player.tnl='('..xp.tnl..') '
    player.pct=xp.total>0 and math.floor(xp.current/xp.total*100)..'% ' or '0% '
    player.phr='EXP/hr '..string.format('%.1f',math.floor(xp.rate/100)/10)..'k'
    exp_text:clear()
    if settings.ShowDetails.MainJob then exp_text:append(player.job) end
    if settings.ShowDetails.SubJob then exp_text:append(player.sub)
    else exp_text:append(' ') end
    if settings.ShowDetails.Level then exp_text:append(player.lvl) end
    if settings.ShowDetails.ExperiencePoints then exp_text:append(player.exp) end
    if settings.ShowDetails.ToNextLevel then exp_text:append(player.tnl) end
    if settings.ShowDetails.Percent then exp_text:append(player.pct) end
    if settings.ShowDetails.Rate then exp_text:append(player.phr) end
end
function exp_msg(val,msg)
    local t=os.time()
    if msg==8 or msg==105 or msg==253 then
        xp.registry[t]=(xp.registry[t] or 0)+val
        xp.current=math.min(xp.current+val,55999)
        if xp.current>xp.tnl then xp.current=xp.current-xp.tnl end
        chunk_update=true
    end
end
function analyze_points_table(tab)
    local t=os.time()
    local running_total,maximum_timestamp=0,0
    for ts,points in pairs(tab) do
        local time_diff=t-ts
        if time_diff>600 then tab[ts]=nil
        else
            running_total=running_total+points
            if time_diff>maximum_timestamp then maximum_timestamp=time_diff end
        end
    end
    if maximum_timestamp<30 then return 0 end
    return math.floor(running_total/maximum_timestamp*3600)
end
function calc_new_width()
    if xp.current>0 and xp.total>0 then
        local calc=math.floor(xp.current/xp.total*468)
        xp.rate=analyze_points_table(xp.registry)
        return calc
    end
end
function position_images()
    local x
    if settings.Images.Background.Pos.AllowDecenter then
        x=settings.Images.Background.Pos.X
    else
        x=windower.get_windower_settings().x_res/2-settings.Images.Background.Size.Width/2
    end
    background_image:pos(x,settings.Images.Background.Pos.Y)
    foreground_image:pos(x+2,settings.Images.Foreground.Pos.Y)
    rested_bonus_image:pos(x+settings.Images.Background.Size.Width,
        settings.Images.Background.Pos.Y-6)
end
function position_text()
    exp_text:pos(background_image:pos_x()-6,background_image:pos_y()+4)
end
function hide()
    background_image:hide()
    foreground_image:hide()
    rested_bonus_image:hide()
    exp_text:hide()
    ready=false
end
function show()
    background_image:show()
    foreground_image:show()
    mog_house()
    exp_text:show()
    ready=true
end
function mog_house()
    return windower.ffxi.get_info().mog_house and rested_bonus_image:show()
        or rested_bonus_image:hide()
end
