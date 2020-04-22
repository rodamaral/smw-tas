local M = {}

local bit, memory = _G.bit, _G.memory

local luap = require('luap')
local config = require('config')
local keyinput = require('keyinput')
local draw = require('draw')
local lsnes = require('lsnes')
local cheat = require('cheat')
local Options_menu = require('menu')
local Display = require('display')
local smw = require('game.smw')
local tile = require('game.tile')
local state = require('game.state')
local Sprites_info = require('game.sprites.spriteinfo')

local fmt = string.format
local floor = math.floor
local u8 = memory.readbyte
local w8 = memory.writebyte
local s16 = memory.readsword
local OPTIONS = config.OPTIONS
local SMW = smw.constant
local WRAM = smw.WRAM
local game_coordinates = smw.game_coordinates
local User_input = keyinput.key_state
local store = state.store

-- private

-- uses the mouse to select an object
local function select_object(mouse_x, mouse_y, camera_x, camera_y)
    -- Font
    draw.Font = false
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 0.5

    local x_game, y_game = game_coordinates(mouse_x, mouse_y, camera_x, camera_y)
    local obj_id

    -- Checks if the mouse is over Mario
    local x_player = s16('WRAM', WRAM.x)
    local y_player = s16('WRAM', WRAM.y)
    if x_player + 0xe >= x_game and x_player + 0x2 <= x_game and y_player + 0x30 >= y_game and
    y_player + 0x8 <= y_game then obj_id = 'Mario' end

    if not obj_id and OPTIONS.display_sprite_info then
        for id = 0, SMW.sprite_max - 1 do
            local sprite_status = u8('WRAM', WRAM.sprite_status + id)
            -- TODO: see why the script gets here without exporting Sprites_info
            if sprite_status ~= 0 and Sprites_info[id].x then
                -- Import some values
                local x_sprite, y_sprite = Sprites_info[id].x, Sprites_info[id].y
                local xoff, yoff = Sprites_info[id].hitbox_xoff, Sprites_info[id].hitbox_yoff
                local width, height = Sprites_info[id].hitbox_width, Sprites_info[id].hitbox_height

                if x_sprite + xoff + width >= x_game and x_sprite + xoff <= x_game and y_sprite +
                yoff + height >= y_game and y_sprite + yoff <= y_game then
                    obj_id = id
                    break
                end
            end
        end
    end

    if not obj_id then return end

    draw.text(User_input.mouse_x, User_input.mouse_y - 8, obj_id, true, false, 0.5, 1.0)
    return obj_id, x_game, y_game
end

-- public

-- This function sees if the mouse if over some object, to change its hitbox mode
-- The order is: 1) player, 2) sprite.
function M.right()
    -- do nothing if over movie editor
    if OPTIONS.display_controller_input and
    luap.inside_rectangle(User_input.mouse_x, User_input.mouse_y, lsnes.movie_editor_left,
                          lsnes.movie_editor_top, lsnes.movie_editor_right,
                          lsnes.movie_editor_bottom) then return end

    local id = select_object(User_input.mouse_x, User_input.mouse_y, store.Camera_x, store.Camera_y)

    if tostring(id) == 'Mario' then
        if OPTIONS.display_player_hitbox and OPTIONS.display_interaction_points then
            OPTIONS.display_interaction_points = false
            OPTIONS.display_player_hitbox = false
        elseif OPTIONS.display_player_hitbox then
            OPTIONS.display_interaction_points = true
            OPTIONS.display_player_hitbox = false
        elseif OPTIONS.display_interaction_points then
            OPTIONS.display_player_hitbox = true
        else
            OPTIONS.display_player_hitbox = true
        end

        config.save_options()
        return
    end

    local spr_id = tonumber(id)
    if spr_id and spr_id >= 0 and spr_id <= SMW.sprite_max - 1 then
        local number = u8('WRAM', WRAM.sprite_number + spr_id)
        local t = Display.sprite_hitbox[spr_id][number]
        if t.sprite and t.block then
            t.sprite = false
            t.block = false
        elseif t.sprite then
            t.block = true
            t.sprite = false
        elseif t.block then
            t.sprite = true
        else
            t.sprite = true
        end

        config.save_options()
        return
    end

    -- Select layer 2 tiles
    local layer2x = s16('WRAM', WRAM.layer2_x_nextframe)
    local layer2y = s16('WRAM', WRAM.layer2_y_nextframe)
    local x_mouse, y_mouse = floor(User_input.mouse_x / draw.AR_x) + layer2x,
                             floor(User_input.mouse_y / draw.AR_y) + layer2y
    tile.select_tile(16 * floor(x_mouse / 16), 16 * floor(y_mouse / 16), tile.layer2)
end

function M.left()
    -- Buttons
    for _, field in ipairs(draw.button_list) do
        -- if mouse is over the button
        if keyinput:mouse_onregion(field.x, field.y, field.x + field.width, field.y + field.height) then
            field.action()
            config.save_options()
            return
        end
    end

    -- Movie Editor
    if lsnes.movie_editor() then return end

    -- Sprites' tweaker editor
    if cheat.allow_cheats and cheat.sprite_tweaker_selected_id then
        local id = cheat.sprite_tweaker_selected_id
        local tweaker_num = cheat.sprite_tweaker_selected_y + 1
        local tweaker_bit = 7 - cheat.sprite_tweaker_selected_x

        -- Sanity check
        if id < 0 or id >= SMW.sprite_max then return end
        if tweaker_num < 1 or tweaker_num > 6 or tweaker_bit < 0 or tweaker_bit > 7 then
            return
        end

        -- Get address and edit value
        local tweaker_table = {
            WRAM.sprite_1_tweaker, WRAM.sprite_2_tweaker, WRAM.sprite_3_tweaker,
            WRAM.sprite_4_tweaker, WRAM.sprite_5_tweaker, WRAM.sprite_6_tweaker
        }
        local address = tweaker_table[tweaker_num] + id
        local value = u8('WRAM', address)
        local status = bit.test(value, tweaker_bit)

        w8('WRAM', address, value + (status and -1 or 1) * bit.lshift(1, tweaker_bit)) -- edit only given bit
        print(fmt('Edited bit %d of sprite (#%d) tweaker %d (address WRAM+%x).', tweaker_bit, id,
                  tweaker_num, address))
        cheat.sprite_tweaker_selected_id = nil -- don't edit two addresses per click
        return
    end

    -- Drag and drop sprites
    if cheat.allow_cheats then
        local id = select_object(User_input.mouse_x, User_input.mouse_y, store.Camera_x,
                                 store.Camera_y)
        if type(id) == 'number' and id >= 0 and id < SMW.sprite_max then
            cheat.dragging_sprite_id = id
            cheat.is_dragging_sprite = true
            return
        end
    end

    -- Layer 1 tiles
    if not Options_menu.show_menu then
        if not (OPTIONS.display_controller_input and
        luap.inside_rectangle(User_input.mouse_x, User_input.mouse_y, lsnes.movie_editor_left,
                              lsnes.movie_editor_top, lsnes.movie_editor_right,
                              lsnes.movie_editor_bottom)) then
            -- don't select over movie editor
            local x_mouse, y_mouse = game_coordinates(User_input.mouse_x, User_input.mouse_y,
                                                      store.Camera_x, store.Camera_y)
            x_mouse = 16 * floor(x_mouse / 16)
            y_mouse = 16 * floor(y_mouse / 16)
            tile.select_tile(x_mouse, y_mouse, tile.layer1)
        end
    end
end

function M.toggle_sprite_hitbox()
    if User_input.mouse_inwindow == 1 then
        select_object(User_input.mouse_x, User_input.mouse_y, store.Camera_x, store.Camera_y)
    end
end

return M
