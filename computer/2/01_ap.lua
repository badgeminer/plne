-- CREDIT
-- Thanks to 19PHOBOSS98 for allowing me to add his PID controller setups to my project!
-- https://github.com/19PHOBOSS98/LUA_PID_LIBRARY/tree/main (MIT License)
-- https://github.com/19PHOBOSS98/LUA_PID_LIBRARY/blob/main/LICENSE
package.path = package.path .. ";/?;/?.lua;/?/init.lua"
local args = {...}
local pidcontrollers = require ".lib.pidcontrollers"

local target_altitude = args[1] or error("Missing Target Altitude!")
local output_side = args[2] or error("Missing Output Side!")
local P = args[3] or 0.15
local I = args[4] or 0
local D = args[5] or 0.1
local Gr = {}



local S = 0
--used for integral clamping--
local minimum_value = -45 
local maximum_value = 45 --redstone
--used for integral clamping--
local continuous_scalar_pid = pidcontrollers.PID_Continuous_Scalar(P, I, D, minimum_value ,maximum_value)

local function getError()
    S = S+0.1
    return math.sin(S)*100 - target_altitude
end

local error_value = getError()

--while true do
for i = 1, 100, 1 do
    local pid_value = continuous_scalar_pid:run(error_value)
    table.insert(Gr,{S,math.sin(S)*100,pid_value})
    error_value = getError()
    
    
    
    os.sleep()
end
textutils.pagedTabulate(colors.orange, { "S","Altitude","pid"},
colors.lightBlue,table.unpack(Gr))

local f = fs.open("out.csv","w")
if f then
    f.write("S, Altitude, pid\n")
    for index, value in ipairs(Gr) do
        f.write(string.format("%d, %d, %d\n",value[1],value[2],value[3]))
    end
    f.close()
end