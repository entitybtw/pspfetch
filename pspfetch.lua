-- Loading the font, thanks to @seandear for helping with the font^.^
local ark4_font = font.load("FONT.pgf")

-- Converting hex code to color

local function hex_to_color(hex)
    if not hex:match("^#%x%x%x%x%x%x$") then
        return nil 
    end

    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    return color.new(r, g, b)
end

-- Misc

local usb_enabled = false
local colors = {
    ascii_art = color.new(255, 255, 255),
    info = color.new(255, 255, 255)
}
local art = {}

-- Loading colors

local function load_colors()
    local colors_path = "colors.txt"
    if files.exists(colors_path) then
        local colors_file = io.open(colors_path, "r")
        if colors_file then
            for line in colors_file:lines() do
                local key, value = string.match(line, "^%s*(%w+)%s*=%s*(.-)%s*$")
                
                if key and value then
                    if value:sub(1, 1) == "#" then
                        colors[key] = hex_to_color(value)
                    else
                        local named_colors = {
                            white = color.new(255, 255, 255),
                            red = color.new(255, 0, 0),
                            green = color.new(0, 255, 0),
                            blue = color.new(0, 0, 255),
                            yellow = color.new(255, 255, 0),
                            cyan = color.new(0, 255, 255),
                            magenta = color.new(255, 0, 255),
                            black = color.new(0, 0, 0)
                        }
                        colors[key] = named_colors[value] or colors[key]
                    end
                end
            end
            colors_file:close()
        end
    end
end


-- Loading ASCII art

local function load_ascii_art()
    art = {}
    local art_path = "ascii_art.txt"
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

-- Set the default font

font.setdefault(ark4_font)

-- Buttons

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

-- Misc

    local art_start_y = 10
    for i, line in ipairs(art) do
        screen.print(10, art_start_y + (i - 1) * 8, line, 0.6, colors.ascii)
    end

    local firmware = os.cfw()
    local model = hw.getmodel()

    if firmware == "UNK" then
        firmware = "unknown"
    end

    local user = os.nick()
    local ram_total = 64

    if model == 1000 then
        ram_total = 32
    end

    local ram_display = string.format("%d MB", ram_total)

    local info_start_x = 170
    local info_start_y = 10

-- Info

    screen.print(info_start_x, info_start_y, user .. "@" .. model, 0.4, colors.user)
    screen.print(info_start_x, info_start_y + 13, "-------------", 0.6, colors.info)
    screen.print(info_start_x, info_start_y + 28, "firmware: " .. firmware, 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 43, "kernel: " .. "PSP Custom Firmware", 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 58, "packages: " .. "n/d", 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 73, "display: " .. "480x272 @ 60hz", 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 88, "ram: " .. ram_display, 0.4, colors.info)
    local charging_status = batt.charging() and "[charging]" or "[not charging]"
    screen.print(info_start_x, info_start_y + 103, "battery: " .. batt.lifepercent() .. "% " .. charging_status, 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 118, "cpu clock: " .. os.cpu() .. " mhz", 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 133, "bus clock: " .. os.bus() .. " mhz", 0.4, colors.info)
    screen.print(info_start_x, info_start_y + 148, "locale: " .. os.language(), 0.4, colors.info)

    if buttons.start then break end

    screen.flip()
end
