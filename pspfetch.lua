-- Loading the font, thanks to @seandear for helping with the font^.^
local ark4_font = font.load("FONT.pgf")

-- Symbols that the system recognizes
local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,'\"_+-=?/!$@&()#%*:;<>[]\\^"

-- Table for storing character sprites
local lettersSprites = {}

-- It is assumed that the symbol sprite files are located in the symbols folder and have names in the format "1.png", "2.png", etc.
for i = 1, #characters do
    local char = characters:sub(i, i)
    -- Use image.load to load an image from a specified path
    local sprite = image.load("symbols/" .. i .. ".png")
    if sprite then
        lettersSprites[char] = sprite
    else
        print("Failed to load image for symbol:" .. char)
    end
end

-- Function to render a string of text to the screen with support for colors from the `colors` table
function drawText(text, x, y, printedCharsPerLine, color)
    local CHARACTER_WIDTH = 6 
    local CHARACTER_HEIGHT = 12
    local lineHeight = CHARACTER_HEIGHT
    local charsToShow = printedCharsPerLine or #text
    local startX = x

    color = color or color.new(255, 255, 255)

    for i = 1, charsToShow do
        local char = text:sub(i, i)

        if char == "\n" then
            y = y + lineHeight
            x = startX
        else
            local sprite = lettersSprites[char]
            if sprite then
                image.blittint(sprite, x, y, color)
                x = x + CHARACTER_WIDTH
            else
                x = x + CHARACTER_WIDTH
                print("Unknown character: " .. char)
            end
        end
    end
end

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

local ram = os.ram()
local packages = 0

-- Function to recursively scan directories
local function scan_directory(dir)
	 for _, f in ipairs(files.list(dir)) do
		if not f.path:match("%%") then
			if f.directory and f.name ~= "." and f.name ~= ".." then
				scan_directory(f.path)
			elseif f.name:match("([^/\\]+)$"):upper() == "EBOOT.PBP" then
				packages = packages + 1
			elseif f.name:match(".*[sS][oO]$") then
				packages = packages + 1
			end
		end
	end
end

scan_directory("ms0:/PSP/GAME")
scan_directory("ms0:/PSP/GAME150")
scan_directory("ms0:/ISO")


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

    drawText("> pspfetch", 10, 10, 40, colors.info)

    local art_start_y = 25
    for i, line in ipairs(art) do
        screen.print(10, art_start_y + (i - 1) * 8, line, 0.6, colors.ascii)
    end

    local firmware = os.cfw()
    local model = hw.getmodel()

	if files.exists("ms0:/SEPLUGINS/PLUGINS.TXT") or files.exists("ms0:/PSP/SAVEDATA/ARK_01234") then
		local version = os.versiontxt()
		firmware = string.sub(version, 9, 12) .. " ARK-4"
	elseif firmware == "UNK" then
        firmware = "unknown"
    end

	local user = os.nick()
    local ram_total = 64

    if model == 1000 then
        ram_total = 32
    end

    local ram_display = string.format("%d MB", ram_total)

    local info_start_x = 170
    local info_start_y = art_start_y
    -- local info_start_y = 10

-- Info

    drawText(user .. "@" .. model, info_start_x, info_start_y, 40, colors.user)
    drawText("-------------", info_start_x, info_start_y + 13, 40, colors.info)
    drawText("firmware: " .. firmware, info_start_x, info_start_y + 28, 40, colors.info)
    drawText("kernel: " .. "PSP Custom Firmware", info_start_x, info_start_y + 43, 40, colors.info)
    drawText("packages: " .. packages, info_start_x, info_start_y + 58, 40, colors.info)
    drawText("display: " .. "480x272 @ 60hz", info_start_x, info_start_y + 73, 40, colors.info)
    drawText("ram: " .. ram_display, info_start_x, info_start_y + 88, 40, colors.info)

    local charging_status = batt.charging() and "[charging]" or "[not charging]"
    drawText("battery: " .. batt.lifepercent() .. "% " .. charging_status, info_start_x, info_start_y + 103, 40, colors.info)
    drawText("cpu: " .. "Sony Allegrex (CXD2962GG) @ " .. os.cpu() .. "MHz", info_start_x, info_start_y + 118, 40, colors.info)
    drawText("bus: " .. "Sony Allegrex (CXD2962GG) @ " .. os.bus() .. "MHz", info_start_x, info_start_y + 133, 40, colors.info)
    drawText("gpu: " .. "Sony GPU @ 166MHz", info_start_x, info_start_y + 148, 40, colors.info)
	drawText("memory: " .. math.floor(os.totalram() / 1024 / 1024)-math.floor(ram / 1024 / 1024) .. "MiB / " .. math.floor(os.totalram() / 1024 / 1024) .. "MiB", info_start_x, info_start_y + 163, 40, colors.info)
    drawText("locale: " .. os.language(), info_start_x, info_start_y + 178, 40, colors.info)

-- Color indicators

local function draw_indicators(x, y, radius, color, sections)
    local sections = sections or 30
    for i = -radius, radius do
        local line_y = y + i
        local width = math.floor(math.sqrt(radius^2 - i^2))

        draw.line(x - width, line_y, x + width, line_y, color)
    end
end

local indicators_start_x = info_start_x + 40
local indicators_start_y = info_start_y + 208
local indicators_radius = 6
local indicators_spacing = 16
local max_per_row = 30
local row_offset = 20

local auto_select_colors = false
local selected_colors = {colors.ascii, colors.info, colors.user}

local indicators_index = 0
local current_row_y = indicators_start_y

local colors_to_use = auto_select_colors and colors or selected_colors

for _, color in pairs(colors_to_use) do
    local x = indicators_start_x + (indicators_index % max_per_row) * indicators_spacing
    local y = current_row_y

    draw_indicators(x, y, indicators_radius, color)

    indicators_index = indicators_index + 1
    if indicators_index % max_per_row == 0 then
        current_row_y = current_row_y + row_offset
    end
end

drawText("> start to quit", 10, info_start_y + 215, 40, colors.ascii)

    if buttons.start then break end

    screen.flip()
end
