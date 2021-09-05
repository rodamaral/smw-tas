local M = {} -- Special generators class

local gui, bit = _G.gui, _G.bit

local luap = require 'luap'
local mem = require 'memory'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'
local RNG = require 'game.rng'
local sprite_images = require 'game.sprites.spriteimages'

local u8 = mem.u8
local s16 = mem.s16
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local fmt = string.format

function M:info()
    if not OPTIONS.display_generator_info then
        return
    end

    draw.Font = 'Uzebox6x8'
    local generator = u8(WRAM.generator_type)
    if generator == 0 then
        return
    end -- no active generator

    -- local generator_timer = u8(WRAM.generator_timer) -- TODO: use for some generators
    local text = fmt('Generator $%X: %s', generator, smw.GENERATOR_TYPES[generator])
    draw.text(0, draw.Buffer_height + 12, text, COLOUR.warning2)

    local f = self.sprite[generator]
    if f then
        f()
    end
end

M.sprite = {}

M.sprite[0x09] = function()
    -- Super Koopas
    -- load environment
    local Effective_frame = u8(WRAM.effective_frame)
    local Camera_x = s16(WRAM.camera_x)
    local Camera_y = s16(WRAM.camera_y)
    local _, _, next_rng1 = RNG.predict(
        u8(WRAM.RNG_input),
        u8(WRAM.RNG_input + 1),
        u8(WRAM.RNG),
        u8(WRAM.RNG + 1)
    )
    -- FIXME: actually, carry flag is not always the same

    local ypos = Camera_y + bit.band(next_rng1, 0x3F) + 0x20
    local xpos = Camera_x + (next_rng1 % 2 == 0 and -0x20 or 0x110)
    local timer = 0x40 - bit.band(Effective_frame, 0x3F)
    local xscreen, yscreen = screen_coordinates(xpos, ypos, Camera_x, Camera_y)
    xscreen, yscreen = draw.AR_x * xscreen, draw.AR_y * yscreen

    gui.crosshair(xscreen, yscreen)
    local bitmap = sprite_images[0x71]
    bitmap:draw(xscreen + 5, yscreen + 5)
    draw.text(xscreen + 40, yscreen + 5, timer, COLOUR.warning)
    draw.text(xscreen + 4, yscreen - 10, fmt('%d, %d', xpos, ypos))
end

M.sprite[0x0B] = function()
    -- Bullet Bills, sides
    local bill_x, bill_y

    -- load environment
    local Effective_frame = u8(WRAM.effective_frame)
    local Camera_x = s16(WRAM.camera_x)
    local Camera_y = s16(WRAM.camera_y)
    local _, _, next_rng1 = RNG.predict(
        u8(WRAM.RNG_input),
        u8(WRAM.RNG_input + 1),
        u8(WRAM.RNG),
        u8(WRAM.RNG + 1)
    )
    local C = 1
    -- FIXME: carry is always set after the RNG routine

    -- calculate the y pos
    local A = bit.band(next_rng1, 0x7F) + 0x20 + Camera_y % 0x100 + C
    C = 0
    if A >= 0x100 then
        A = A - 0x100
        C = 1
    end
    bill_y = bit.band(A, 0xF0) + 0x100 * (math.floor(Camera_y / 0x100) + C)

    -- calculate the x pos
    local Y = bit.band(next_rng1, 0x01)
    A = Camera_x % 0x100 + (Y == 0 and 0xE0 or 0x10)
    C = 0
    if A >= 0x100 then
        A = A - 0x100
        C = 1
    end

    bill_x = A
    A = math.floor(Camera_x / 0x100) + (Y == 0 and 0xFF or 0x01) + C
    A = A % 0x100
    bill_x = luap.signed16(bill_x + 0x100 * A)

    local xpos, ypos = screen_coordinates(bill_x, bill_y, Camera_x, Camera_y)
    draw.rectangle(xpos + 2, ypos + 3, 12, 10)
    draw.text(
        (xpos + 8) * draw.AR_x,
        ypos * draw.AR_y,
        fmt('%d', 0x80 - bit.band(Effective_frame, 0x7F)),
        COLOUR.warning,
        true,
        false,
        0.5,
        1.0
    )

    local bill_bitmap = sprite_images[0x1c]
    bill_bitmap:draw((xpos + 5) * draw.AR_x, (ypos + 5) * draw.AR_y)
end

M.sprite[0x0C] = function()
    local Real_frame = u8(WRAM.real_frame)

    -- Bullet Bills, surrounded
    local bullet_timer = u8(WRAM.bullet_bill_timer)
    bullet_timer = 2 * (0xa0 - bullet_timer) + (Real_frame % 2 == 0 and 1 or 2)

    draw.text(0, draw.Buffer_height + 12 + 12, 'Timer: ' .. bullet_timer, COLOUR.warning2)
end

M.sprite[0x0D] = M.sprite[0x0C] -- Bullet Bills, diagonal

return M
