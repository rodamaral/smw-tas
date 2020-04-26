local M = {}

local memory = _G.memory

local mem = require('memory')
local smw = require('game.smw')

local bus8 = memory.readbyte
local u8 = mem.u8
local w8 = mem.w8
-- local w16 = mem.w16
-- local w24 = mem.w24
local WRAM = smw.WRAM

local tweakers = {
    WRAM.sprite_1_tweaker, WRAM.sprite_2_tweaker, WRAM.sprite_3_tweaker, WRAM.sprite_4_tweaker,
    WRAM.sprite_5_tweaker, WRAM.sprite_6_tweaker
}

local function zero_tables(slot, list)
    for _, address in ipairs(list) do w8(address + slot, 0) end
end

function M.clock(time, subsecond)
    assert(math.type(time) == 'integer', 'time should be integer')
    assert(subsecond == nil or math.type(subsecond) == 'integer', 'subsecond should be integer')

    local hundreds = math.floor(time / 100)
    local tens = math.floor(time / 10) % 10
    local ones = time % 10

    w8(WRAM.clock_hundreds, hundreds)
    w8(WRAM.clock_tens, tens)
    w8(WRAM.clock_ones, ones)

    if subsecond then
        w8(WRAM.timer_frame_counter, subsecond)
    end
end

function M.create_sprite(id, slot, x, y)
    -- misc tables
    zero_tables(slot, smw.zeroed_tables)
    w8(WRAM.sprite_x_offscreen + slot, 1)

    -- tweakers
    local YXPPCCCT = bus8('BUS', smw.tweaker_addresses[3] + id)
    w8(WRAM.sprite_YXPPCCCT + slot, YXPPCCCT)

    for i in ipairs(tweakers) do
        local value = bus8('BUS', smw.tweaker_addresses[i] + id)
        w8(tweakers[i] + slot, value)
    end

    -- position
    local xhigh = math.floor(x / 0x100) % 0x100
    local xlow = x % 0x100
    local yhigh = math.floor(y / 0x100) % 0x100
    local ylow = y % 0x100

    w8(WRAM.sprite_x_high + slot, xhigh)
    w8(WRAM.sprite_y_high + slot, yhigh)
    w8(WRAM.sprite_x_low + slot, xlow)
    w8(WRAM.sprite_y_low + slot, ylow)
    w8(WRAM.sprite_status + slot, 1)
    w8(WRAM.sprite_number + slot, id)
end

function M.delete_sprites(slots, types)
    for slot in pairs(slots) do
        w8(WRAM.sprite_status + slot, 0)
    end
    for slot = 0, 11 do
        local number = u8(WRAM.sprite_number + slot)
        if  types[number] then
            w8(WRAM.sprite_status + slot, 0)
        end
    end
end

return M
