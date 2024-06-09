package.path = package.path .. ";/?;/?/init.lua"
local renderer   = require('rendr.renderer')
local databus    = require("rendr.databus")
local threads    = require("rendr.threads")
local util       = require("scada-common.util")
local log        = require("scada-common.log")
local tcd        = require("scada-common.tcd")
local core       = require("graphics.core")
local types      = require("rendr.types")
local modem      = peripheral.find('modem')
modem.open(0)
local config = {
    COMMS_TIMEOUT = 5
}

databus.ps.subscribe("GEAR",function(val)
    databus.ps.toggle('init_ok')
    modem.transmit(0,0,textutils.serialise({"GEAR",val}))
end)



local speaker    = peripheral.find('speaker')
local dfpwm      = require("cc.audio.dfpwm")


local smpl = (8 * 1024)

local function callout(tx)
    local url = "https://music.madefor.cc/tts?text=" .. textutils.urlEncode(tx)
    local response, err = http.get { url = url, binary = true }
    if not response then error(err, 0) end
    local prog = tonumber(response.getResponseHeaders()["Content-Length"])
    
    local decoder = dfpwm.make_decoder()

    while true do
        local chunk
        if prog < smpl then
            chunk = response.read(prog)
        else
            chunk = response.read(smpl)
        end
        if not chunk or #chunk <=0 then break end

        prog = prog -#chunk

        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    os.pullEvent("speaker_audio_empty")
    speaker.stop()
end

local queue = {
    p0 = {},
    p1 = {},
    p2 = {},
    p3 = {},
    p4 = {}
}
local function fetch()
    if #queue.p4 > 0 then
        return table.remove(queue.p4,1)
    elseif #queue.p3 > 0 then
        return table.remove(queue.p3,1)
    elseif #queue.p2 > 0 then
        return table.remove(queue.p2,1)
    elseif #queue.p1 > 0 then
        return table.remove(queue.p1,1)
    elseif #queue.p0 > 0 then
        return table.remove(queue.p0,1)
    end
end


local GEAR = types.GEAR_STATE.UP
local REVR = false
local drop = false
local nuke = false
local engn = true
local nlcd = 0
local function dropsafe ()
    local t = (
        GEAR == types.GEAR_STATE.UP and
        engn
    )
    if nuke then
        t = t and nlcd == 123456
    end
    databus.ps.publish('drop',t)
end

local function main()
    local conn_wd = {
        sv = util.new_watchdog(config.COMMS_TIMEOUT),
        api = util.new_watchdog(config.COMMS_TIMEOUT)
    }
    conn_wd.sv.cancel()
    conn_wd.api.cancel()
    local MAIN_CLOCK = 0.5
    local loop_clock = util.new_clock(MAIN_CLOCK)
    local ui_ok, message = renderer.try_start_ui()
    if not ui_ok then
        print(util.c("UI error: ", message))
        log.error(util.c("startup> GUI render failed with error ", message))
    else
        -- start clock
        loop_clock.start()
    end



    if ui_ok then
        -- start connection watchdogs
        conn_wd.sv.feed()
        conn_wd.api.feed()
        log.debug("startup> conn watchdog started")
        databus.ps.publish("init_ok",true)


        -- main event loop
        while true do
            local event, param1, param2, param3, param4, param5 = util.pull_event()

            -- handle event
            if event == "timer" then
                if loop_clock.is_clock(param1) then
                    -- main loop tick

                    -- relink if necessary
                    databus.heartbeat()
                    

                    loop_clock.start()
                elseif conn_wd.sv.is_timer(param1) then
                    -- supervisor watchdog timeout
                    log.info("supervisor server timeout")
                    
                elseif conn_wd.api.is_timer(param1) then
                    -- coordinator watchdog timeout
                    log.info("coordinator api server timeout")

                else
                    -- a non-clock/main watchdog timer event
                    -- notify timer callback dispatcher
                    tcd.handle(param1)
                end
            elseif event == "modem_message" then
                ---- got a packet
                --local packet = superv_comms.parse_packet(param1, param2, param3, param4, param5)
                --superv_comms.handle_packet(packet)
            elseif event == "monitor_touch" or event == "mouse_click" or event == "mouse_up" or
                event == "mouse_drag" or event == "mouse_scroll" or event == "double_click" then
                -- handle a mouse event
                renderer.handle_mouse(core.events.new_mouse_event(event, param1, param2, param3))
            end

            -- check for termination request
            if event == "terminate" then
                log.info("terminate requested, closing server connections...")
                
                log.info("connections closed")
                break
            end
        end

        --renderer.close_ui()
    end

    print("exited")
    log.info("exited")
end
databus.ps.subscribe("nlcd",function(v)
    nlcd = v
end)
databus.ps.subscribe("engn",function(v)
    engn =not engn
    if engn then
        databus.ps.publish("estat",types.ENGN_STATE.NORM)
    else
        if REVR then
            databus.ps.publish("Trevrsr",555)
        end
        databus.ps.publish("estat",types.ENGN_STATE.CUT)
    end
end)
databus.ps.subscribe("ARM_AP",function(v)
    databus.ps.publish('AP',v)
end)
databus.ps.subscribe("ARM_AT",function(v)
    databus.ps.publish('AT',v)
end)
databus.ps.subscribe("tgl_gear",function(v)
    if (GEAR == types.GEAR_STATE.UP) then
        databus.ps.publish('gear',types.GEAR_STATE.DOWN)
        GEAR = types.GEAR_STATE.DOWN
        drop = false
    elseif (GEAR == types.GEAR_STATE.DOWN) then
        databus.ps.publish('gear',types.GEAR_STATE.UP)
        GEAR = types.GEAR_STATE.UP
        drop = false
    end
    
end)
databus.ps.subscribe("Trevrsr",function(v)
    if (GEAR == types.GEAR_STATE.DOWN or GEAR == types.GEAR_STATE.LOCK) and engn then
        REVR = not REVR
        if REVR then
            databus.ps.publish('gear',types.GEAR_STATE.LOCK)
            GEAR = types.GEAR_STATE.LOCK
        else
            databus.ps.publish('gear',types.GEAR_STATE.DOWN)
            GEAR = types.GEAR_STATE.DOWN
        end
        databus.ps.publish('revrsr',REVR)
        
    elseif REVR then
        if GEAR == types.GEAR_STATE.LOCK then
            databus.ps.publish('gear',types.GEAR_STATE.DOWN)
            GEAR = types.GEAR_STATE.DOWN
        end
        databus.ps.publish('revrsr',false)
        --databus.ps.publish("caution",true)
        REVR = false
    end
    
end)
parallel.waitForAll(main,function()
    databus.ps.publish("nuke",nuke)
    databus.ps.publish("estat",types.ENGN_STATE.NORM)
    while true do
        dropsafe()
        sleep(1)
    end
end,function()
    while true do
        if REVR and GEAR == types.GEAR_STATE.DOWN then
            databus.ps.publish('gear',types.GEAR_STATE.LOCK)
            GEAR = types.GEAR_STATE.LOCK
        elseif REVR and GEAR == types.GEAR_STATE.UP then
            databus.ps.publish("warning",true)
        end
        sleep(0.5)
    end
end,function()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        local bus = textutils.unserialise(message)
        databus.ps.publish(table.unpack(bus))
    end
end,
function()
    while true do
        local tx = fetch()
        if tx then
            databus.ps.toggle("audioSVR")
            callout(tx)
            databus.ps.toggle("audioSVR")
        else
            os.pullEventRaw('audio')
        end
        os.pullEventRaw()
    end
end,
function()
    while true do
        local _,ur,tx = os.pullEventRaw('audio')
        table.insert(queue[ur],tx)
    end
end)
local ok, m = pcall(main)
if not ok then
    print(m)

    pcall(renderer.close_ui)
else
    log.close()
end