local M = {}

local memory, bit = _G.memory, _G.bit

local draw = require 'draw'
local config = require 'config'
local widget = require 'widget'
local smw = require 'game.smw'

local OPTIONS = config.OPTIONS
local WRAM = smw.WRAM
local u32 = memory.readdword
local fmt = string.format

-- complete list of all possible RNG states
M.possible_values = {} -- FIXME: stateful
M.reverse_possible_values = {}

-- predict the next RNG values
function M.predict(seed1, seed2, rng1, rng2)
    local Y = 1
    local A, carry_flag

    local function tick_RNG()
        A = (4 * seed1) % 0x100

        carry_flag = true
        A = (A + seed1 + 1)
        if A < 0x100 then
            carry_flag = false
        else
            A = A % 0x100
            carry_flag = true
        end

        seed1 = A

        seed2 = 2 * seed2
        if seed2 < 0x100 then
            carry_flag = false
        else
            seed2 = seed2 % 0x100
            carry_flag = true
        end

        A = 0x20
        local tmp = bit.band(A, seed2)

        -- simplified branches
        if (carry_flag and tmp ~= 0) or (not carry_flag and tmp == 0) then
            seed2 = (seed2 + 1) % 0x100
        end
        A = seed2
        A = bit.bxor(A, seed1)

        -- set RNG byte
        if Y == 0 then
            rng1 = A
        else
            rng2 = A
        end
    end

    tick_RNG()
    Y = Y - 1
    tick_RNG()

    return seed1, seed2, rng1, rng2
end

-- generate a list of all RNG states from the initial state until it loops
function M.create_lists()
    local seed1, seed2, rng1, rng2 = 0, 0, 0, 0
    local counter = 1
    while true do
        local RNG_index = seed1 + 0x100 * seed2 + 0x10000 * rng1 + 0x1000000 * rng2
        if M.possible_values[RNG_index] then
            break
        end
        M.possible_values[RNG_index] = counter
        M.reverse_possible_values[counter] = RNG_index

        counter = counter + 1
        seed1, seed2, rng1, rng2 = M.predict(seed1, seed2, rng1, rng2)
    end
end

-- diplay nearby RNG states: past, present a future values
function M.display_RNG()
    if not bit.bfields then
        return
    end -- FIXME: define procedure when new API doesn't exist

    if not OPTIONS.display_RNG_info then
        if next(M.possible_values) ~= nil then
            M.possible_values = {}
            M.reverse_possible_values = {}
            collectgarbage()
        end

        return
    end

    -- create RNG lists if they are empty
    if next(M.possible_values) == nil then
        M.create_lists()
    end

    widget:set_property('RNG.predict', 'display_flag', true)
    local x = draw.AR_x * widget:get_property('RNG.predict', 'x')
    local y = draw.AR_y * widget:get_property('RNG.predict', 'y')
    draw.Font = false
    local height = draw.font_height()
    local upper_rows = 10

    local index = u32('WRAM', WRAM.RNG_input)
    local RNG_counter = M.possible_values[index]

    if RNG_counter then
        local min = math.max(RNG_counter - upper_rows, 1)
        local max = math.min(min + 2 * upper_rows, 27777) -- todo: hardcoded constants are never a good idea

        for i = min, max do
            local seed1, seed2, rng1, rng2 = bit.bfields(M.reverse_possible_values[i], 8, 8, 8, 8)
            local info = fmt('%d: %.2x, %.2x, %.2x, %.2x\n', i, seed1, seed2, rng1, rng2)
            draw.text(x, y, info, i ~= RNG_counter and 'white' or 'red')
            y = y + height
        end
    else
        draw.text(x, y, 'Glitched RNG! Report state/movie', 'red')
    end
end

return M
