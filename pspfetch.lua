local ark4_font = intraFont.load("FONT.pgf", 8)

local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,'\"_+-=?/!$@&()#%*:;<>[]\\^"

local lettersSprites = {}
for i = 1, #characters do
    local char = characters:sub(i, i)
    local sprite = Image.load("symbols/" .. i .. ".png")
    if sprite then
        lettersSprites[char] = sprite
    end
end

function drawText(text, x, y, printedCharsPerLine, col)
    local CHARACTER_WIDTH = 6
    local CHARACTER_HEIGHT = 12
    local charsToShow = printedCharsPerLine or #text
    local startX = x
    col = col or Color.new(255, 255, 255)
    for i = 1, charsToShow do
        local char = text:sub(i, i)
        if char == "\n" then
            y = y + CHARACTER_HEIGHT
            x = startX
        else
            local sprite = lettersSprites[char]
            if sprite then
                Image.draweasy(sprite, x, y, col)
                x = x + CHARACTER_WIDTH
            else
                x = x + CHARACTER_WIDTH
            end
        end
    end
end

local function hex_to_color(hex)
    if not hex:match("^#%x%x%x%x%x%x$") then return nil end
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    return Color.new(r, g, b)
end

local usb_enabled = false
local colors = {
    ascii_art = Color.new(255, 255, 255),
    info = Color.new(255, 255, 255)
}
local art = {}

local function load_colors()
    if System.isFile("colors.txt") then
        local f = io.open("colors.txt", "r")
        if f then
            for line in f:lines() do
                local key, value = line:match("^%s*(%w+)%s*=%s*(.-)%s*$")
                if key and value then
                    if value:sub(1, 1) == "#" then
                        colors[key] = hex_to_color(value)
                    else
                        local named = {
                            white   = Color.new(255, 255, 255),
                            red     = Color.new(255, 0, 0),
                            green   = Color.new(0, 255, 0),
                            blue    = Color.new(0, 0, 255),
                            yellow  = Color.new(255, 255, 0),
                            cyan    = Color.new(0, 255, 255),
                            magenta = Color.new(255, 0, 255),
                            black   = Color.new(0, 0, 0)
                        }
                        colors[key] = named[value] or colors[key]
                    end
                end
            end
            f:close()
        end
    end
end

local function load_ascii_art()
    art = {}
    if System.isFile("ascii_art.txt") then
        local f = io.open("ascii_art.txt", "r")
        if f then
            for line in f:lines() do table.insert(art, line) end
            f:close()
        else
            art = { "Error: Unable to open ASCII art file." }
        end
    else
        art = { "Error: ASCII art file not found." }
    end
end

load_colors()
load_ascii_art()

local ram_used = LUA.getRAM()
local packages = 0

local function scan_directory(dir)
    if not System.isDir(dir) then return end
    local dirs = {dir}
    while #dirs > 0 do
        local cur = table.remove(dirs)
        local ok, list = pcall(System.listDir, cur)
        if ok and list then
            for _, entry in pairs(list) do
                local name = type(entry) == "table" and entry.name or entry
                if name and name ~= "." and name ~= ".." then
                    local path = cur .. "/" .. name
                    if System.isDir(path) then
                        table.insert(dirs, path)
                    elseif name:upper() == "EBOOT.PBP" or name:match("%.so$") then
                        packages = packages + 1
                    end
                end
            end
        end
    end
end

scan_directory("ms0:/PSP/GAME")
scan_directory("ms0:/PSP/GAME150")
scan_directory("ms0:/ISO")

while true do
    buttons.read()
    screen.clear(Color.new(0, 0, 0))

    if buttons.pressed(buttons.square) then
        usb_enabled = not usb_enabled
        if usb_enabled then System.USB.activate() else System.USB.deactivate() end
    end

    if buttons.pressed(buttons.circle) then LUA.exit() end

    drawText("> pspfetch", 10, 10, 40, colors.info)

    local art_start_y = 25
    for i, line in ipairs(art) do
        intraFont.print(10, art_start_y + (i - 1) * 8, line, colors.ascii or Color.new(255,255,255), ark4_font, 0.6)
    end

    local firmware = System.getOSV() or "unknown"
    local model = System.getModel() or 0

    if System.isFile("ms0:/SEPLUGINS/PLUGINS.TXT") or System.isDir("ms0:/PSP/SAVEDATA/ARK_01234") then
        local vf = io.open("ms0:/PSP/SAVEDATA/ARK_01234/VERSION.TXT", "r")
        if vf then
            local ver = vf:read("*l") or ""
            vf:close()
            firmware = ver:sub(9, 12) .. " ARK-4"
        end
    elseif firmware == "UNK" or firmware == "" then
        firmware = "unknown"
    end

    local user = System.getNickname() or "user"
    local ram_total = (model == 1000) and 32 or 64
    local cpu_mhz = System.getCPU() or 222

    local info_start_x = 170
    local info_start_y = art_start_y

    drawText(user .. "@PSP-" .. model,                      info_start_x, info_start_y,       40, colors.user)
    drawText("-------------",                               info_start_x, info_start_y + 13,  40, colors.info)
    drawText("firmware: " .. firmware,                      info_start_x, info_start_y + 28,  40, colors.info)
    drawText("kernel: PSP Custom Firmware",                 info_start_x, info_start_y + 43,  40, colors.info)
    drawText("packages: " .. packages,                      info_start_x, info_start_y + 58,  40, colors.info)
    drawText("display: 480x272 @ 60hz",                     info_start_x, info_start_y + 73,  40, colors.info)
    drawText("ram: " .. ram_total .. " MB",                 info_start_x, info_start_y + 88,  40, colors.info)
    drawText("battery: " .. System.getBatteryPercent() .. "%",
                                                            info_start_x, info_start_y + 103, 40, colors.info)
    drawText("cpu: Sony Allegrex @ " .. cpu_mhz .. "MHz",  info_start_x, info_start_y + 118, 40, colors.info)
    drawText("bus: Sony Allegrex @ " .. math.floor(cpu_mhz / 2) .. "MHz",
                                                            info_start_x, info_start_y + 133, 40, colors.info)
    drawText("gpu: Sony GPU @ 166MHz",                      info_start_x, info_start_y + 148, 40, colors.info)
    drawText("memory: " .. ram_used .. " KiB used / " .. ram_total .. " MiB",
                                                            info_start_x, info_start_y + 163, 40, colors.info)
    drawText("locale: " .. (System.getLang() or "unknown"), info_start_x, info_start_y + 178, 40, colors.info)

    local selected_colors = {colors.ascii or Color.new(255,255,255), colors.info, colors.user or Color.new(255,255,255)}
    local ix = info_start_x + 40
    local iy = info_start_y + 208
    for i, c in ipairs(selected_colors) do
        screen.drawCircle(ix + (i - 1) * 16, iy, 6, c)
    end

    drawText("> start to quit", 10, info_start_y + 215, 40, colors.ascii or Color.new(255,255,255))

    if buttons.pressed(buttons.start) then break end
    screen.flip()
end
