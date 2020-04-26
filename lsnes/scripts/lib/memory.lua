local mem = _G.memory
local readbyte = mem.readbyte
local readsbyte = mem.readsbyte
local writebyte = mem.writebyte
local readword = mem.readword
local readsword = mem.readsword
local writeword = mem.writeword
local readhword = mem.readhword
local readhsword = mem.readhsword
local writehword = mem.writehword
local WRAM = 'WRAM'

local M = {}

function M.u8(address)
    return readbyte(WRAM, address)
end

function M.s8(address)
    return readsbyte(WRAM, address)
end

function M.w8(address, value)
    return writebyte(WRAM, address, value)
end

function M.u16(address)
    return readword(WRAM, address)
end

function M.s16(address)
    return readsword(WRAM, address)
end

function M.w16(address, value)
    return writeword(WRAM, address, value)
end

function M.u24(address)
    return readhword(WRAM, address)
end

function M.s24(address)
    return readhsword(WRAM, address)
end

function M.w24(address, value)
    return writehword(WRAM, address, value)
end

return M
