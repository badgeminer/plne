-- https://pinestore.cc/projects/48/emulauncher

settings.load()
settings.define("launcher.names", {
  description = "Table of computer names to be shown by EmuLauncher",
  type = "table",
  default = {}
})
settings.define("launcher.last", {
  description = "Last computer launched by EmuLauncher",
  type = "number",
  default = os.getComputerID()
})

local offsetY = 0
local cursorY = settings.get("launcher.last") + 1

local names = settings.get("launcher.names")

function saveSettings()
  settings.set("launcher.names", names)
  settings.save()
end

-- Migration
if fs.exists("/.man") then
  local file = fs.open("/.man", "r")
  names = textutils.unserialize(file.readAll())
  file.close()
  fs.delete("/.man")

  names["_VERSION"] = nil
  saveSettings()
end

function getSize()
  local w, h = term.getSize()
  return w, h - 1
end

function resolveColor(color)
  if type(color) == "string" then
    return colors[color] or colours[color]
  elseif type(color) == "number" then
    return color
  end
end

function setColor(textColor, bgColor)
  textColor = resolveColor(textColor)
  bgColor = resolveColor(bgColor)
  if textColor then
    term.setTextColor(textColor)
  end
  if bgColor then
    term.setBackgroundColor(bgColor)
  end
end

function resetColors()
  setColor("white", "black")
end

function helpText(text)
  local _, height = term.getSize()

  setColor("white", "gray")
  term.setCursorPos(2, height)
  term.clearLine()
  term.write(text)

  resetColors()
end

function successText(text)
  setColor("black", "lime")
  term.setCursorPos(2, cursorY)
  term.clearLine()
  term.write(text)

  sleep(1)
  resetColors()
end

function errorText(text)
  helpText("[Enter] Continue")

  setColor("white", "red")
  term.setCursorPos(2, cursorY)
  term.clearLine()
  term.write(text)

  os.pullEvent("key")
  resetColors()
end

function draw()
  local width, height = getSize()
  -- term.clear()
  for y = 1, height, 1 do
    local id = offsetY + y - 1
    term.setCursorPos(2, y)
    if y == cursorY then
      setColor("black", "yellow")
    else
      setColor("white", "black")
    end
    term.clearLine()
    local name = getPCName(id)
    if name == "" then
      setColor("gray")
      if y == cursorY then
        term.write("Computer #" .. id)
      else
        term.write("---")
      end
    else
      term.write(name)
    end
  end

  -- helpText("PC#" .. (offsetY + cursorY - 1) .. " [R]ename [D]ata [C]onfig")
  helpText("[R] Rename [D] Data [C] Config")
end

function getPCName(id)
  if names[id] then
    return names[id]
  elseif id == os.getComputerID() then
    return "This Computer"
  else
    -- return id
    return ""
  end
end

function update()
  local _, height = getSize()
  if height == 0 then
    return
  end
  local minY = 1
  local maxY = height
  if height > 15 then
    minY = 7
    maxY = height - 6
  elseif height > 10 then
    minY = 5
    maxY = height - 4
  elseif height > 5 then
    minY = 3
    maxY = height - 2
  end

  if offsetY == 0 then
    minY = 1
  end
  if cursorY < minY then
    repeat
      offsetY = offsetY - 1
      cursorY = cursorY + 1
    until cursorY == minY
  end
  if cursorY > maxY then
    repeat
      offsetY = offsetY + 1
      cursorY = cursorY - 1
    until cursorY == maxY
  end
  if offsetY < 0 then
    offsetY = 0
  end
end

draw()
while true do
  local eventData = { os.pullEvent() }
  local event = eventData[1]
  -- local key = keys.getName(keyCode)
  if event == "mouse_scroll" then
    local _, dir, x, y = unpack(eventData)
    -- print(dir, x, y)
    cursorY = cursorY + dir
  elseif event == "mouse_click" or event == "mouse_drag" then
    local _, button, x, y = unpack(eventData)
    if button == 1 then -- left click
      cursorY = y
    end
  elseif event == "key" then
    local _, key, held = unpack(eventData)

    if key == keys.up then
      cursorY = cursorY - 1
    elseif key == keys.down then
      cursorY = cursorY + 1
    elseif key == keys.left then
      cursorY = cursorY - 5
    elseif key == keys.right then
      cursorY = cursorY + 5
    elseif key == keys.pageUp then
      cursorY = cursorY - 10
    elseif key == keys.pageDown then
      cursorY = cursorY + 10
    elseif key == keys.home then
      offsetY = 0
      cursorY = 1
    elseif key == keys.r then
      local id = offsetY + cursorY - 1
      helpText("Renaming Computer #" .. id)
      term.setCursorPos(1, cursorY)
      setColor("black", "lightBlue")
      term.clearLine()
      local name = names[id] or ""
      write(">" .. name)
      term.setCursorPos(2, cursorY)
      os.pullEvent("key_up")
      name = read(nil, nil, nil, name)
      names[id] = name ~= "" and name or nil
      saveSettings()
    elseif key == keys.d then
      local id = offsetY + cursorY - 1
      if ccemux then
        local res = ccemux.openDataDir(id)
        if res then
          successText("Opened data folder")
        else
          errorText("Unable to open data folder")
        end
      else
        errorText("CCEmuX API Required")
      end
    elseif key == keys.c then
      if ccemux then
        local res = ccemux.openConfig()
        if res then
          successText("Opened config editor")
        else
          errorText("Unable to open config")
        end
      else
        errorText("CCEmuX API Required")
      end
    elseif key == keys.enter then
      local id = offsetY + cursorY - 1
      if id ~= os.getComputerID() then
        local res
        local tried = true
        if ccemux then
          res = ccemux.openEmu(id)
        elseif periphemu then -- CraftOS-PC
          res = periphemu.create(id, "computer")
        else
          tried = false
          errorText("CCEmuX API Required")
        end
        -- Only possible on CraftOS-PC
        if tried and not res then
          errorText("Computer already running")
        else
          settings.set("launcher.last", id)
          saveSettings()
          successText("Opened computer ID " .. id)
        end
      else
        settings.set("launcher.last", id)
        saveSettings()
        break
      end
    end
  end
  update()
  draw()
end

term.clear()
term.setCursorPos(1, 1)
