local M = {}

local memory,
  bit,
  gui = _G.memory, _G.bit, _G.gui

local config = require 'config'
local draw = require 'draw'
local Display = require 'display'
local smw = require 'game.smw'
local image = require 'game.image'
local store = (require 'game.state').store

local u8 = memory.readbyte
local u16 = memory.readword
local floor = math.floor
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local BITMAPS = image.bitmaps
local DBITMAPS = image.dbitmaps
local Palettes_adjusted = image.Palettes_adjusted
local X_INTERACTION_POINTS = smw.X_INTERACTION_POINTS
local Y_INTERACTION_POINTS = smw.Y_INTERACTION_POINTS

function M.draw_blocked_status(x_text, y_text, player_blocked_status, x_speed, y_speed)
  local bitmap_width = 14
  local bitmap_height = 20
  local block_str = 'Block:'
  local str_len = #(block_str)
  local xoffset = x_text + str_len * draw.font_width()
  local yoffset = y_text
  local color_line = draw.change_transparency(COLOUR.warning, draw.Text_max_opacity * draw.Text_opacity)

  local bitmap,
    pal = BITMAPS.player_blocked_status, Palettes_adjusted.player_blocked_status
  bitmap:draw(xoffset, yoffset, pal)

  local was_boosted = false

  if bit.test(player_blocked_status, 0) then -- Right
    draw.line(
      xoffset + bitmap_width - 2,
      yoffset,
      xoffset + bitmap_width - 2,
      yoffset + bitmap_height - 2,
      1,
      color_line
    )
    if x_speed < 0 then
      was_boosted = true
    end
  end

  if bit.test(player_blocked_status, 1) then -- Left
    draw.line(xoffset, yoffset, xoffset, yoffset + bitmap_height - 2, 1, color_line)
    if x_speed > 0 then
      was_boosted = true
    end
  end

  if bit.test(player_blocked_status, 2) then -- Down
    draw.line(
      xoffset,
      yoffset + bitmap_height - 2,
      xoffset + bitmap_width - 2,
      yoffset + bitmap_height - 2,
      1,
      color_line
    )
  end

  if bit.test(player_blocked_status, 3) then -- Up
    draw.line(xoffset, yoffset, xoffset + bitmap_width - 2, yoffset, 1, color_line)
    if y_speed > 6 then
      was_boosted = true
    end
  end

  if bit.test(player_blocked_status, 4) then -- Middle
    gui.crosshair(
      xoffset + floor(bitmap_width / 2),
      yoffset + floor(bitmap_height / 2),
      floor(math.min(bitmap_width / 2, bitmap_height / 2)),
      color_line
    )
  end

  draw.text(x_text, y_text, block_str, COLOUR.text, was_boosted and COLOUR.warning_bg or nil)
end

-- displays player's hitbox
function M.player_hitbox(x, y, is_ducking, powerup, transparency_level, palette)
  -- Colour settings
  local interaction_bg,
    mario_line,
    interaction_points_palette
  interaction_bg = draw.change_transparency(COLOUR.interaction_bg, transparency_level)
  mario_line = draw.change_transparency(COLOUR.mario, transparency_level)

  if not palette then
    if transparency_level == 1 then
      interaction_points_palette = DBITMAPS.interaction_points_palette
    else
      interaction_points_palette = draw.copy_palette(DBITMAPS.interaction_points_palette)
      interaction_points_palette:adjust_transparency(floor(transparency_level * 256))
    end
  else
    interaction_points_palette = palette
  end

  -- don't use Camera_x/y midframe, as it's an old value
  local x_screen,
    y_screen = screen_coordinates(x, y, store.Camera_x, store.Camera_y)
  local is_small = is_ducking ~= 0 or powerup == 0
  local hitbox_type = 2 * (store.Yoshi_riding_flag and 1 or 0) + (is_small and 0 or 1) + 1

  local left_side = X_INTERACTION_POINTS.left_side
  local right_side = X_INTERACTION_POINTS.right_side
  local head = Y_INTERACTION_POINTS[hitbox_type].head
  local foot = Y_INTERACTION_POINTS[hitbox_type].foot

  local hitbox_offsets = smw.PLAYER_HITBOX[hitbox_type]
  local xoff = hitbox_offsets.xoff
  local yoff = hitbox_offsets.yoff
  local width = hitbox_offsets.width
  local height = hitbox_offsets.height

  -- background for block interaction
  draw.box(
    x_screen + left_side,
    y_screen + head,
    x_screen + right_side,
    y_screen + foot,
    2,
    interaction_bg,
    interaction_bg
  )

  -- Collision with sprites
  if OPTIONS.display_player_hitbox then
    local mario_bg = (not store.Yoshi_riding_flag and COLOUR.mario_bg) or COLOUR.mario_mounted_bg
    draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, mario_line, mario_bg)
  end

  -- interaction points (collision with blocks)
  if OPTIONS.display_interaction_points then
    if not OPTIONS.display_player_hitbox then
      draw.box(
        x_screen + left_side,
        y_screen + head,
        x_screen + right_side,
        y_screen + foot,
        2,
        COLOUR.interaction_nohitbox,
        COLOUR.interaction_nohitbox_bg
      )
    end

    gui.bitmap_draw(
      draw.AR_x * x_screen,
      draw.AR_y * y_screen,
      DBITMAPS.interaction_points[hitbox_type],
      interaction_points_palette
    )
  end

  -- That's the pixel that appears when Mario dies in the pit
  Display.show_player_point_position =
    Display.show_player_point_position or Display.is_player_near_borders or OPTIONS.display_debug_player_extra
  if Display.show_player_point_position then
    draw.pixel(x_screen, y_screen, COLOUR.text, COLOUR.interaction_bg)
    Display.show_player_point_position = false
  end
end

-- displays the hitbox of the cape while spinning
function M.cape_hitbox(spin_direction)
  local cape_interaction = u8('WRAM', WRAM.cape_interaction)
  if cape_interaction == 0 then
    return
  end

  local cape_x = u16('WRAM', WRAM.cape_x)
  local cape_y = u16('WRAM', WRAM.cape_y)

  local cape_x_screen,
    cape_y_screen = screen_coordinates(cape_x, cape_y, store.Camera_x, store.Camera_y)
  local cape_left = -2
  local cape_right = 0x12
  local cape_up = 0x01
  local cape_down = 0x11
  local cape_middle = 0x08
  local block_interaction_cape = (spin_direction < 0 and cape_left + 4) or cape_right - 4
  local active_frame_sprites = store.Real_frame % 2 == 1 -- active iff the cape can hit a sprite
  -- active iff the cape can hit a block
  local active_frame_blocks = store.Real_frame % 2 == (spin_direction < 0 and 0 or 1)

  local bg_color = active_frame_sprites and COLOUR.cape_bg or -1
  draw.box(
    cape_x_screen + cape_left,
    cape_y_screen + cape_up,
    cape_x_screen + cape_right,
    cape_y_screen + cape_down,
    2,
    COLOUR.cape,
    bg_color
  )

  if active_frame_blocks then
    draw.pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, COLOUR.warning)
  else
    draw.pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, COLOUR.text)
  end
end

return M
