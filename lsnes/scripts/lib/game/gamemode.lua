local M = {}

local memory = _G.memory

local config = require('config')
local draw = require('draw')
local onclick = require('onclick')
local state = require('game.state')
local tile = require('game.tile')
local countdown = require('game.countdown')
local misc = require('game.misc')
local smw = require('game.smw')
local limits = require('game.limits')
local player = require('game.player')
local sprite = require('game.sprites.sprite')
local generators = require('game.sprites.generator')
local extended = require('game.sprites.extended')
local cluster = require('game.sprites.cluster')
local minorextended = require('game.sprites.minorextended')
local bounce = require('game.sprites.bounce')
local quake = require('game.sprites.quake')
local shooter = require('game.sprites.shooter')
local score = require('game.sprites.score')
local smoke = require('game.sprites.smoke')
local coin = require('game.sprites.coin')
local spritedata = require('game.sprites.spritedata')
local yoshi = require('game.sprites.yoshi')
local blockdup = require('game.blockdup')
_G.commands = require('commands')

local COLOUR = config.COLOUR
local SMW = smw.constant
local WRAM = smw.WRAM
local fmt = string.format
local u8 = memory.readbyte
local store = state.store

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

-- Main function to run inside a level
function M.level_mode()
  if SMW.game_mode_fade_to_level <= store.Game_mode and store.Game_mode <= SMW.game_mode_level then
    -- Draws/Erases the tiles if user clicked
    --map16.display_known_tiles()
    tile.draw_layer1(store.Camera_x, store.Camera_y)
    tile.draw_layer2()
    limits.draw_boundaries()
    limits.display_despawn_region()
    limits.display_spawn_region()
    sprite.info()
    extended.sprite_table()
    cluster.sprite_table()
    minorextended.sprite_table()
    bounce.sprite_table()
    quake.sprite_table()
    shooter.sprite_table()
    score.sprite_table()
    smoke.sprite_table()
    coin.sprite_table()
    misc.level_info()
    spritedata.display_room_data()
    player.info()
    yoshi.info()
    countdown.show_counters()
    generators:info()
    blockdup.predict_block_duplications()
    onclick.toggle_sprite_hitbox()
  end
end

return M
