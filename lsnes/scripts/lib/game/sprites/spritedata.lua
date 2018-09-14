local M = {}

local memory,
  gui,
  bit = _G.memory, _G.gui, _G.bit

local config = require('config')
local draw = require('draw')
local widget = require('widget')
local smw = require('game.smw')

local u8 = memory.readbyte
local u16 = memory.readword
local WRAM = smw.WRAM
local OPTIONS = config.OPTIONS

--[[ local function scan_sprite_data()
  --do something
end ]]
local MAX_SPRITE_DATA_SIZE = 0x80

local function get_alive()
  local alive = {}
  for slot = 0, 11 do
    if u8('WRAM', 0x14c8 + slot) ~= 0 then
      local index = u8('WRAM', 0x161a + slot)
      alive[index] = true
    end
  end
  return alive
end

function M.display_room_data()
  widget:set_property('sprite_load_status', 'display_flag', OPTIONS.display_sprite_load_status)
  if not OPTIONS.display_sprite_load_status then
    return
  end

  draw.Font = 'Uzebox6x8'
  local height = draw.font_height()
  local width = draw.font_width()
  local x0 = draw.AR_x * widget:get_property('sprite_load_status', 'x')
  local y0 = draw.AR_y * widget:get_property('sprite_load_status', 'y')

  local header = memory.readhword('WRAM', 0xce)
  local screen_number = u8('WRAM', 0x5e) + 1
  local cameraX = u16('WRAM', 0x1462)
  local cameraY = u16('WRAM', 0x1464)
  local xt,
    yt = x0, y0
  local sprite = header + 1

  -- if inside ROM
  if (sprite % 0x10000) < 0x8000 and (sprite + 3 * 128 % 0x10000) < 0x8000 then
    return
  end

  local area = memory.readregion('BUS', sprite, 3 * MAX_SPRITE_DATA_SIZE)
  local alive = get_alive()

  for id = 0, MAX_SPRITE_DATA_SIZE - 1 do
    -- parse sprite data
    local byte0 = area[3 * id]
    local byte1 = area[3 * id + 1]
    local byte2 = area[3 * id + 2]
    if byte0 == 0xFF then
      break
    end

    local Y = (byte0 % 2 == 1 and 16 or 0) + math.floor(byte0 / 16)
    local x_screen = (bit.test(byte0, 1) and 16 or 0) + (byte1 % 16)
    local X = math.floor(byte1 / 16)

    local xpos = 16 * (x_screen * 16 + X)
    local ypos = 16 * Y

    local number = byte2
    local color = x_screen <= screen_number and 0x80808080 or 0xff00ff

    -- sprite color according to status
    local onscreen = u8('WRAM', 0x1938 + id) ~= 0
    if onscreen then
      color = 0xffffff
      if not alive[id] then
        color = 0xff0000
      end
    end
    draw.text(xt, yt, string.format('%.2d: %.2x (%4d, %3d)', id, number, xpos, ypos), color, 0)
    yt = yt + height

    -- draw sprite data on position
    do
      draw.Font = 'Uzebox8x12'
      draw.text(2 * (xpos - cameraX), 2 * (ypos - cameraY), id, color, 0x40000040)
      gui.crosshair(2 * (xpos - cameraX), 2 * (ypos - cameraY), 8, 'red')
      draw.Font = 'Uzebox6x8'
    end

    -- update text position
    if (id + 1) % 16 == 0 then
      yt = y0
      xt = xt + 19 * width
    end
  end
end

return M
