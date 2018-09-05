local M = {}

local memory = _G.memory

--local config = require 'config'
local smw = require 'game.smw'

local WRAM = smw.WRAM
local screen_coordinates = smw.screen_coordinates
local u8 = memory.readbyte
local s16 = memory.readsword

M.store = {}

function M:refresh()
  local s = self.store

  -- variables which will be used in another stored item
  local Level_index = u8('WRAM', WRAM.level_index)
  local Camera_x = s16('WRAM', WRAM.camera_x)
  local Camera_y = s16('WRAM', WRAM.camera_y)
  local Player_x = s16('WRAM', WRAM.x)
  local Player_y = s16('WRAM', WRAM.y)

  -- store all values
  s.Real_frame = u8('WRAM', WRAM.real_frame)
  s.Effective_frame = u8('WRAM', WRAM.effective_frame)
  s.Game_mode = u8('WRAM', WRAM.game_mode)
  s.Level_index = Level_index
  s.Level_flag = u8('WRAM', WRAM.level_flag_table + Level_index)
  s.Is_paused = u8('WRAM', WRAM.level_paused) == 1
  s.Player_powerup = u8('WRAM', WRAM.powerup)
  s.Camera_x = Camera_x
  s.Camera_y = Camera_y
  s.Yoshi_riding_flag = u8('WRAM', WRAM.yoshi_riding_flag) ~= 0
  s.Player_x = Player_x
  s.Player_y = Player_y

  s.Player_x_screen,
    s.Player_y_screen = screen_coordinates(Player_x, Player_y, Camera_x, Camera_y)
end

function M:dump()
  for key, value in pairs(self.store) do
    print(key, value)
  end
end

return M
