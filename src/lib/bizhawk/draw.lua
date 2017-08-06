local draw = {}

local luap = require "luap"
local biz = biz or require "bizhawk.biz"
local config = require "config"
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local BIZHAWK_FONT_HEIGHT = config.BIZHAWK_FONT_HEIGHT
local BIZHAWK_FONT_WIDTH = config.BIZHAWK_FONT_WIDTH
local floor = math.floor

-- Text/Background_max_opacity is only changed by the player using the hotkeys
-- Text/Bg_opacity must be used locally inside the functions
draw.Text_max_opacity = COLOUR.default_text_opacity
draw.Background_max_opacity = COLOUR.default_bg_opacity
draw.Outline_max_opacity = 1
draw.Text_opacity = 1
draw.Bg_opacity = 1


-- Correct gui.text
local gui_text
if biz.features.gui_text_backcolor then
  if biz.features.backcolor_default_arg then
    function gui_text(x, y, text, forecolor, backcolor)
      gui.text(x, y, text, backcolor, forecolor)
    end
  else
    function gui_text(x, y, text, forecolor, backcolor)
      gui.text(x, y, text, forecolor, backcolor)
    end
  end
else
  function gui_text(x, y, text, forecolor, backcolor)
    gui.text(x, y, text, forecolor)
  end
end

-- Get screen values of the game and emulator areas
local function bizhawk_screen_info()
  draw.Left_gap = OPTIONS.left_gap
  draw.Top_gap = OPTIONS.top_gap
  draw.Right_gap = OPTIONS.right_gap
  draw.Bottom_gap = OPTIONS.bottom_gap

  draw.Screen_width = client.screenwidth()  -- Screen area
  draw.Screen_height = client.screenheight()
  draw.Buffer_width = client.bufferwidth()  -- Game area
  draw.Buffer_height = client.bufferheight()
  draw.Border_left = client.borderwidth()  -- Borders' dimensions
  draw.Border_top = client.borderheight()

  -- Derived dimensions
  draw.Buffer_middle_x = floor(draw.Buffer_width/2)
  draw.Buffer_middle_y = floor(draw.Buffer_height/2)
  draw.Border_right = draw.Screen_width - draw.Buffer_width - draw.Border_left
  draw.Border_bottom = draw.Screen_height - draw.Buffer_height - draw.Border_top
  draw.AR_x = draw.Screen_width/(draw.Buffer_width + draw.Left_gap + draw.Right_gap)
  draw.AR_y = draw.Screen_height/(draw.Buffer_height + draw.Top_gap + draw.Bottom_gap)
end


local function increase_opacity()
  if draw.Text_max_opacity <= 0.9 then draw.Text_max_opacity = draw.Text_max_opacity + 0.1
  else
    if draw.Background_max_opacity <= 0.9 then draw.Background_max_opacity = draw.Background_max_opacity + 0.1 end
  end
end


local function decrease_opacity()
  if  draw.Background_max_opacity >= 0.1 then draw.Background_max_opacity = draw.Background_max_opacity - 0.1
  else
    if draw.Text_max_opacity >= 0.1 then draw.Text_max_opacity = draw.Text_max_opacity - 0.1 end
  end
end


-- Changes transparency of a color: result is opaque original * transparency level (0.0 to 1.0)
local function change_transparency(color, transparency)
  -- Sane transparency
  if transparency >= 1 then return color end  -- no transparency
  if transparency <= 0 then return 0 end   -- total transparency

  -- Sane colour
  if color == 0 then return 0 end
  if type(color) ~= "number" then
    print(color)
    error"Wrong color"
  end

  local a = floor(color/0x1000000)
  local rgb = color - a*0x1000000
  local new_a = floor(a*transparency)
  return new_a*0x1000000 + rgb
end


-- Takes a position and dimensions of a rectangle and returns a new position if this rectangle has points outside the screen
local function put_on_screen(x, y, width, height)
  local x_screen, y_screen
  width = width or 0
  height = height or 0

  if x < - draw.Border_left then
    x_screen = - draw.Border_left
  elseif x > draw.Buffer_width + draw.Border_right - width then
    x_screen = draw.Buffer_width + draw.Border_right - width
  else
    x_screen = x
  end

  if y < - draw.Border_top then
    y_screen = - draw.Border_top
  elseif y > draw.Buffer_height + draw.Border_bottom - height then
    y_screen = draw.Buffer_height + draw.Border_bottom - height
  else
    y_screen = y
  end

  return x_screen, y_screen
end


-- draw a pixel given (x,y) with SNES' pixel sizes
local function pixel(x, y, color, shadow)
  gui.drawRectangle(x + draw.Left_gap - 1, y + draw.Top_gap - 1, 2, 2, shadow or 0, color)
end


-- draws a line given (x,y) and (x',y') with given scale and SNES' pixel thickness
-- not necessary to draw from top-left to bottom-right in BizHawk
local function line(x1, y1, x2, y2, color)
  gui.drawLine(x1 + draw.Left_gap, y1 + draw.Top_gap, x2 + draw.Left_gap, y2 + draw.Top_gap, color)
end


-- draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function box(x1, y1, x2, y2, line, bg)
  gui.drawBox(x1 + draw.Left_gap, y1 + draw.Top_gap, x2 + draw.Left_gap, y2 + draw.Top_gap, line, bg)
end


-- draws a rectangle given (x,y) and dimensions, with SNES' pixel sizes
local function rectangle(x, y, w, h, line, bg)
  gui.drawRectangle(x + draw.Left_gap, y + draw.Top_gap, w, h, line, bg)
end


-- returns the (x, y) position to start the text and its length:
-- number, number, number text_position(x, y, text, font_width, font_height[[[[, always_on_client], always_on_game], ref_x], ref_y])
-- x, y: the coordinates that the refereed point of the text must have
-- text: a string, don't make it bigger than the buffer area width and don't include escape characters
-- font_width, font_height: the sizes of the font
-- always_on_client, always_on_game: boolean
-- ref_x and ref_y: refer to the relative point of the text that must occupy the origin (x,y), from 0% to 100%
--            for instance, if you want to display the middle of the text in (x, y), then use 0.5, 0.5
local function text_position(x, y, text, font_width, font_height, always_on_client, always_on_game, ref_x, ref_y)
  -- Reads external variables
  local border_left    = draw.Border_left
  local border_right   = draw.Border_right
  local border_top     = draw.Border_top
  local border_bottom  = draw.Border_bottom
  local buffer_width   = draw.Buffer_width
  local buffer_height  = draw.Buffer_height

  -- text processing
  local text_length = text and string.len(text)*font_width or font_width  -- considering another objects, like bitmaps

  -- actual position, relative to game area origin
  x = (not ref_x and x) or (ref_x == 0 and x) or x - floor(text_length*ref_x)
  y = (not ref_y and y) or (ref_y == 0 and y) or y - floor(font_height*ref_y)

  -- adjustment needed if text is supposed to be on screen area
  local x_end = x + text_length
  local y_end = y + font_height

  if always_on_game then
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    if x_end > buffer_width*draw.AR_x  then x = buffer_width*draw.AR_x - text_length end
    if y_end > buffer_height*draw.AR_y then y = buffer_height*draw.AR_y - font_height end

  elseif always_on_client then
    if x < -border_left then x = -border_left end
    if y < -border_top  then y = -border_top  end

    if x_end > buffer_width  + border_right  then x = buffer_width  + border_right  - text_length end
    if y_end > buffer_height + border_bottom then y = buffer_height + border_bottom - font_height end
  end

  return x, y, text_length
end


-- Complex function for drawing, that uses text_position
local function draw_text(x, y, text, ...)
  -- Reads external variables
  local font_width  = BIZHAWK_FONT_WIDTH
  local font_height = BIZHAWK_FONT_HEIGHT
  local bg_default_color = COLOUR.outline
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

  local x_pos, y_pos, length = text_position(x, y, text, font_width, font_height,
                      always_on_client, always_on_game, ref_x, ref_y)
  ;

  text_color = change_transparency(text_color, draw.Text_max_opacity * draw.Text_opacity)
  bg_color = change_transparency(bg_color, draw.Text_max_opacity * draw.Text_opacity)
  gui_text(x_pos + draw.Border_left, y_pos + draw.Border_top, text, text_color, bg_color)

  return x_pos + length, y_pos + font_height, length
end


local function alert_text(x, y, text, text_color, bg_color, always_on_game, ref_x, ref_y)
  -- Reads external variables
  local font_width  = BIZHAWK_FONT_WIDTH
  local font_height = BIZHAWK_FONT_HEIGHT

  local x_pos, y_pos, text_length = text_position(x, y, text, font_width, font_height, false, always_on_game, ref_x, ref_y)

  if not bg_color then bg_color = COLOUR.background end
  text_color = change_transparency(text_color, draw.Text_max_opacity * draw.Text_opacity)
  bg_color = change_transparency(bg_color, draw.Background_max_opacity * draw.Bg_opacity)

  box(x_pos/draw.AR_x, y_pos/draw.AR_y, (x_pos + text_length)/draw.AR_x + 2, (y_pos + font_height)/draw.AR_y + 1, 0, bg_color)
  gui_text(x_pos + draw.Border_left, y_pos + draw.Border_top, text, text_color, 0)
end


local function over_text(x, y, value, base, color_base, color_value, color_bg, always_on_client, always_on_game, ref_x, ref_y)
  value = luap.decode_bits(value, base)
  local x_end, y_end, length = draw_text(x, y, base,  color_base, color_bg, always_on_client, always_on_game, ref_x, ref_y)

  change_transparency(color_value or COLOUR.text, draw.Text_max_opacity * draw.Text_opacity)
  gui_text(x_end + draw.Border_left - length, y_end + draw.Border_top - BIZHAWK_FONT_HEIGHT, value, color_value, 0)

  return x_end, y_end, length
end


-- export functions and some local variables
draw.bizhawk_screen_info = bizhawk_screen_info
draw.change_transparency = change_transparency
draw.increase_opacity, draw.decrease_opacity = increase_opacity, decrease_opacity
draw.put_on_screen, draw.text_position, draw.text = put_on_screen, text_position, draw_text
draw.alert_text, draw.over_text = alert_text, over_text
draw.pixel, draw.line, draw.rectangle, draw.box = pixel, line, rectangle, box

return draw
