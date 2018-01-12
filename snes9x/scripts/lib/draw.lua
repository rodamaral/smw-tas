local draw = {}

local luap = require "luap"
local config = require "config"
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local SNES9X_FONT_HEIGHT = config.SNES9X_FONT_HEIGHT
local SNES9X_FONT_WIDTH = config.SNES9X_FONT_WIDTH
local floor = math.floor

-- Snes9x constants
draw.Border_left = 0
draw.Border_right = 0
draw.Border_top = 0
draw.Border_bottom = 0
draw.Buffer_width = 256
draw.Buffer_height = 224
draw.Buffer_middle_x = draw.Buffer_width/2
draw.Buffer_middle_y = draw.Buffer_height/2
draw.Screen_width = 256
draw.Screen_height = 224
draw.AR_x = 1
draw.AR_y = 1

-- Text/Background_max_opacity is only changed by the player using the hotkeys
-- Text/Bg_opacity must be used locally inside the functions
draw.Text_max_opacity = COLOUR.default_text_opacity
draw.Background_max_opacity = COLOUR.default_bg_opacity
draw.Outline_max_opacity = 1
draw.Text_opacity = 1
draw.Bg_opacity = 1


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
local function pixel(x, y, point, shadow)
  gui.box(x - 1, y - 1, x + 1, y + 1, color, shadow or 0)
end


-- draws a line given (x,y) and (x',y') with given scale and SNES' pixel thickness (whose scale is 2)
local function line(x1, y1, x2, y2, scale, color)
  -- Draw from top-left to bottom-right
  if x2 < x1 then
    x1, x2 = x2, x1
  end
  if y2 < y1 then
    y1, y2 = y2, y1
  end

  x1, y1, x2, y2 = scale*x1, scale*y1, scale*x2, scale*y2
  gui.line(x1, y1, x2, y2, color)
end


-- draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function box(x1, y1, x2, y2, line, bg)
  gui.box(x1, y1, x2, y2, bg, line)
end


-- draws a rectangle given (x,y) and dimensions, with SNES' pixel sizes
local function rectangle(x, y, w, h, line, bg)
  gui.box(x, y, x + w, y + h, bg, line)
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

    if x_end > buffer_width  then x = buffer_width  - text_length end
    if y_end > buffer_height then y = buffer_height - font_height end

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
  local font_width  = SNES9X_FONT_WIDTH
  local font_height = SNES9X_FONT_HEIGHT
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

  gui.opacity(draw.Text_max_opacity * draw.Text_opacity)
  gui.text(x_pos, y_pos, text, text_color, bg_color)
  gui.opacity(1.0)

  return x_pos + length, y_pos + font_height, length
end


local function alert_text(x, y, text, text_color, bg_color, always_on_game, ref_x, ref_y)
  -- Reads external variables
  local font_width  = SNES9X_FONT_WIDTH
  local font_height = SNES9X_FONT_HEIGHT

  local x_pos, y_pos, text_length = text_position(x, y, text, font_width, font_height, false, always_on_game, ref_x, ref_y)

  gui.opacity(draw.Background_max_opacity * draw.Bg_opacity)
  rectangle(x_pos, y_pos, text_length - 1, font_height - 1, bg_color, bg_color)
  gui.opacity(draw.Text_max_opacity * draw.Text_opacity)
  gui.text(x_pos, y_pos, text, text_color, 0)
  gui.opacity(1.0)
end


local function over_text(x, y, value, base, color_base, color_value, color_bg, always_on_client, always_on_game, ref_x, ref_y)
  value = luap.decode_bits(value, base)
  local x_end, y_end, length = draw_text(x, y, base,  color_base, color_bg, always_on_client, always_on_game, ref_x, ref_y)
  gui.opacity(draw.Text_max_opacity * draw.Text_opacity)
  gui.text(x_end - length, y_end - SNES9X_FONT_HEIGHT, value, color_value or COLOUR.text)
  gui.opacity(1.0)

  return x_end, y_end, length
end


-- export functions and some local variables
draw.change_transparency = change_transparency
draw.increase_opacity, draw.decrease_opacity = increase_opacity, decrease_opacity
draw.put_on_screen, draw.text_position, draw.text = put_on_screen, text_position, draw_text
draw.alert_text, draw.over_text = alert_text, over_text
draw.pixel, draw.line, draw.rectangle, draw.box = pixel, line, rectangle, box

return draw
