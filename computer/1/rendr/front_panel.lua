--
-- Reactor PLC Front Panel GUI
--

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
local DataIndicator     = require("graphics.elements.indicators.data")

local ALIGN = core.ALIGN

local cpair = core.cpair
local border = core.border

local ind_grn = style.ind_grn
local ind_red = style.ind_red
local ind_yllw = style.ind_yllw

local bw_fg_bg = style.bw_fg_bg
local lu_cpair = style.lu_colors
local hzd_fg_bg = style.hzd_fg_bg
local dis_colors = style.dis_colors

local gry_wht = style.gray_white

local ack_fg_bg = cpair(colors.black, colors.orange)
local rst_fg_bg = cpair(colors.black, colors.lime)
local active_fg_bg = cpair(colors.white, colors.gray)

local dis_colors = style.dis_colors

local smpl = (8 * 1024)


local function callout(tx)
    os.queueEvent("audio",types.PRIORITY.BASIC,tx)
end




-- create new front panel view
---@param panel graphics_element main displaybox
local function init(panel)


    local system = Div{parent=panel,width=14,height=24,x=1,y=1}
    local header = TextBox{parent=system,y=1,text="STATUS",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    system.line_break()

    local init_ok = LED{parent=system,label="STATUS",colors=cpair(colors.green,colors.red)}
    local heartbeat = LED{parent=system,label="HEARTBEAT",colors=ind_grn}
    
    system.line_break()

    local gear = RGBLED{parent=system,label="GEAR",colors={colors.red,colors.orange,colors.yellow,colors.green}}
    system.line_break()


    local fuel = LED{parent=system,label="Low Fuel",colors=ind_red}
    system.line_break()

    local CTRL = LED{parent=system,label="CTRLS",colors=ind_grn}
    
    

    gear.update(types.GEAR_STATE.UP)

    init_ok.register(databus.ps, "init_ok", init_ok.update)
    
    gear.register(databus.ps, "gear", gear.update)
    heartbeat.register(databus.ps, "heartbeat", heartbeat.update)

    local status = Div{parent=panel,width=21,height=24,x=15,y=1}

    local controls_rct = Rectangle{parent=status,width=21,height=24,x=1,border=border(1,colors.black,true),even_inner=true,fg_bg=cpair(colors.black,colors.gray)}

    local controls = Div{parent=controls_rct,width=20,height=23,fg_bg=cpair(colors.black,colors.black)}

    local controls_FIRE = Div{parent=controls,width=10,height=4,y=1,fg_bg=cpair(colors.red,colors.black)}
    local FH = TextBox{parent=controls_FIRE,y=1,text="FIRE",alignment=ALIGN.CENTER,height=1,fg_bg=cpair(colors.white,colors.red)}
    
    local fb1 = hazard_button{accent=colors.red,parent=controls_FIRE,x=1,y=2,min_width=7,text="1",dis_colors=cpair(colors.red_off,colors.lightGray),callback=databus.Gear,fg_bg=cpair(colors.white,colors.gray)}
    local fb2 = hazard_button{accent=colors.red,parent=controls_FIRE,x=6,y=2,min_width=7,text="2",dis_colors=cpair(colors.red_off,colors.lightGray),callback=databus.Gear,fg_bg=cpair(colors.white,colors.gray)}
    fb1.disable()
    fb2.disable()


    hazard_button{accent=colors.orange,parent=controls,x=1,y=6,min_width=7,text="GEAR",callback=databus.Gear,fg_bg=cpair(colors.white,colors.gray)}
    
    
    
    local psngr = Div{parent=panel,width=12,height=24,x=36,y=1}
    TextBox{parent=psngr,y=1,text="PSNGR",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    psngr.line_break()
    local PA = LED{parent=psngr,y=3,label="",colors=ind_yllw}
    PushButton{parent=psngr,x=3,y=3,min_width=5,text="P.A",callback=databus.PA,fg_bg=cpair(colors.black,colors.yellow),active_fg_bg=cpair(colors.black,colors.yellow_off)}
    PA.register(databus.ps,"PA",PA.update)

    psngr.line_break()
    local sblt = LED{parent=psngr,y=5,label="",colors=cpair(colors.green,colors.red_off)}
    PushButton{parent=psngr,x=3,y=5 ,min_width=6,text="SBLT",callback=databus.rps_reset,fg_bg=cpair(colors.black,colors.green),active_fg_bg=cpair(colors.black,colors.green_off)}


    local alarm_panel = Div{parent=panel,width=9,height=6,x=48,y=1}
    local header = TextBox{parent=alarm_panel,y=1,text="MSTR",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    alarm_panel.line_break()
    local master_caution = IndicatorLight{parent=alarm_panel,label="Caution",colors=ind_yllw}
    master_caution.register(databus.ps,"mcat",master_caution.update)
    alarm_panel.line_break()
    local master_warn = IndicatorLight{parent=alarm_panel,label="Warning",colors=ind_red}
    master_warn.register(databus.ps,"mwarn",master_warn.update)
    

    local AP_div = Div{parent=panel,width=21,height=7,x=36,y=7}
    local header = TextBox{parent=AP_div,text="A/P",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    AP_div.line_break()
    
    local AP = LED{parent=AP_div,label="A/P",colors=ind_yllw}
    AP.register(databus.ps,"AP",AP.update)

    local AT = LED{parent=AP_div,label="A/T",colors=ind_yllw}
    AT.register(databus.ps,"AT",AT.update)

    local alt = LED{parent=AP_div,x=1,y=5,label="ALT",colors=ind_grn,height=1,fg_bg=style.label}
    local lvl_p = DataIndicator{parent=AP_div,x=7,y=5,label="",format="%5d",value=0,unit="",lu_colors=lu_cpair,width=5,fg_bg=style.bw_fg_bg}
    lvl_p.register(databus.ps, "LVLCHG", lvl_p.update)

    local spd = LED{parent=AP_div,x=1,y=6,label="SPD",height=1,colors=ind_grn,fg_bg=style.label}
    local spd_p = DataIndicator{parent=AP_div,x=7,y=6,label="",format="%5d",value=0,unit="",lu_colors=lu_cpair,width=5,fg_bg=style.bw_fg_bg}
    spd_p.register(databus.ps, "SPDSEL", spd_p.update)

    local hdd = LED{parent=AP_div,x=1,y=7,label="HDD",height=1,colors=ind_grn,fg_bg=style.label}
    local hdd_p = DataIndicator{parent=AP_div,x=7,y=7,label="",format="%5d",value=0,unit="",lu_colors=lu_cpair,width=5,fg_bg=style.bw_fg_bg}
    hdd_p.register(databus.ps, "HDDSEL", hdd_p.update)

    local EStat_div = Div{parent=panel,width=21,height=22,x=36,y=15}
    local header = TextBox{parent=EStat_div,text="ENGN STATUS",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}

    local EStat1_div = Div{parent=EStat_div,width=10,height=7,x=1,y=2}
    local header = TextBox{parent=EStat1_div,text="E1",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    local engnF1 = RGBLED{parent=EStat1_div,label="Fire",colors={colors.red,colors.orange,colors.red_off}}

    engnF1.update(types.ENGN_F_STATE.NORM)
    engnF1.register(databus.ps, "ef1", engnF1.update)

    TextBox{parent=EStat1_div,x=1,y=3,text="RPM",height=1,colors=ind_grn,fg_bg=style.label}
    local erpm1_p = DataIndicator{parent=EStat1_div,x=5,y=3,label="",format="   %03d",value=0,unit="",lu_colors=lu_cpair,width=6,fg_bg=style.bw_fg_bg}
    erpm1_p.register(databus.ps, "erpm1", erpm1_p.update)


    local EStat2_div = Div{parent=EStat_div,width=10,height=7,x=12,y=2}
    local header = TextBox{parent=EStat2_div,text="E2",alignment=ALIGN.CENTER,height=1,fg_bg=style.header}
    local engnF2 = RGBLED{parent=EStat2_div,label="Fire",colors={colors.red,colors.orange,colors.red_off}}

    engnF2.update(types.ENGN_F_STATE.NORM)
    engnF2.register(databus.ps, "ef1", engnF2.update)

    TextBox{parent=EStat2_div,x=1,y=3,text="RPM",height=1,colors=ind_grn,fg_bg=style.label}
    local erpm2_p = DataIndicator{parent=EStat2_div,x=5,y=3,label="",format="   %03d",value=0,unit="",lu_colors=lu_cpair,width=6,fg_bg=style.bw_fg_bg}
    erpm2_p.register(databus.ps, "erpm2", erpm2_p.update)
    

    local outFBND = Rectangle{parent=panel,width=2,height=24,x=57,y=1,border=border(1,colors.blue,true),even_inner=true,fg_bg=cpair(colors.blue,colors.blue)}


    databus.ps.subscribe('ef1',function(s)
        if s == types.ENGN_F_STATE.FIRE then
            callout('FIRE ENGINE 1')
            fb1.enable()
        end
        
    end)
    
    databus.ps.subscribe('ef2',function(s)
        if s == types.ENGN_F_STATE.FIRE then
            callout('FIRE ENGINE 2')
            fb2.enable()
        end
        
    end)
end

return init