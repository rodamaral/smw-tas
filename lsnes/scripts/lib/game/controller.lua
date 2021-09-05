local M = {}

local memory2 = _G.memory2

local config = require 'config'
local mem = require 'memory'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local WRAM = smw.WRAM

-- Shows the controller input as the RAM and SNES registers store it
function M.display()
    if not OPTIONS.display_debug_controller_data then
        return
    end

    -- Font
    draw.Font = 'snes9xluasmall'
    local x_pos, _, x, y, _ = 0, 0, 0, 0

    x = draw.over_text(
        x,
        y,
        memory2.BUS:word(0x4218),
        'BYsS^v<>AXLR0123',
        COLOUR.warning,
        false,
        true
    )
    x = draw.over_text(
        x,
        y,
        memory2.BUS:word(0x421a),
        'BYsS^v<>AXLR0123',
        COLOUR.warning2,
        false,
        true
    )
    x = draw.over_text(
        x,
        y,
        memory2.BUS:word(0x421c),
        'BYsS^v<>AXLR0123',
        COLOUR.warning,
        false,
        true
    )
    x = draw.over_text(
        x,
        y,
        memory2.BUS:word(0x421e),
        'BYsS^v<>AXLR0123',
        COLOUR.warning2,
        false,
        true
    )
    _, y = draw.text(x, y, ' (Registers)', COLOUR.warning, false, true)

    x = x_pos
    x = draw.over_text(
        x,
        y,
        memory2.BUS:word(0x4016),
        'BYsS^v<>AXLR0123',
        COLOUR.warning,
        false,
        true
    )
    _, y = draw.text(x, y, ' ($4016)', COLOUR.warning, false, true)

    x = x_pos
    x = draw.over_text(
        x,
        y,
        256 * u8(WRAM.ctrl_1_1) + u8(WRAM.ctrl_1_2),
        'BYsS^v<>AXLR0123',
        COLOUR.weak
    )
    _, y = draw.text(x, y, ' (RAM data)', COLOUR.weak, false, true)

    x = x_pos
    draw.over_text(
        x,
        y,
        256 * u8(WRAM.firstctrl_1_1) + u8(WRAM.firstctrl_1_2),
        'BYsS^v<>AXLR0123',
        -1,
        0xff,
        -1
    )
end

return M
