local telem = require 'telem'
local x = 0
local mon = peripheral.wrap('right')
local mon2 = peripheral.wrap('bottom')
mon.setTextScale(0.5)
mon2.setTextScale(0.5)
local monw, monh = mon.getSize()
local mon2w, mon2h = mon2.getSize()
local win = window.create(mon, 1, 1, monw, math.ceil(monh/2))
local win2 = window.create(mon, 1, math.ceil(monh/2)+1, monw, math.ceil(monh/2))
local win3 = window.create(mon2, 1, 1, mon2w, mon2h)
-- setup the fluent interface

local pidcontrollers = require ".lib.pidcontrollers"

local target_altitude = 100
local P = 0.155
local I = 0
local D = 0.075

local vel =0

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
  end

--used for integral clamping--
local minimum_value = -10 
local maximum_value = 10 --redstone
--used for integral clamping--
local continuous_scalar_pid = pidcontrollers.PID_Continuous_Scalar(P, I, D, minimum_value ,maximum_value)
local alti = 0

local function trvl(v)
    vel = round(vel+(v/5),3)
    alti = round(alti + vel,2)
    if math.abs(vel) >= 0.2 then
        vel = vel -(0.2*(vel/math.abs(vel)))
    end
end

local function getError()
    x = x+0.1
    return (alti) - target_altitude
end

local error_value = getError()
local pid_value = 0


local backplane = telem.backplane()
    -- short form return, name and value only
    :addInput('custom_short', telem.input.custom(function ()
        -- do stuff
        -- ...
        return {
            custom_short_1 = alti,
            custom_short_2 = pid_value,
            custom_short_3 = vel
        }
    end))

    -- long form return, supports all Metric properties
    :addOutput('monitor_rand1', telem.output.plotter.line(win, 'custom_short_2', colors.black, colors.red))
    :addOutput('monitor_rand2', telem.output.plotter.line(win2, 'custom_short_1', colors.black, colors.blue))

-- read all inputs and write all outputs, then wait 3 seconds, repeating indefinitely
parallel.waitForAny(
    function()
        while true do
            if (alti ~= target_altitude) or (vel ~=0)then
                pid_value = -continuous_scalar_pid:run(error_value)
                error_value = getError()
            else
                pid_value = 0
            end
            trvl(pid_value)
            os.pullEvent()
        end
    end,
    function()
        while true do
            target_altitude = tonumber(read())
        end
        
    end,
	backplane:cycleEvery(0.07)
)