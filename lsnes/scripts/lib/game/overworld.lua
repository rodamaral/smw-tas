local M = {}

local config = require('config')
local mem = require('memory')
local draw = require('draw')
local smw = require('game.smw')
_G.commands = require('commands')

local COLOUR = config.COLOUR
local SMW = smw.constant
local WRAM = smw.WRAM
local fmt = string.format
local u8 = mem.u8
local u16 = mem.u16
local s8 = mem.s8
local s16 = mem.s16

local function display_OW_exits()
    draw.Font = false
    local x = draw.Buffer_width
    local y = draw.AR_y * 24
    local h = draw.font_height()

    draw.text(x, y, 'Beaten exits:' .. u8(0x1f2e))
    for i = 0, 15 - 1 do
        y = y + h
        local byte = u8(0x1f02 + i)
        draw.over_text(x, y, byte, '76543210', COLOUR.weak, 'red')
    end
end

local function getTileNumber(x, y)
    return bit.lrshift(x, 4), bit.lrshift(y, 4)
end

local function getIndex(x, y)
    local xtile, ytile = getTileNumber(x, y)
    local xhigh = bit.lrshift(xtile, 4)
    local yhigh = bit.lrshift(ytile, 4)
    local xlow = bit.band(xtile, 0x0f)
    local ylow = bit.band(ytile, 0x0f)

    return bit.lshift(yhigh, 9) + bit.lshift(xhigh, 8) + bit.lshift(ylow, 4) + xlow -- SYX yyyy xxxx
end

local function getPath(x, y)
    local index = getIndex(x, y)
    local A = u8(0xc800 + index)
    A = 2*(A - 1)
    local xoffset = memory.readsbyte('ROM', 0x21ea7 + A)
    local yoffset = memory.readsbyte('ROM', 0x21ea7 + A + 1)

    return xoffset, yoffset
end

local function drawTile(xpixel, ypixel, xcam, ycam, xplayer, yplayer)
    local bg = (xplayer >= xpixel and xplayer < xpixel + 0x10 and yplayer >= ypixel and yplayer < ypixel + 0x10) and 0xa0ffff00 or -1
    draw.rectangle(xpixel - xcam, ypixel - ycam, 16, 16, 0x60808080, bg)
    local xoffset, yoffset = getPath(xpixel, ypixel)

    if xoffset >= -0x10 and xoffset <= 0x10 and yoffset >= -0x10 and yoffset <= 0x10 then
        if yoffset == 0x10 then
            draw.line(xpixel - xcam + 8, ypixel - ycam, xpixel - xcam + xoffset + 8, ypixel - ycam + yoffset, 2, 'green')
        elseif xoffset == 0x10 then
            draw.line(xpixel - xcam, ypixel - ycam + 8, xpixel - xcam + xoffset, ypixel - ycam + yoffset + 8, 2, 'orange')
        else
            local xin = 0
            local yin = 0
            local xnext = (xin + xoffset)
            local ynext = (yin + yoffset)
            draw.line(xpixel + xin - xcam, ypixel + yin - ycam, xpixel + xnext - xcam, ypixel + ynext - ycam, 2, 'red')
        end
    end

    local index = getIndex(xpixel, ypixel)
    local tileValue = u8(0xc800 + index)
    if tileValue ~= 0 then
        draw.text(2 * (xpixel - xcam), 2 *  (ypixel - ycam), string.format('%x', xpixel//16), 0x80ffffff)
        draw.text(2 * (xpixel - xcam) + 12, 2 *  (ypixel - ycam), string.format('%+d', xoffset), 0x60f66f6f)
        draw.text(2 * (xpixel - xcam), 2 *  (ypixel - ycam) + 8, string.format('%x', ypixel//16), 0x80ffffff)
        draw.text(2 * (xpixel - xcam) + 12, 2 *  (ypixel - ycam) + 8, string.format('%+d', yoffset), 0x60f66f6f)
        draw.text(2 * (xpixel - xcam), 2 *  (ypixel - ycam) + 16, string.format('%x', index), 0x6000ff00)

        if tileValue >= 0x56 then
            local transLevel = u8(0xd000 + index)
            draw.text(2 * (xpixel - xcam), 2 *  (ypixel - ycam) + 24, string.format('%x %x', tileValue, transLevel),  0x30ff0000)
        else
            draw.text(2 * (xpixel - xcam), 2 *  (ypixel - ycam) + 24, string.format('%x', tileValue),  0x600080ff)
        end
    end
end

local function displayGrid()
    local xcam = s16(0x1a)
    local ycam = s16(0x1c)
    local x = s16(0x1f17)
    local y = s16(0x1f19)

    draw.rectangle(0, 0, 512, 448, -1, 0x60000000)
    draw.Font = 'Uzebox6x8'
    for xpixel = 0, 16 * 31, 16  do
        for ypixel = 0, 31 * 16, 16  do
            drawTile(xpixel, ypixel, xcam, ycam, x, y)
        end
    end
    draw.Font = false

    local xoffset, yoffset = getPath(x, y)
    draw.line(-16, -16, xoffset - 16, yoffset - 16, 2, "red")

    draw.rectangle(x - xcam - 2, y - ycam - 2, 4, 4, 0x400000ff, 0x400000ff)
    draw.pixel(x - xcam, y - ycam, 'red')
end

local function displayPlayer()
    local x = s16(0x1f17)
    local y = s16(0x1f19)

    local xspeed = s16(0xdcf)
    local yspeed = s16(0xdd1) + s16(0x1317) // 256

    local xoffset, yoffset = getPath(x, y)
    local xnext = (x + xoffset) & 0xfffc
    local ynext = (y + yoffset) & 0xfffc

    draw.text(0, 32, string.format('Pos %d(%+d %d) %d(%+d %d) : ', x, xoffset, xnext, y, yoffset, ynext))
    draw.text(0, 48, string.format('Speed %d, %d', xspeed, yspeed))

    for i, obj in ipairs{
        { address = 0x0DC7, word = true, description = 'X position where Mario should be going to'},
        { address = 0x0DC9, word = true, description = 'Y position where Mario should be going to'},
        { address = 0x0DCB, word = true, description = 'X position where Luigi should be going to'},
        { address = 0x0DCD, word = true, description = 'Y position where Luigi should be going to'},
        { address = 0x0DCF, word = true, description = 'Player X speed on the overworld. Added with $7E:13D5'},
        { address = 0x0DD1, word = true, description = 'Player Y speed on the overworld. Added with $7E:13D7'},
        { address = 0x0DD3, description = 'Player direction. #$00 = up; #$02 = down; #$04 = left; #$06 = right' },
        -- { address = 0x0DD4, description = '' },
        { address = 0x0DD5, description = 'Used to indicate how a level has been exited', important = true },
        { address = 0x0DD6, description = 'Which character is in play' },
        { address = 0x13C1, description = 'Current Layer 1 overworld tile the player is standing on.', important = true },
        { address = 0x13C3, description = 'Current player submap. #$00 = Main map; #$01 = YI; etc', important = true },
        { address = 0x13D9, description = 'A pointer to various processes running on the overworld', important = true },
        { address = 0x1444, description = 'Player is on a level tile', important = true },
        { address = 0x1B78, description = 'hard coded path should be processed', word = true, important = true },
        { address = 0x1B9C, description = 'entering a warp pipe/star' },
        { address = 0x1DEA, description = 'Overworld event to run at level end', important = true },
        { address = 0x1DEB, description = 'Event tile to load', word = true, important = true },
        { address = 0x1DED, description = 'Last event tile to load to the overworld during a given event', word = true },
        { address = 0x1DF6, description = 'Star and Warp pipe handler', important = true },
        { address = 0x1F11, description = 'Current submap for Mario', important = true },
        { address = 0x1F12, description = 'Current submap for Mario', important = true },
        { address = 0x1F17, word = true, description = 'Overworld X position of Mario.', },
        { address = 0x1F19, word = true, description = 'Overworld Y position of Mario.', },
        { address = 0x1F1B, word = true, description = 'Overworld X position of Luigi.', },
        { address = 0x1F1D, word = true, description = 'Overworld Y position of Luigi.', },
        { address = 0x1F1F, description = "Pointer to Mario's overworld X position. Value is Mario's regular overworld X position divided by #$10 (#16).", },
        { address = 0x1F21, description = "Pointer to Mario's overworld Y position. Value is Mario's regular overworld Y position divided by #$10 (#16).", },
        { address = 0x1F23, description = "Pointer to Luigi's overworld X position. Value is Luigi's regular overworld X position divided by #$10 (#16).", },
        { address = 0x1F25, description = "Pointer to Luigi's overworld Y position. Value is Luigi's regular overworld Y position divided by #$10 (#16).", },
    } do
        local fn = obj.word and u16 or u8
        local address = obj.address
        local value = fn(address)

        draw.text(600, 0 + 16 * i, string.format('$%.4x: %4x  %s', address, value, obj.description), obj.important and 'red' or 'white')
    end
end

function M.main()
    display_OW_exits()
    displayGrid()
    displayPlayer()
end

return M
