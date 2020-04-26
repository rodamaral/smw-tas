local M = {}

-- local config = require 'config'
local smw = require 'game.smw'
local mem = require('memory')

local WRAM = smw.WRAM
local screen_coordinates = smw.screen_coordinates
local u8 = mem.u8
local s8 = mem.s8
local s16 = mem.s16

M.store = {}
M.previous = {}

function M:refresh()
    local s = self.store

    -- variables which will be used in another stored item
    local Level_index = u8(WRAM.level_index)
    local Camera_x = s16(WRAM.camera_x)
    local Camera_y = s16(WRAM.camera_y)
    local Player_x = s16(WRAM.x)
    local Player_y = s16(WRAM.y)

    -- store all values
    s.Real_frame = u8(WRAM.real_frame)
    s.Effective_frame = u8(WRAM.effective_frame)
    s.Game_mode = u8(WRAM.game_mode)
    s.Level_index = Level_index
    s.Level_flag = u8(WRAM.level_flag_table + Level_index)
    s.Is_paused = u8(WRAM.level_paused) == 1
    s.Player_powerup = u8(WRAM.powerup)
    s.Camera_x = Camera_x
    s.Camera_y = Camera_y
    s.Yoshi_riding_flag = u8(WRAM.yoshi_riding_flag) ~= 0
    s.Player_x = Player_x
    s.Player_y = Player_y
    s.x_sub = u8(WRAM.x_sub)
    s.y_sub = u8(WRAM.y_sub)
    s.x_speed = s8(WRAM.x_speed)
    s.x_subspeed = u8(WRAM.x_subspeed)
    s.y_speed = s8(WRAM.y_speed)
    s.p_meter = u8(WRAM.p_meter)
    s.take_off = u8(WRAM.take_off)
    s.direction = u8(WRAM.direction)
    s.cape_spin = u8(WRAM.cape_spin)
    s.cape_fall = u8(WRAM.cape_fall)
    s.flight_animation = u8(WRAM.flight_animation)
    s.diving_status = s8(WRAM.diving_status)
    s.slide_flag = u8(WRAM.slide_flag)
    s.player_blocked_status = u8(WRAM.player_blocked_status)
    s.is_ducking = u8(WRAM.is_ducking)
    s.spinjump_flag = u8(WRAM.spinjump_flag)
    s.pose_turning = u8(WRAM.player_pose_turning)
    s.scroll_timer = u8(WRAM.camera_scroll_timer)
    s.vertical_scroll_flag_header = u8(WRAM.vertical_scroll_flag_header)
    s.vertical_scroll_enabled = u8(WRAM.vertical_scroll_enabled)

    s.Player_x_screen, s.Player_y_screen =
    screen_coordinates(Player_x, Player_y, Camera_x, Camera_y)
end

function M:dump() for key, value in pairs(self.store) do print(key, value) end end

function M.set_previous(key, value) M.previous[key] = value end

return M
