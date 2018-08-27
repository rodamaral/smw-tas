local M = {}

local memory = _G.memory

local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'
_G.commands = require 'commands'

local COLOUR = config.COLOUR
local SMW = smw.constant
local WRAM = smw.WRAM
local fmt = string.format
local u8 = memory.readbyte

local function display_OW_exits()
  draw.Font = false
  local x = draw.Buffer_width
  local y = draw.AR_y * 24
  local h = draw.font_height()

  draw.text(x, y, 'Beaten exits:' .. u8('WRAM', 0x1f2e))
  for i = 0, 15 - 1 do
    y = y + h
    local byte = u8('WRAM', 0x1f02 + i)
    draw.over_text(x, y, byte, '76543210', COLOUR.weak, 'red')
  end
end

function M.info()
  if u8('WRAM', WRAM.game_mode) ~= SMW.game_mode_overworld then
    return
  end

  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local height = draw.font_height()
  local y_text = 0

  -- Real frame modulo 8
  local Real_frame = u8('WRAM', WRAM.real_frame)
  local real_frame_8 = Real_frame % 8
  draw.text(
    draw.Buffer_width + draw.Border_right,
    y_text,
    fmt('Real Frame = %3d = %d(mod 8)', Real_frame, real_frame_8),
    true
  )

  -- Star Road info
  local star_speed = u8('WRAM', WRAM.star_road_speed)
  local star_timer = u8('WRAM', WRAM.star_road_timer)
  y_text = y_text + height
  draw.text(
    draw.Buffer_width + draw.Border_right,
    y_text,
    fmt('Star Road(%x %x)', star_speed, star_timer),
    COLOUR.cape,
    true
  )

  -- beaten exits
  display_OW_exits()
end

return M
