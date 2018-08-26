local M = {} -- experimental: determine how laggy (0-100) the last frame was, after emulation

local memory = _G.memory

function M.get_master_cycles()
  local v,
    h = memory.getregister('vcounter'), memory.getregister('hcounter')
  local mcycles = v + 262 - 225

  M.Mcycles = 1364 * mcycles + h
  if v >= 226 or (v == 225 and h >= 12) then
    M.Mcycles = M.Mcycles - 2620
    print('Lagmeter (V, H):', v, h)
  end
  if v >= 248 then
    M.Mcycles = M.Mcycles - 262 * 1364
  end
end

return M
