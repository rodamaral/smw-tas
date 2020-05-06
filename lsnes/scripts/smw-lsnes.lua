---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for Lsnes - rr2 version
--  http://tasvideos.org/Lsnes.html
--
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------
-- #############################################################################
-- CONFIG:
local GLOBAL_SMW_TAS_PARENT_DIR = _G.GLOBAL_SMW_TAS_PARENT_DIR
local lsnes_features, callback, gui = _G.lsnes_features, _G.callback, _G.gui

assert(GLOBAL_SMW_TAS_PARENT_DIR, 'smw-tas.lua must be run')
local INI_CONFIG_NAME = 'lsnes-config.ini'
local LUA_SCRIPT_FILENAME = load([==[return @@LUA_SCRIPT_FILENAME@@]==])()
local LUA_SCRIPT_FOLDER = LUA_SCRIPT_FILENAME:match('(.+)[/\\][^/\\+]') .. '/'
local INI_CONFIG_FILENAME = GLOBAL_SMW_TAS_PARENT_DIR .. 'config/' .. INI_CONFIG_NAME
-- TODO: save the config file in the parent directory;
--       must make the JSON library work for the other scripts first

-- END OF CONFIG < < < < < < <
-- #############################################################################
-- INITIAL STATEMENTS:

print(string.format('Starting script %s', LUA_SCRIPT_FILENAME))

-- Script verifies whether the emulator is indeed Lsnes - rr2 version / beta23 or higher
if not lsnes_features or not lsnes_features('text-halos') then
    callback.paint:register(function()
        gui.text(0, 00, 'This script is supposed to be run on Lsnes.', 'red', 0x600000ff)
        gui.text(0, 16, 'Version: rr2-beta23 or higher.', 'red', 0x600000ff)
        gui.text(0, 32, 'Your version seems to be different.', 'red', 0x600000ff)
        gui.text(0, 48, 'Download the correct script at:', 'red', 0x600000ff)
        gui.text(0, 64, 'https://github.com/rodamaral/smw-tas/wiki/Downloads', 'red', 0x600000ff)
        gui.text(0, 80, 'Download the latest version of lsnes here', 'red', 0x600000ff)
        gui.text(0, 96, 'http://tasvideos.org/Lsnes.html', 'red', 0x600000ff)
    end)
    gui.repaint()
    error('This script works in a newer version of lsnes.')
end

-- Load environment
package.path = LUA_SCRIPT_FOLDER .. 'lib/?.lua' .. ';'
        .. GLOBAL_SMW_TAS_PARENT_DIR .. 'lua_modules/share/lua/5.3/?.lua' .. ';'
        .. package.path

local movie, memory = _G.movie, _G.memory
local string, math, pairs = _G.string, _G.math, _G.pairs
local exec, set_idle_timeout = _G.exec, _G.set_idle_timeout

local luap = require('luap')
local config = require('config')
config.load_options(INI_CONFIG_FILENAME)
config.load_lsnes_fonts(GLOBAL_SMW_TAS_PARENT_DIR .. 'lsnes')
local keyinput = require('keyinput')
local mem = require('memory')
-- local Timer = require('timer')
local draw = require('draw')
local lsnes = require('lsnes')
local joypad = require('joypad')
local widget = require('widget')
local cheat = require('cheat')
local Options_menu = require('menu')
local Lagmeter = require('lagmeter')
local Display = require('display')
local movieinfo = require('movieinfo')
local onclick = require('onclick')
local on_input = require 'events.input'
local on_frame_emulated = require 'events.frame_emulated'
local misc = require('game.misc')
local smw = require('game.smw')
local tile = require('game.tile')
local RNG = require('game.rng')
local gamecontroller = require('game.controller')
local smwdebug = require('game.smwdebug')
local player = require('game.player')
local Sprites_info = require('game.sprites.spriteinfo')
local image = require('game.image')
local gamemode = require('game.gamemode')
local collision = require('game.collision').new()
local state = require('game.state')
_G.commands = require('commands')
_G.ibind = require('ibind')
local Ghost_player -- for late require/unrequire

local floor = math.floor
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT
local WRAM = smw.WRAM
local DEBUG_REGISTER_ADDRESSES = smw.DEBUG_REGISTER_ADDRESSES
local controller = lsnes.controller
local User_input = keyinput.key_state
local store = state.store
local DBITMAPS = image.dbitmaps
local PALETTES = image.palettes
local Palettes_adjusted = image.Palettes_adjusted

config.filename = INI_CONFIG_FILENAME
config.raw_data = {['LSNES OPTIONS'] = OPTIONS}

-- Compatibility of the memory read/write functions
local u8 = mem.u8
local s16 = mem.s16

-- Hotkeys availability  -- TODO: error if key is invalid
print(string.format('Hotkey \'%s\' set to increase opacity.', OPTIONS.hotkey_increase_opacity))
print(string.format('Hotkey \'%s\' set to decrease opacity.', OPTIONS.hotkey_decrease_opacity))

-- #############################################################################
-- SCRIPT UTILITIES:

-- Variables used in various functions
local Paint_context = gui.renderctx.new(256, 224) -- lsnes specific
local Midframe_context = gui.renderctx.new(256, 224) -- lsnes specific
local Address_change_watcher = {}
local Registered_addresses = {}
local Readonly_on_timer

-- test
player.use_render_context(Midframe_context)

widget:new('player', 0, 32)
widget:new('yoshi', 0, 88)
widget:new('miscellaneous_sprite_table', 0, 180)
widget:new('sprite_load_status', 256, 224)
widget:new('RNG.predict', 224, 112)
widget:new('spriteMiscTables', 256, 126)

-- #############################################################################
-- SMW FUNCTIONS:

local function scan_smw()
    Display.is_player_near_borders = store.Player_x_screen <= 32 or store.Player_x_screen >= 0xd0 or
                                     store.Player_y_screen <= -100 or store.Player_y_screen >= 224
end

-- Creates lateral gaps
local function create_gaps()
    gui.left_gap(OPTIONS.left_gap) -- for input display
    gui.right_gap(OPTIONS.right_gap)
    gui.top_gap(OPTIONS.top_gap)
    gui.bottom_gap(OPTIONS.bottom_gap)
end

-- This function runs at the end of paint callback
-- Specific for info that changes if the emulator is paused and idle callback is called
local function lsnes_yield()
    -- Widget buttons
    -- moves blocks of info when button is held
    widget:display_all()
    widget:drag_widget()

    -- Font
    draw.Font = false

    if not Options_menu.show_menu and User_input.mouse_inwindow == 1 then
        draw.button(-draw.Border_left, -draw.Border_top, 'Menu',
                    function() Options_menu.show_menu = true end, {always_on_client = true})

        draw.button(0, 0, '↓', function()
            OPTIONS.display_controller_input = not OPTIONS.display_controller_input
        end, {always_on_client = true, ref_x = 1.0, ref_y = 1.0})
        draw.button(-draw.Border_left, draw.Buffer_height + draw.Border_bottom,
                    cheat.allow_cheats and 'Cheats: allowed' or 'Cheats: blocked', function()
            cheat.allow_cheats = not cheat.allow_cheats
            draw.message('Cheats ' .. (cheat.allow_cheats and 'allowed.' or 'blocked.'))
        end, {always_on_client = true, ref_y = 1.0})

        draw.button(draw.Buffer_width + draw.Border_right, draw.Buffer_height + draw.Border_bottom,
                    'Erase Tiles', function()
            tile.layer1 = {}
            tile.layer2 = {}
        end, {always_on_client = true, ref_y = 1.0})
        -- Quick save movie/state buttons
        draw.Font = 'Uzebox6x8'
        draw.text(0, draw.Buffer_height - 2 * draw.font_height(), 'Save?', COLOUR.text,
                  COLOUR.background)

        draw.button(0, draw.Buffer_height, 'Movie', function()
            local hint = movie.get_rom_info()[1].hint
            local current_time = string.gsub(luap.luap.system_time(), ':', '.')
            local filename = string.format('%s-%s(MOVIE).lsmv', current_time, hint)
            if not luap.file_exists(filename) then
                exec('save-movie ' .. filename)
                draw.message('Pending save-movie: ' .. filename, 3000)
                return
            else
                print('Movie ' .. filename .. ' already exists.', 3000000)
                draw.message('Movie ' .. filename .. ' already exists.')
                return
            end
        end, {always_on_game = true})
        draw.button(5 * draw.font_width() + 1, draw.Buffer_height + LSNES_FONT_HEIGHT, 'State',
                    function()
            local hint = movie.get_rom_info()[1].hint
            local current_time = string.gsub(luap.luap.system_time(), ':', '.')
            local filename = string.format('%s-%s(STATE).lsmv', current_time, hint)
            if not luap.file_exists(filename) then
                exec('save-state ' .. filename)
                draw.message('Pending save-state: ' .. filename, 3000)
                return
            else
                print('State ' .. filename .. ' already exists.')
                draw.message('State ' .. filename .. ' already exists.', 3000)
                return
            end
        end, {always_on_game = true})
        -- Free movement cheat
        -- display button to toggle the free movement state
        if cheat.allow_cheats then
            draw.Font = 'Uzebox8x12'
            local x, y, dx, dy = 0, 0, draw.font_width(), draw.font_height()
            draw.font[draw.Font](x, y, 'Free movement cheat ', COLOUR.warning, COLOUR.weak, 0)
            draw.button(x + 20 * dx, y, cheat.free_movement.is_applying or ' ', function()
                cheat.free_movement.is_applying = not cheat.free_movement.is_applying
            end)

            -- display free movement options if it's active
            if cheat.free_movement.is_applying then
                y = y + dy
                draw.font[draw.Font](x, y, 'Type:', COLOUR.button_text, COLOUR.weak)
                draw.button(x + 5 * dx, y,
                            cheat.free_movement.manipulate_speed and 'Speed' or ' Pos ', function()
                    cheat.free_movement.manipulate_speed = not cheat.free_movement.manipulate_speed
                end)
                y = y + dy
                draw.font[draw.Font](x, y, 'invincibility:', COLOUR.button_text, COLOUR.weak)
                draw.button(x + 14 * dx, y, cheat.free_movement.give_invincibility or ' ',
                            function()
                    cheat.free_movement.give_invincibility =
                    not cheat.free_movement.give_invincibility
                end)
                y = y + dy
                draw.font[draw.Font](x, y, 'Freeze animation:', COLOUR.button_text, COLOUR.weak)
                draw.button(x + 17 * dx, y, cheat.free_movement.freeze_animation or ' ', function()
                    cheat.free_movement.freeze_animation = not cheat.free_movement.freeze_animation
                end)
                y = y + dy
                draw.font[draw.Font](x, y, 'Unlock camera:', COLOUR.button_text, COLOUR.weak)
                draw.button(x + 14 * dx, y, cheat.free_movement.unlock_vertical_camera or ' ',
                            function()
                    cheat.free_movement.unlock_vertical_camera =
                    not cheat.free_movement.unlock_vertical_camera
                end)
            end
        end

        Options_menu.adjust_lateral_gaps()
    else
        if cheat.allow_cheats then -- show cheat status anyway
            draw.Font = 'Uzebox6x8'
            draw.text(-draw.Border_left, draw.Buffer_height + draw.Border_bottom, 'Cheats: allowed',
                      COLOUR.warning, true, false, 0.0, 1.0)
        end
    end

    -- Drag and drop sprites with the mouse
    if cheat.is_dragging_sprite then
        -- TODO: avoid many parameters in function
        cheat.drag_sprite(cheat.dragging_sprite_id, store.Game_mode, Sprites_info, store.Camera_x,
                          store.Camera_y)
        cheat.is_cheating = true
    end

    Options_menu.display()
end

-- #############################################################################
-- MAIN --

_G.on_input = on_input:new(joypad)

_G.on_frame_emulated = on_frame_emulated:new({
    options = OPTIONS,
    state = state,
    movieinfo = movieinfo,
    address_watcher = Address_change_watcher,
    registered_addresses = Registered_addresses
})

function _G.on_snoop2(p, c --[[ , b, v ]] )
    -- Clear stuff after emulation of frame has started
    if p == 0 and c == 0 then
        Registered_addresses.mario_position = ''
        Midframe_context:clear()

        collision:reset()
    end
end

function _G.on_frame()
    if not movie.rom_loaded() then -- only useful with null ROM
        gui.repaint()
    end
end

function _G.on_paint(received_frame)
    -- Initial values, don't make drawings here
    keyinput.get_mouse()
    lsnes.get_status()
    draw.lsnes_screen_info()
    lsnes.get_movie_info()
    create_gaps()
    state:refresh()

    -- If the paint request occurs just after a load state, don't render new elements
    if lsnes.preloading_state then
        Paint_context:run()
        return
    end

    Paint_context:clear()
    Paint_context:set()

    -- gets back to default paint context / video callback doesn't capture anything
    if not controller.info_loaded then return end

    -- Dark filter to cover the game area
    if OPTIONS.filter_opacity ~= 0 then
        gui.solidrectangle(0, 0, draw.Buffer_width, draw.Buffer_height, COLOUR.filter_color)
    end

    -- Drawings are allowed now
    if Ghost_player then Ghost_player.renderctx:run() end
    scan_smw()
    gamemode.level_mode()
    gamemode.info()
    movieinfo.display()
    misc.global_info()
    RNG.display_RNG()
    gamecontroller.display()

    if OPTIONS.display_controller_input then
        lsnes.frame, lsnes.port, lsnes.controller, lsnes.button = lsnes.display_input() -- test: fix names
    end

    -- ACE debug info
    if OPTIONS.register_ACE_debug_callback then
        draw.Font = 'Uzebox6x8'
        local y, height = LSNES_FONT_HEIGHT, draw.font_height()
        local count = 0

        for index in pairs(DEBUG_REGISTER_ADDRESSES.active) do
            draw.text(draw.Buffer_width, y, DEBUG_REGISTER_ADDRESSES[index][3], false, true)
            y = y + height
            count = count + 1
        end

        if count > 0 then
            draw.Font = false
            draw.text(draw.Buffer_width, 0, 'ACE helper:', COLOUR.warning, COLOUR.warning_bg, false,
                      true)
        end
    end

    Lagmeter.display()
    collision:display()
    cheat.is_cheat_active()

    -- Comparison ghost
    --[[ if OPTIONS.show_comparison_ghost and Ghost_player then
    Ghost_player.comparison(received_frame)
  end ]]
    -- gets back to default paint context / video callback doesn't capture anything
    gui.renderctx.setnull()
    Paint_context:run()

    -- display warning if recording OSD
    if state.previous.video_callback then
        draw.text(0, draw.Buffer_height,
                  OPTIONS.make_lua_drawings_on_video and 'Capturing OSD' or 'NOT capturing OSD',
                  COLOUR.warning, true, true)
        if received_frame then state.set_previous('video_callback', false) end
    end

    -- on_timer registered functions
    -- Timer.on_paint()

    lsnes_yield()
end

function _G.on_video()
    if OPTIONS.make_lua_drawings_on_video then
        -- Scale the video to the same dimensions of the emulator
        gui.set_video_scale(2, 2)

        -- Renders the same context of on_paint over video
        Paint_context:run()
        if Ghost_player then Ghost_player.renderctx:run() end
        create_gaps()
    end

    state.set_previous('video_callback', true)
end

-- Loading a state
function _G.on_pre_load()
    -- Resets special WRAM addresses for changes
    for _, inner in pairs(Address_change_watcher) do
        inner.watching_changes = false
        inner.info = ''
    end
    Registered_addresses.mario_position = ''
    Midframe_context:clear()
end

function _G.on_post_load --[[ name, was_savestate ]] ()
    movieinfo.set_lagged(false)
    Lagmeter.Mcycles = false

    -- ACE debug info
    if OPTIONS.register_ACE_debug_callback then
        for index in pairs(DEBUG_REGISTER_ADDRESSES.active) do
            DEBUG_REGISTER_ADDRESSES.active[index] = nil
        end
    end

    collision:reset()
    collectgarbage()
    gui.repaint()
end

function _G.on_err_save(name) draw.message('Failed saving state ' .. name) end

-- Functions called on specific events
function _G.on_readwrite()
    draw.message('Read-Write mode')
    gui.repaint()
end

function _G.on_rewind()
    draw.message('Movie rewound to beginning')
    movieinfo.set_lagged(false)
    Lagmeter.Mcycles = false
    lsnes.Lastframe_emulated = nil

    gui.repaint()
end

-- Repeating callbacks
-- FIXME:
-- function _G.on_timer()
--     state.previous.readonly_on_timer = Readonly_on_timer -- artificial callback on_readonly
--     Readonly_on_timer = movie.readonly()
--     if (Readonly_on_timer and not state.previous.readonly_on_timer) then
--         draw.message('Read-Only mode')
--     end
--
--     set_timer_timeout(OPTIONS.timer_period) -- calls on_timer forever
-- end

-- local foo = require('timeout')
-- local set_timeout = foo.set_timeout
-- local clear_timeout = foo.clear_timeout
-- set_timeout(function()
--     print(1, 1500)
-- end, 1500)
-- local handle = set_timeout(function()
--     print(2, 4000)
--
--     set_timeout(function()
--         print(3, 6000)
--     end, 2000)
-- end, 4000)
--
-- local handle2
-- handle2 = set_timeout(function()
--     print(4, 2000)
--     clear_timeout(handle)
--
--     set_timeout(function()
--         print(5, 3900)
--         clear_timeout(handle2)
--
--         set_timeout(function()
--             print(6, 5900)
--         end, 2000)
--     end, 1900)
-- end, 2000)
-- set_timeout(function()
--     print(7, 5000)
-- end, 5000)
-- print('handles', handle, handle2)

function _G.on_idle()
    if User_input.mouse_inwindow == 1 then gui.repaint() end

    set_idle_timeout(OPTIONS.idle_period) -- calls on_idle forever, while idle
end

function lsnes.on_new_ROM()
    print 'new_ROM'
    if not movie.rom_loaded() then return end

    lsnes.get_controller_info()
    smwdebug.register_debug_callback(false)

    -- Register special WRAM addresses for changes
    Registered_addresses.mario_position = ''
    Address_change_watcher[WRAM.x] = {
        watching_changes = false,
        register = function(_, value)
            local tabl = Address_change_watcher[WRAM.x]
            if tabl.watching_changes then
                local new = luap.signed16(256 * u8(WRAM.x + 1) + value)
                local change = new - s16(WRAM.x)
                if OPTIONS.register_player_position_changes == 'complete' and change ~= 0 then
                    Registered_addresses.mario_position =
                    Registered_addresses.mario_position ..
                    (change > 0 and (change .. '→') or (-change .. '←')) .. ' '

                    -- Debug: display players' hitbox when position changes
                    Midframe_context:set()
                    player.player_hitbox(new, s16(WRAM.y), u8(WRAM.is_ducking),
                                         u8(WRAM.powerup), 1,
                                         DBITMAPS.interaction_points_palette_alt)
                end
            end

            tabl.watching_changes = true
        end
    }
    Address_change_watcher[WRAM.y] = {
        watching_changes = false,
        register = function(_, value)
            local tabl = Address_change_watcher[WRAM.y]
            if tabl.watching_changes then
                local new = luap.signed16(256 * u8(WRAM.y + 1) + value)
                local change = new - s16(WRAM.y)
                if OPTIONS.register_player_position_changes == 'complete' and change ~= 0 then
                    Registered_addresses.mario_position =
                    Registered_addresses.mario_position ..
                    (change > 0 and (change .. '↓') or (-change .. '↑')) .. ' '

                    -- Debug: display players' hitbox when position changes
                    if math.abs(new - state.previous.y) > 1 then -- ignores the natural -1 for y, while on top of a block
                        Midframe_context:set()
                        player.player_hitbox(s16(WRAM.x), new, u8(WRAM.is_ducking),
                                             u8(WRAM.powerup), 1,
                                             DBITMAPS.interaction_points_palette_alt)
                    end
                end
            end

            tabl.watching_changes = true
        end
    }
    for address, inner in pairs(Address_change_watcher) do
        memory.registerwrite('WRAM', address, inner.register)
    end

    collision:init()

    -- Lagmeter
    if OPTIONS.use_lagmeter_tool then
        memory.registerexec('BUS', 0x8075, Lagmeter.get_master_cycles) -- unlisted ROM
    end
end

-- #############################################################################
-- ON START --

lsnes.init()

-- Lateral gaps
OPTIONS.left_gap = floor(OPTIONS.left_gap)
OPTIONS.right_gap = floor(OPTIONS.right_gap)
OPTIONS.top_gap = floor(OPTIONS.top_gap)
OPTIONS.bottom_gap = floor(OPTIONS.bottom_gap)

-- Initilize comparison ghost
if OPTIONS.is_simple_comparison_ghost_loaded then
    Ghost_player = require('ghost')
    Ghost_player.init()
end

-- KEYHOOK callback
_G.on_keyhook = keyinput.altkeyhook

-- Key presses:
keyinput.register_key_press('mouse_inwindow', gui.repaint)
keyinput.register_key_press(OPTIONS.hotkey_increase_opacity, function()
    draw.increase_opacity()
    gui.repaint()
end)
keyinput.register_key_press(OPTIONS.hotkey_decrease_opacity, function()
    draw.decrease_opacity()
    gui.repaint()
end)
keyinput.register_key_press('mouse_right', onclick.right)
keyinput.register_key_press('mouse_left', onclick.left)

-- Key releases:
keyinput.register_key_release('mouse_inwindow', function()
    cheat.is_dragging_sprite = false
    widget.left_mouse_dragging = false
    gui.repaint()
end)
keyinput.register_key_release(OPTIONS.hotkey_increase_opacity, gui.repaint)
keyinput.register_key_release(OPTIONS.hotkey_decrease_opacity, gui.repaint)
keyinput.register_key_release('mouse_left', function()
    cheat.is_dragging_sprite = false
    widget.left_mouse_dragging = false
end)

-- Read raw input:
keyinput.get_all_keys()

-- Timeout settings
-- set_timer_timeout(OPTIONS.timer_period)
set_idle_timeout(OPTIONS.idle_period)

-- Finish
draw.palettes_to_adjust(PALETTES, Palettes_adjusted)
draw.adjust_palette_transparency()
COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality, OPTIONS.filter_opacity / 10)
gui.repaint()
print('Lua script loaded successfully.')
