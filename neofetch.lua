local function hex_to_color(hex)
    if not hex:match("^#%x%x%x%x%x%x$") then
        return nil 
    end

    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    return color.new(r, g, b)
end

local usb_enabled = false
local colors = {
    ascii_art = color.new(255, 255, 255),
    info = color.new(255, 255, 255)
}
local art = {}

local function load_colors()
    local colors_path = "ms0:/PSP/GAME/ONEluav4R1/colors.txt"
    if files.exists(colors_path) then
        local colors_file = io.open(colors_path, "r")
        if colors_file then
            for line in colors_file:lines() do
                local trimmed_line = line:match("^%s*(.-)%s*$")
                local key, value = string.match(trimmed_line, "^(%w+)%s*=%s*(%S+)")
                if key and value then
                    if value:sub(1, 1) == "#" then
                        local color_from_hex = hex_to_color(value)
                        if color_from_hex then
                            colors[key] = color_from_hex
                        end
                    elseif value == "white" then
                        colors[key] = color.new(255, 255, 255)
                    elseif value == "red" then
                        colors[key] = color.new(255, 0, 0)
                    elseif value == "green" then
                        colors[key] = color.new(0, 255, 0)
                    elseif value == "blue" then
                        colors[key] = color.new(0, 0, 255)
                    elseif value == "yellow" then
                        colors[key] = color.new(255, 255, 0)
                    elseif value == "cyan" then
                        colors[key] = color.new(0, 255, 255)
                    elseif value == "magenta" then
                        colors[key] = color.new(255, 0, 255)
                    elseif value == "black" then
                        colors[key] = color.new(0, 0, 0)
                    end
                end
            end
            colors_file:close()
        end
    end
end

local function load_ascii_art()
    art = {}
    local art_path = "ms0:/PSP/GAME/ONEluav4R1/ascii_art.txt"
    if files.exists(art_path) then
        local art_file = io.open(art_path, "r")
        if art_file then
            for line in art_file:lines() do
                table.insert(art, line)
            end
            art_file:close()
        else
            art = { "Error: Unable to open ASCII art file." }
        end
    else
        art = { "Error: ASCII art file not found." }
    end
end

load_colors()
load_ascii_art()

while true do
    buttons.read()

    screen.clear(color.new(0, 0, 0))

    if buttons.square then
        usb_enabled = not usb_enabled
        if usb_enabled then
            usb.mstick()
        else
            usb.stop()
        end
    end

    if buttons.circle then
        os.restart()
    end

    local art_start_y = 10
    for i, line in ipairs(art) do
        screen.print(10, art_start_y + (i - 1) * 8, line, 0.6, colors.ascii_art)
    end

    local firmware = os.cfw()
    local model = hw.getmodel()

    if firmware == "UNK" then
        firmware = "Unknown Firmware"
    end

    local user = os.nick()
    local ram_total = 64

    if model == 1000 then
        ram_total = 32
    end

    local ram_display = string.format("%d MB", ram_total)

    local info_start_x = 120
    local info_start_y = 10

    screen.print(info_start_x, info_start_y, user .. "@" .. model, 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 20, "Firmware: " .. firmware, 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 40, "RAM: " .. ram_display, 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 60, "Battery: " .. batt.lifepercent() .. "%", 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 80, "Charging: " .. (batt.charging() and "Yes" or "No"), 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 100, "CPU Clock: " .. os.cpu() .. " MHz", 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 120, "Bus Clock: " .. os.bus() .. " MHz", 0.5, colors.info)
    -- screen.print(info_start_x, info_start_y + 140, "Language: " .. os.language(), 0.5, colors.info)
    screen.print(info_start_x, info_start_y + 140, "Press START to exit", 0.5, colors.info)

    if buttons.start then break end

    screen.flip()
end
