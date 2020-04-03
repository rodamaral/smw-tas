local M = {}

local gui, settings, identify_class, tostringx, bit, callback = _G.gui, _G.settings,
                                                                _G.identify_class, _G.tostringx,
                                                                _G.bit, _G.callback

local config = require 'config'
local Timer = require 'timer'
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH
local CUSTOM_FONTS = config.CUSTOM_FONTS
local floor = math.floor

M.button_list = {}

-- Text/Background_max_opacity is only changed by the player using the hotkeys
-- Text/Bg_opacity must be used locally inside the functions
M.Text_max_opacity = COLOUR.default_text_opacity
M.Background_max_opacity = COLOUR.default_bg_opacity
M.Outline_max_opacity = 1
M.Text_opacity = 1
M.Bg_opacity = 1

-- Verify whether the fonts exist
M.font = {}
for key, value in pairs(CUSTOM_FONTS) do
    if key ~= false and value.file then
        if not io.open(value.file, 'r') then
            print('WARNING:', string.format('couldn\'t open font: ./%s', value.file))
            CUSTOM_FONTS[key] = nil -- this makes the width/heigth work correctly if the font is not loaded
            M.font[key] = gui.text
        else
            M.font[key] = gui.font.load(value.file) -- issue: contrary to the io library, ./folder is not valid here
        end
    else
        M.font[key] = gui.text
    end
end

-- Get screen values of the game and emulator areas
local function lsnes_screen_info()
    M.Padding_left = tonumber(settings.get('left-border')) -- Advanced configuration padding dimensions
    M.Padding_right = tonumber(settings.get('right-border'))
    M.Padding_top = tonumber(settings.get('top-border'))
    M.Padding_bottom = tonumber(settings.get('bottom-border'))

    M.Border_left = math.max(M.Padding_left, OPTIONS.left_gap) -- Borders' dimensions
    M.Border_right = math.max(M.Padding_right, OPTIONS.right_gap)
    M.Border_top = math.max(M.Padding_top, OPTIONS.top_gap)
    M.Border_bottom = math.max(M.Padding_bottom, OPTIONS.bottom_gap)

    M.Buffer_width, M.Buffer_height = gui.resolution() -- Game area
    M.Buffer_middle_x = math.floor(M.Buffer_width / 2)
    M.Buffer_middle_y = math.floor(M.Buffer_height / 2)

    M.Screen_width = M.Buffer_width + M.Border_left + M.Border_right -- Emulator area
    M.Screen_height = M.Buffer_height + M.Border_top + M.Border_bottom

    M.AR_x = 2
    M.AR_y = 2

    -- AVI dump settings
    M.avi_large = settings.get('avi-large') == 'yes' and true or false
    M.avi_xfactor = tonumber(settings.get('avi-xfactor')) -- normally 0
    M.avi_yfactor = tonumber(settings.get('avi-yfactor')) -- normally 0
    M.avi_top_border = tonumber(settings.get('avi-top-border')) -- normally 0
    M.avi_bottom_border = tonumber(settings.get('avi-bottom-border')) -- normally 0
    M.avi_left_border = tonumber(settings.get('avi-left-border')) -- normally 0
    M.avi_right_border = tonumber(settings.get('avi-right-border')) -- normally 0
end

-- Some extension to gui
local function font_width(font)
    local font = OPTIONS.use_custom_fonts and M.Font or false
    return CUSTOM_FONTS[font] and CUSTOM_FONTS[font].width or LSNES_FONT_WIDTH
end

local function font_height(font)
    local font = OPTIONS.use_custom_fonts and M.Font or false
    return CUSTOM_FONTS[font] and CUSTOM_FONTS[font].height or LSNES_FONT_HEIGHT
end

-- Bitmap functions
local function copy_bitmap(src)
    local width, height = src:size()
    local dest = gui.bitmap.new(width, height)
    dest:blit(0, 0, src, 0, 0, width, height)

    return dest
end

local function copy_dbitmap(src)
    local width, height = src:size()
    local dest = gui.dbitmap.new(width, height)
    dest:blit(0, 0, src, 0, 0, width, height)

    return dest
end

local function copy_palette(pal)
    local copy = gui.palette.new()

    for index = 0, 65535 do
        local color = pal:get(index)
        if not color then break end

        copy:set(index, color)
    end

    return copy
end

local function bitmap_to_dbitmap(bitmap, palette)
    local w, h = bitmap:size()
    local dbitmap = gui.dbitmap.new(w, h)
    local index, color

    for x = 0, w - 1 do
        for y = 0, h - 1 do
            index = bitmap:pget(x, y)
            color = palette:get(index)
            dbitmap:pset(x, y, color)
        end
    end

    return dbitmap
end

local function dbitmap_to_bitmap(dbitmap)
    local w, h = dbitmap:size()
    local bitmap = gui.bitmap.new(w, h)
    local palette = gui.palette.new()
    local colours = {}
    local index = 0

    for x = 0, w - 1 do
        for y = 0, h - 1 do
            local color = dbitmap:pget(x, y)

            if not colours[color] then
                colours[color] = index
                palette:set(index, color)
                index = index + 1
            end

            bitmap:pset(x, y, colours[color])
        end
    end

    return bitmap, palette
end

local function palettes_to_adjust(src, dest)
    M.palettes_source = src
    M.palettes_destination = dest
end

-- Background opacity functions
local function adjust_palette_transparency(src, dest)
    src = src or M.palettes_source
    dest = dest or M.palettes_destination
    for key, obj in pairs(src) do
        if identify_class(obj) == 'PALETTE' then
            dest[key] = M.copy_palette(obj)
            dest[key]:adjust_transparency(floor(256 * M.Background_max_opacity * M.Bg_opacity))
        end
    end
end

local function increase_opacity()
    if M.Text_max_opacity <= 0.9 then
        M.Text_max_opacity = M.Text_max_opacity + 0.1
    else
        if M.Background_max_opacity <= 0.9 then
            M.Background_max_opacity = M.Background_max_opacity + 0.1
        end
    end

    adjust_palette_transparency()
end

local function decrease_opacity()
    if M.Background_max_opacity >= 0.1 then
        M.Background_max_opacity = M.Background_max_opacity - 0.1
    else
        if M.Text_max_opacity >= 0.1 then M.Text_max_opacity = M.Text_max_opacity - 0.1 end
    end

    adjust_palette_transparency()
end

-- Changes transparency of a color: result is opaque original * transparency level (0.0 to 1.0)
local function change_transparency(color, transparency)
    -- Sane transparency
    if transparency >= 1 then return color end -- no transparency
    if transparency <= 0 then return -1 end -- total transparency

    -- Sane colour
    if color == -1 then return -1 end
    if type(color) ~= 'number' then color = gui.color(color) end

    local a = math.floor(color / 0x1000000)
    local rgb = color - (a * 0x1000000)
    local new_a = 0x100 - math.ceil((0x100 - a) * transparency)
    return (new_a * 0x1000000) + rgb
end

-- Takes a position and dimensions of a rectangle and returns a new position
-- if this rectangle has points outside the screen
local function put_on_screen(x, y, width, height)
    local x_screen, y_screen
    width = width or 0
    height = height or 0

    if x < -M.Border_left then
        x_screen = -M.Border_left
    elseif x > M.Buffer_width + M.Border_right - width then
        x_screen = M.Buffer_width + M.Border_right - width
    else
        x_screen = x
    end

    if y < -M.Border_top then
        y_screen = -M.Border_top
    elseif y > M.Buffer_height + M.Border_bottom - height then
        y_screen = M.Buffer_height + M.Border_bottom - height
    else
        y_screen = y
    end

    return x_screen, y_screen
end

-- returns the (x, y) position to start the text and its length:
-- number, number, number text_position(x, y, text, font_width, font_height[[[[, always_on_client],
--   always_on_game], ref_x], ref_y])
-- x, y: the coordinates that the refereed point of the text must have
-- text: a string, don't make it bigger than the buffer area width and don't include escape characters
-- font_width, font_height: the sizes of the font
-- always_on_client, always_on_game: boolean
-- ref_x and ref_y: refer to the relative point of the text that must occupy the origin (x,y), from 0% to 100%
--            for instance, if you want to display the middle of the text in (x, y), then use 0.5, 0.5
local function text_position(x, y, text, font_width, font_height, always_on_client, always_on_game,
                             ref_x, ref_y)
    -- Reads external variables
    local border_left = M.Border_left
    local border_right = M.Border_right
    local border_top = M.Border_top
    local border_bottom = M.Border_bottom
    local buffer_width = M.Buffer_width
    local buffer_height = M.Buffer_height

    -- text processing
    local text_type = type(text)
    if text_type == 'number' and text < 0 then
        text = string.format('%+d', text)
    elseif text and text_type ~= 'string' then
        text = tostringx(text)
    end
    local text_length = text and #(text) * font_width or font_width -- considering another objects, like bitmaps

    -- actual position, relative to game area origin
    x = (not ref_x and x) or (ref_x == 0 and x) or x - floor(text_length * ref_x)
    y = (not ref_y and y) or (ref_y == 0 and y) or y - floor(font_height * ref_y)

    -- adjustment needed if text is supposed to be on screen area
    local x_end = x + text_length
    local y_end = y + font_height

    if always_on_game then
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end

        if x_end > buffer_width then x = buffer_width - text_length end
        if y_end > buffer_height then y = buffer_height - font_height end
    elseif always_on_client then
        if x < -border_left then x = -border_left end
        if y < -border_top then y = -border_top end

        if x_end > buffer_width + border_right then
            x = buffer_width + border_right - text_length
        end
        if y_end > buffer_height + border_bottom then
            y = buffer_height + border_bottom - font_height
        end
    end

    return x, y, text_length
end

-- Complex function for drawing, that uses text_position
local function draw_text(x, y, text, ...)
    -- Reads external variables
    local font_name = OPTIONS.use_custom_fonts and M.Font or false
    local font_width = M.font_width()
    local font_height = M.font_height()

    -- Background type preference
    local full_bg, bg_default_color
    if OPTIONS.text_background_type == 'full' then
        full_bg = true
    elseif OPTIONS.text_background_type == 'outline' then
        full_bg = false
    else
        full_bg = font_name == false
    end
    bg_default_color = COLOUR[full_bg and 'background' or 'outline']

    local text_color, bg_color, always_on_client, always_on_game, ref_x, ref_y
    local arg1, arg2, arg3, arg4, arg5, arg6 = ...

    if not arg1 or arg1 == true then
        text_color = COLOUR.text
        bg_color = bg_default_color
        always_on_client, always_on_game, ref_x, ref_y = arg1, arg2, arg3, arg4
    elseif not arg2 or arg2 == true then
        text_color = arg1
        bg_color = bg_default_color
        always_on_client, always_on_game, ref_x, ref_y = arg2, arg3, arg4, arg5
    else
        text_color, bg_color = arg1, arg2
        always_on_client, always_on_game, ref_x, ref_y = arg3, arg4, arg5, arg6
    end

    text_color = change_transparency(text_color, M.Text_max_opacity * M.Text_opacity)
    bg_color = change_transparency(bg_color, full_bg and M.Background_max_opacity * M.Bg_opacity or
                                   M.Text_max_opacity * M.Text_opacity)
    local x_pos, y_pos, length = text_position(x, y, text, font_width, font_height,
                                               always_on_client, always_on_game, ref_x, ref_y)

    -- draw correct font with correct background type
    if font_name then
        if full_bg then
            M.font[font_name](x_pos, y_pos, text, text_color, bg_color)
        else
            M.font[font_name](x_pos, y_pos, text, text_color, nil, bg_color)
        end
    else
        if full_bg then
            gui.text(x_pos, y_pos, text, text_color, bg_color)
        else
            gui.text(x_pos, y_pos, text, text_color, nil, bg_color)
        end
    end

    return x_pos + length, y_pos + font_height, length
end

local function alert_text(x, y, text, text_color, bg_color, always_on_game, ref_x, ref_y)
    -- Reads external variables
    local font_width = LSNES_FONT_WIDTH
    local font_height = LSNES_FONT_HEIGHT

    local x_pos, y_pos, text_length = text_position(x, y, text, font_width, font_height, false,
                                                    always_on_game, ref_x, ref_y)

    text_color = change_transparency(text_color, M.Text_max_opacity * M.Text_opacity)
    bg_color = change_transparency(bg_color, M.Background_max_opacity * M.Bg_opacity)
    gui.text(x_pos, y_pos, text, text_color, bg_color)
end

local function over_text(x, y, value, base, color_base, color_value, color_bg, always_on_client,
                         always_on_game, ref_x, ref_y)
    value = bit.rflagdecode(value, #base, string.reverse(base), ' ')
    local x_end, y_end, length = draw_text(x, y, base, color_base, color_bg, always_on_client,
                                           always_on_game, ref_x, ref_y)
    M.font[M.Font](x_end - length, y_end - M.font_height(), value, color_value or COLOUR.text)

    return x_end, y_end, length
end

local function draw_message(message, timeout)
    Timer.unregisterfunction('draw_message')

    timeout = timeout or 2000000
    Timer.registerfunction(timeout, function()
        gui.text(0, M.Buffer_height - 2 * LSNES_FONT_HEIGHT, message, COLOUR.text, nil,
                 COLOUR.outline)
    end, 'draw_message')
end

-- draw a pixel given (x,y) with SNES' pixel sizes
local function pixel(x, y, point, shadow)
    gui.rectangle(M.AR_x * x - 2, M.AR_y * y - 2, M.AR_x * 3, M.AR_y * 3, M.AR_x, shadow or -1,
                  point)
end

-- draws a line given (x,y) and (x',y') with given scale and SNES' pixel thickness (whose scale is 2)
local function line(x1, y1, x2, y2, scale, ...)
    x1, y1, x2, y2 = scale * x1, scale * y1, scale * x2, scale * y2
    if x1 == x2 then
        gui.line(x1, y1, x2, y2 + 1, ...)
        gui.line(x1 + 1, y1, x2 + 1, y2 + 1, ...)
    elseif y1 == y2 then
        gui.line(x1, y1, x2 + 1, y2, ...)
        gui.line(x1, y1 + 1, x2 + 1, y2 + 1, ...)
    else
        gui.line(x1, y1, x2, y2, ...)
        gui.line(x1 + 1, y1, x2 + 1, y2, ...)
        gui.line(x1, y1 + 1, x2, y2 + 1, ...)
        gui.line(x1 + 1, y1 + 1, x2 + 1, y2 + 1, ...)
    end
end

-- draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function box(x1, y1, x2, y2, ...)
    -- Draw from top-left to bottom-right
    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end

    local x = M.AR_x * x1
    local y = M.AR_y * y1
    local w = (M.AR_x * (x2 - x1)) + 2 -- adds thickness
    local h = (M.AR_y * (y2 - y1)) + 2 -- adds thickness

    gui.rectangle(x, y, w, h, ...)
end

-- draws a rectangle given (x,y) and dimensions, with SNES' pixel sizes
local function rectangle(x, y, w, h, ...)
    x, y, w, h = M.AR_x * x, M.AR_y * y, M.AR_x * w + 2, M.AR_y * h + 2
    gui.rectangle(x, y, w, h, 2, ...)
end

-- displays a button everytime in (x,y)
-- object can be a text or a dbitmap
-- if user clicks onto it, fn is executed once
local function button(x, y, object, fn, extra_options)
    local always_on_client, always_on_game, ref_x, ref_y, button_pressed
    if extra_options then
        always_on_client, always_on_game, ref_x, ref_y, button_pressed =
        extra_options.always_on_client, extra_options.always_on_game, extra_options.ref_x,
        extra_options.ref_y, extra_options.button_pressed
    end

    local width, height
    local object_type = type(object)

    if object_type == 'string' then
        width, height = M.font_width(), M.font_height()
        x, y, width = M.text_position(x, y, object, width, height, always_on_client, always_on_game,
                                      ref_x, ref_y)
    elseif object_type == 'userdata' then -- lsnes specific
        width, height = object:size()
        x, y = M.text_position(x, y, nil, width, height, always_on_client, always_on_game, ref_x,
                               ref_y)
    elseif object_type == 'boolean' then
        width, height = M.font_width(), M.font_height()
        x, y = M.text_position(x, y, nil, width, height, always_on_client, always_on_game, ref_x,
                               ref_y)
    else
        error 'Type of buttton not supported yet'
    end

    -- draw the button
    if button_pressed then
        gui.box(x, y, width, height, 1, 0x808080, 0xffffff, 0xe0e0e0) -- unlisted colour
    else
        gui.box(x, y, width, height, 1)
    end

    if object_type == 'string' then
        M.font[M.Font](x, y, object, COLOUR.button_text)
    elseif object_type == 'userdata' then
        object:draw(x, y)
    elseif object_type == 'boolean' then
        gui.solidrectangle(x + 1, y + 1, width - 2, height - 2, 0x00ff00) -- unlisted colour
    end

    -- updates the table of buttons
    table.insert(M.button_list,
                 {x = x, y = y, width = width, height = height, object = object, action = fn})
end

-- export functions and some local variables
M.lsnes_screen_info = lsnes_screen_info
M.change_transparency = change_transparency
M.font_width, M.font_height = font_width, font_height
M.copy_bitmap, M.copy_dbitmap, M.copy_palette = copy_bitmap, copy_dbitmap, copy_palette
M.bitmap_to_dbitmap, M.dbitmap_to_bitmap = bitmap_to_dbitmap, dbitmap_to_bitmap
M.palettes_to_adjust, M.adjust_palette_transparency = palettes_to_adjust,
                                                      adjust_palette_transparency
M.increase_opacity, M.decrease_opacity = increase_opacity, decrease_opacity
M.put_on_screen, M.text_position, M.text = put_on_screen, text_position, draw_text
M.alert_text, M.over_text, M.message = alert_text, over_text, draw_message
M.pixel, M.line, M.rectangle, M.box = pixel, line, rectangle, box
M.button = button

-- execute:
callback.register('paint', function() M.button_list = {} end)

return M
