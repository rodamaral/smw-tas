local M = {}

local memory = _G.memory

local luap = require 'luap'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = memory.readbyte
local s8 = memory.readsbyte
local s16 = memory.readsword
local OPTIONS = config.OPTIONS
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant

-- sprite_table environment
do
    local xText, yText, height, xCam, yCam, xPos, yPos, number
    local color = 0xff4410

    local function draw_near_sprite(slot)
        local x, y = screen_coordinates(xPos, yPos, xCam, yCam)

        draw.Font = 'Uzebox6x8'
        draw.text(draw.AR_x * x, draw.AR_y * y, '#' .. slot, color, 0x000060)
    end

    local function sprite_info(slot)
        local xLow = u8('WRAM', WRAM.coinspr_x_low + slot)
        local xHigh = u8('WRAM', WRAM.coinspr_x_high + slot)
        local yLow = u8('WRAM', WRAM.coinspr_y_low + slot)
        local yHigh = u8('WRAM', WRAM.coinspr_y_high + slot)
        local ySub = u8('WRAM', WRAM.coinspr_y_sub + slot)
        local ySpeed = s8('WRAM', WRAM.coinspr_y_speed + slot)

        xPos = luap.signed16(0x100 * xHigh + xLow)
        yPos = luap.signed16(0x100 * yHigh + yLow)
        local text = string.format('#%x: %.2x (%x, %x.%.2x %+d)', slot, number, xPos, yPos, ySub,
                                   ySpeed)

        draw.Font = 'Uzebox8x12'
        draw.text(xText, yText, text, color, 0x000030)
        draw_near_sprite(slot)
    end

    function M.sprite_table()
        if not OPTIONS.display_coin_sprite_info then return end

        draw.Font = 'Uzebox8x12'
        height = draw.font_height()
        xText = draw.AR_x * (-100)
        yText = draw.AR_y * 248
        xCam = s16('WRAM', WRAM.camera_x)
        yCam = s16('WRAM', WRAM.camera_y)

        draw.text(xText, yText, 'Coin sprites:', color, 0x000030)
        yText = yText + height

        for slot = 0, SMW.coin_sprite_max - 1 do
            number = u8('WRAM', WRAM.coinspr_number + slot)

            if number ~= 0 then
                sprite_info(slot)
                yText = yText + height
            end
        end
    end
end

return M
