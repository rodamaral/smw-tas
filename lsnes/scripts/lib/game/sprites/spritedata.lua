local M = {}

local memory, bit = _G.memory, _G.bit

local luap = require('luap')
local mem = require('memory')
local config = require('config')
local draw = require('draw')
local widget = require('widget')
local keyinput = require 'keyinput'
local sprite_images = require 'game.sprites.spriteimages'

local u8 = mem.u8
local u16 = mem.u16
local u24 = mem.u24
local OPTIONS = config.OPTIONS
local input = keyinput.key_state

local MAX_SPRITE_DATA_SIZE = 0x80

local function get_alive()
    local alive = {}
    for slot = 0, 11 do
        if u8(0x14c8 + slot) ~= 0 then
            local index = u8(0x161a + slot)
            alive[index] = true
        end
    end
    return alive
end

-- draw sprite picture if mouse is over text
local function on_hover(xtext, ytext, dx, dy, number, xpos, ypos)
    local x = input.mouse_x - xtext
    local y = input.mouse_y - ytext
    if luap.inside_rectangle(x, y, 0, 0, dx - 1, dy - 1) then
        local x0 = draw.AR_x * widget:get_property('sprite_load_status', 'x')
        local y0 = draw.AR_y * widget:get_property('sprite_load_status', 'y')
        sprite_images:draw_sprite(x0 + 4, y0 - 4, number, false, true)
        draw.text(x0 + 32, y0 - 12, string.format('(%4d, %3d)', xpos, ypos))

        return true
    end

    return false
end

function M.display_room_data()
    widget:set_property('sprite_load_status', 'display_flag', OPTIONS.display_sprite_load_status)
    if not OPTIONS.display_sprite_load_status then return end

    draw.Font = 'Uzebox6x8'
    local height = draw.font_height()
    local width = draw.font_width()
    local x0 = draw.AR_x * widget:get_property('sprite_load_status', 'x')
    local y0 = draw.AR_y * widget:get_property('sprite_load_status', 'y')

    local header = u24(0xce)
    local screen_number = u8(0x5e) + 1
    local cameraX = u16(0x1462)
    local cameraY = u16(0x1464)
    local xt, yt = x0, y0
    local sprite = header + 1

    -- if inside ROM
    if sprite < 0x2000 then
    elseif (sprite % 0x10000) < 0x8000 and (sprite + 3 * 128 % 0x10000) < 0x8000 then return end

    local area = memory.readregion('BUS', sprite, 3 * MAX_SPRITE_DATA_SIZE)
    local alive = get_alive()

    local v0 = memory.readbyte('WRAM', 0x18)
    for id = 0, MAX_SPRITE_DATA_SIZE - 1 do
        local byte0 = area[3 * id]
        local byte1 = area[3 * id + 1]
        local byte2 = area[3 * id + 2]
        if byte0 == 0xFF then break end

        local yScreen = bit.band(byte0, 0x0d)
        local ylow = bit.band(byte0, 0xf0)
        local xScreen = (bit.test(byte0, 1) and 16 or 0) + (byte1 % 16)
        local xlow = math.floor(byte1 / 16)

        local xpos = 16 * (xScreen * 16 + xlow)
        local ypos = 256 * yScreen + ylow

        local number = byte2
        local color = xScreen <= v0 and 0xc0808080 or 0x808080
        local bgRectangle = xScreen <= v0 and -1 or 0xc0ffffff
        color = xScreen <= screen_number and color or 0xff00ff

        local is_on_sprite = on_hover(xt, yt, 6 * width, height, number, xpos, ypos)
        local bg= is_on_sprite and 0x1818a0 or 0

        -- sprite color according to status
        local onscreen = u8(0x1938 + id) ~= 0
        if onscreen then
            color = 0xffffff
            if not alive[id] then color = 0xff0000 end
        end
        draw.text(xt, yt, string.format('%.2d: %.2x', id, number), color, bg)
        yt = yt + height

        -- draw sprite data on position
        do
            local xdraw = 2 * (xpos - cameraX)
            local ydraw = 2 * (ypos - cameraY)
            on_hover(xdraw, ydraw, 2*16, 2*16, number, xpos, ypos)

            draw.Font = 'Uzebox8x12'
            draw.text(xdraw, ydraw, id, color, bg)
            draw.rectangle(xpos - cameraX, ypos - cameraY, 16, 16, 0xc0000000, bgRectangle)
            draw.pixel(xpos - cameraX, ypos - cameraY, 'red', 0x80ffffff)
            draw.Font = 'Uzebox6x8'
        end

        -- update text position
        if (id + 1) % 16 == 0 then
            yt = y0
            xt = xt + 7 * width + 2
        end
    end
end

return M
