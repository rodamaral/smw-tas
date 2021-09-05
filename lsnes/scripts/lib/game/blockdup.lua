local M = {}

local memory, bit = _G.memory, _G.bit

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'
local tile = require 'game.tile'
local mem = require 'memory'
_G.commands = require 'commands'

local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local SMW = smw.constant
local WRAM = smw.WRAM
local screen_coordinates = smw.screen_coordinates
local OBJ_CLIPPING_SPRITE = smw.OBJ_CLIPPING_SPRITE
local fmt = string.format
local u8 = mem.u8
local s16 = mem.s16

-- arguments: left and bottom pixels of a given block tile
-- return: string type of duplication that will happen
--         false otherwise
local function sprite_block_interaction_simulator(x_block_left, y_block_bottom)
    -- local GOOD_SPEEDS = luap.make_set{-2.5, -2, -1.5, -1, 0, 0.5, 1.0, 1.5, 2.5, 3.0, 3.5, 4.0}

    -- get 1st carried sprite slot
    local slot
    for id = 0, SMW.sprite_max - 1 do
        if u8(WRAM.sprite_status + id) == 0x0b then
            slot = id
            break
        end
    end
    if not slot then
        return false
    end

    -- sprite properties
    local ini_x = luap.signed16(256 * u8(WRAM.sprite_x_high + slot) + u8(WRAM.sprite_x_low + slot))
    local ini_y = luap.signed16(256 * u8(WRAM.sprite_y_high + slot) + u8(WRAM.sprite_y_low + slot))
    local ini_y_sub = u8(WRAM.sprite_y_sub + slot)

    -- Sprite clipping vs objects
    local clip_obj = bit.band(u8(WRAM.sprite_1_tweaker + slot), 0xf)
    local ypt_right = OBJ_CLIPPING_SPRITE[clip_obj].yright
    local ypt_left = OBJ_CLIPPING_SPRITE[clip_obj].yleft
    local xpt_up = OBJ_CLIPPING_SPRITE[clip_obj].xup
    local ypt_up = OBJ_CLIPPING_SPRITE[clip_obj].yup

    -- Parameters that will vary each frame
    local left_direction = u8(WRAM.real_frame) % 2 == 0
    local y_speed = -112
    local y = ini_y
    local x_head = ini_x + xpt_up
    local y_sub = ini_y_sub

    -- print(fmt("Block: %d %d - Spr. ^%d <%d >%d", x_block_left, y_block_bottom, ypt_up, ypt_left, ypt_right))
    -- Predict each frame:
    while y_speed < 0 do
        -- Calculate next position.subpixel
        --[[ print(fmt("prediction: (%d, %d.%.2x) %+d %s", x_head, y + ypt_up, y_sub, y_speed,
      left_direction and "left" or "right")) ]]
        local next_total_subpixels = 256 * y + y_sub + 16 * y_speed
        y, y_sub = math.floor(next_total_subpixels / 256), next_total_subpixels % 256

        -- verify whether the block will be duplicated:
        -- if head is on block
        if y + ypt_up <= y_block_bottom and y + ypt_up >= y_block_bottom - 15 then
            -- lateral duplication
            -- if head is in the left-most 4 pixels
            if left_direction and x_block_left <= x_head and x_head - 4 < x_block_left then
                -- if head is in the right-most 4 pixels
                if y + ypt_left <= y_block_bottom then
                    return 'Left'
                end
            elseif
                not left_direction
                and x_head <= x_block_left + 15
                and x_head + 4 > x_block_left + 15
            then
                if y + ypt_right <= y_block_bottom then
                    return 'Right'
                end
            end

            -- Upward duplication
            if y + ypt_up <= y_block_bottom - 14 then -- 2 pixels height
                return 'Upward'
            end

            return false
        end

        -- Set next step
        y_speed = y_speed + 3
        left_direction = not left_direction
    end

    return false
end

-- verify nearby layer 1 tiles that are drawn
-- check whether they would allow a block duplication under ideal conditions
function M.predict_block_duplications()
    if not OPTIONS.use_block_duplication_predictor then
        return
    end

    local Camera_x = s16(WRAM.camera_x)
    local Camera_y = s16(WRAM.camera_y)
    local Player_x = s16(WRAM.x)
    local Player_y = s16(WRAM.y)

    local delta_x, delta_y = 48, 128

    for _, positions in ipairs(tile.layer1) do
        if
            luap.inside_rectangle(
                positions[1],
                positions[2],
                Player_x - delta_x,
                Player_y - delta_y,
                Player_x + delta_x,
                Player_y + delta_y
            )
        then
            local dup_status = sprite_block_interaction_simulator(positions[1], positions[2] + 15)

            if dup_status then
                local x, y = math.floor(positions[1] / 16), math.floor(positions[2] / 16)
                draw.message(fmt('Duplication prediction: %d, %d', x, y), 1000)

                local xs, ys = screen_coordinates(
                    positions[1] + 7,
                    positions[2],
                    Camera_x,
                    Camera_y
                )
                draw.Font = false
                draw.text(
                    draw.AR_x * xs,
                    draw.AR_y * ys - 4,
                    fmt('%s duplication', dup_status),
                    COLOUR.warning,
                    COLOUR.warning_bg,
                    true,
                    false,
                    0.5,
                    1.0
                )
                break
            end
        end
    end
end

return M
