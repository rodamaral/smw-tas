local M = {}

local GLOBAL_SMW_TAS_PARENT_DIR, gui = _G.GLOBAL_SMW_TAS_PARENT_DIR, _G.gui

local config = require 'config'
local draw = require 'draw'

local BMP_STRINGS = config.BMP_STRINGS

-- Hitboxes
local interaction_points = {}
local interaction_points_palette
local interaction_points_palette_alt = gui.palette.new()
local base = GLOBAL_SMW_TAS_PARENT_DIR .. 'images/hitbox/'

interaction_points[1], interaction_points_palette =
gui.image.load_png('interaction_points_1.png', base)
interaction_points[2] = gui.image.load_png('interaction_points_2.png', base)
interaction_points[3] = gui.image.load_png('interaction_points_3.png', base)
interaction_points[4] = gui.image.load_png('interaction_points_4.png', base)

interaction_points_palette_alt:set(1, 0xff)
interaction_points_palette_alt:set(2, 0xe0ff0000)
interaction_points_palette_alt:set(3, 0xff00)

-- Sprites' pictures
base = _G.GLOBAL_SMW_TAS_PARENT_DIR .. 'images/'

local yoshi_full_mouth = gui.image.load_png('yoshi_full_mouth.png', base)
local yoshi_full_mouth_trans = draw.copy_dbitmap(yoshi_full_mouth)
yoshi_full_mouth_trans:adjust_transparency(0x60)

local dbitmaps = {
    goal_tape = gui.image.load_png_str(BMP_STRINGS.goal_tape),
    interaction_points = interaction_points,
    interaction_points_palette = interaction_points_palette,
    interaction_points_palette_alt = interaction_points_palette_alt,
    red_berry = gui.image.load_png('red-berry.png', base),
    pink_berry = gui.image.load_png('pink-berry.png', base),
    yoshi_full_mouth = yoshi_full_mouth,
    yoshi_full_mouth_trans = yoshi_full_mouth_trans,
    yoshi_tongue = gui.image.load_png('yoshi_tongue.png', base),
}

-- Bitmaps and dbitmaps
local player_blocked_status, player_blocked_status_palette =
gui.image.load_png_str(BMP_STRINGS.player_blocked_status)

local bitmaps = {player_blocked_status = player_blocked_status}

local palettes = {player_blocked_status = player_blocked_status_palette}

-- Adjusted palettes
local Palettes_adjusted = {}

M.bitmaps = bitmaps
M.dbitmaps = dbitmaps
M.palettes = palettes
M.Palettes_adjusted = Palettes_adjusted

return M
