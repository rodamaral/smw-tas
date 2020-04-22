local M = {}

local memory = _G.memory
local u8 = memory.readbyte

function M.bus(address)
    if address < 0 or address >= 0x1000000 then return false, 'address is out of bounds' end

    local bank = math.floor(address / 0x10000)
    local offset = address % 0x10000

    if bank >= 0x40 and bank < 0x70 then
        if offset >= 0x8000 then
            return u8('BUS', address)
        else
            return false, 'address is dangerous'
        end
    elseif (bank >= 0x70 and bank < 0x80) or (bank >= 0xE0) then
        return u8('BUS', address)
    else
        if offset < 0x2000 or offset >= 0x8000 then
            return u8('BUS', address)
        else
            return false, 'address is dangerous'
        end
    end
end

return M
