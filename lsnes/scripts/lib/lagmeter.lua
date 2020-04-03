local M = {} -- experimental: determine how laggy (0-100) the last frame was, after emulation

local memory = _G.memory

local draw = require('draw')
local config = require('config')

local OPTIONS = config.OPTIONS

function M.get_master_cycles()
    local v, h = memory.getregister('vcounter'), memory.getregister('hcounter')
    local mcycles = v + 262 - 225

    M.Mcycles = 1364 * mcycles + h
    if v >= 226 or (v == 225 and h >= 12) then
        M.Mcycles = M.Mcycles - 2620
        print('Lagmeter (V, H):', v, h)
    end
    if v >= 248 then M.Mcycles = M.Mcycles - 262 * 1364 end
end

function M.display()
    if OPTIONS.use_lagmeter_tool and M.Mcycles then
        local meter, color = M.Mcycles / 3573.68
        if meter < 70 then
            color = 0x00ff00
        elseif meter < 90 then
            color = 0xffff00
        elseif meter <= 100 then
            color = 0xff0000
        else
            color = 0xff00ff
        end

        draw.Font = 'Uzebox8x12'
        draw.text(364, 16, string.format('Lagmeter: %.3f', meter), color, false, false, 0.5)
    end
end

return M
