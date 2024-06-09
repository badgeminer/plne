
local types             = require("rendr.types")
local util              = require("scada-common.util")

local databus           = require("rendr.databus")

local style             = require("rendr.style")

local core              = require("graphics.core")
local flasher           = require("graphics.flasher")

local Div               = require("graphics.elements.div")
local Rectangle         = require("graphics.elements.rectangle")
local TextBox           = require("graphics.elements.textbox")

local PushButton        = require("graphics.elements.controls.push_button")
local hazard_button     = require("graphics.elements.controls.hazard_button")

local LED               = require("graphics.elements.indicators.led")
local LEDPair           = require("graphics.elements.indicators.ledpair")
local AlarmLight        = require("graphics.elements.indicators.alight")
local IndicatorLight    = require("graphics.elements.indicators.light")
local RGBLED            = require("graphics.elements.indicators.ledrgb")
local SpinboxNumeric    = require("graphics.elements.controls.spinbox_numeric")

local ALIGN = core.ALIGN

local cpair = core.cpair
local border = core.border


local bw_fg_bg = style.bw_fg_bg

local ind_grn = style.ind_grn
local ind_red = style.ind_red
local ind_yllw = style.ind_yllw

local ack_fg_bg = cpair(colors.black, colors.orange)
local rst_fg_bg = cpair(colors.black, colors.lime)
local active_fg_bg = cpair(colors.white, colors.gray)

local gry_wht = style.gray_white

local dis_colors = style.dis_colors

-- create new front panel view
---@param panel graphics_element main displaybox
local function init(panel)
    local AP_div = Div{parent=panel,width=15,height=24,x=1,y=1}
    local header = TextBox{parent=AP_div,text="A/P",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    AP_div.line_break()

    
    local alt = LED{parent=AP_div,label="ALT",y=4,colors=ind_grn,width=4}
    local Alti = SpinboxNumeric{parent=AP_div,x=7,y=3,whole_num_precision=4,fractional_precision=0,min=100,arrow_fg_bg=gry_wht,fg_bg=bw_fg_bg}
    
    PushButton{
        parent=AP_div,x=3,y=6,min_width=8,
        text="LVLCHG",
        callback=function()
            databus.ps.publish("LVLCHG",Alti.get_value())
        end,
        fg_bg=cpair(colors.black,colors.green_off),active_fg_bg=cpair(colors.black,colors.green)}

    local spd = LED{parent=AP_div,label="SPD",y=8,colors=ind_grn,width=4}
    local Speed = SpinboxNumeric{parent=AP_div,x=7,y=7,whole_num_precision=3,fractional_precision=0,min=100,arrow_fg_bg=gry_wht,fg_bg=bw_fg_bg}
    
    PushButton{
        parent=AP_div,x=3,y=10,min_width=8,
        text="SPDSEL",
        callback=function()
            databus.ps.publish("SPDSEL",Speed.get_value())
        end,
        fg_bg=cpair(colors.black,colors.green_off),active_fg_bg=cpair(colors.black,colors.green)}

    local hdd = LED{parent=AP_div,label="HDD",y=12,colors=ind_grn,width=4}
    local Headding = SpinboxNumeric{parent=AP_div,x=7,y=11,whole_num_precision=3,fractional_precision=0,min=0,max=360,arrow_fg_bg=gry_wht,fg_bg=bw_fg_bg}
    
    PushButton{
        parent=AP_div,x=3,y=14,min_width=8,
        text="HDDSEL",
        callback=function()
            databus.ps.publish("HDDSEL",Headding.get_value())
        end,
        fg_bg=cpair(colors.black,colors.green_off),active_fg_bg=cpair(colors.black,colors.green)
    }

    
    PushButton{
            parent=AP_div,x=1,y=21,min_width=5,
            text="A/P",
            callback=function()
                databus.ps.publish("ARM_AP",true)
            end,
            fg_bg=cpair(colors.white,colors.green_off),active_fg_bg=cpair(colors.white,colors.green)
    }

    local armn = TextBox{parent=AP_div,text="ARM",x=6,y=21,alignment=ALIGN.CENTER,height=1,width=5,fg_bg=style.header}

    PushButton{
        parent=AP_div,x=11,y=21,min_width=5,
        text="A/T",
        callback=function()
            databus.ps.publish("ARM_AT",true)
        end,
        fg_bg=cpair(colors.white,colors.green_off),active_fg_bg=cpair(colors.white,colors.green)
}

    local disc = hazard_button{accent=colors.yellow,parent=AP_div,x=1,y=22,min_width=7,text=" Disconect ",dis_colors=cpair(colors.yellow_off,colors.lightGray),callback=databus.ap_dc,fg_bg=cpair(colors.white,colors.gray)}
    disc.disable()
    disc.register(databus.ps,"AP",function(v)
        if v then
            disc.enable()
        else
            disc.on_response(true)

            disc.disable()
            
        end
    end)
    disc.register(databus.ps,"AT",function(v)
        if v then
            disc.enable()
        else
            disc.on_response(true)

            disc.disable()
            
        end
    end)

end
return init