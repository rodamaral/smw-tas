-- This makes <fn> be called for <timeout> microseconds
local M = {}

local gui, callback, utime = _G.gui, _G.callback, _G.utime

-- M.functions is a table of tables. Each inner table contains the function,
-- the period of its call, the start(right now) and whether it's already registered
M.functions = {}

-- Returns the current microsecond since UNIX epoch
local function microseconds()
    local epoch, usecs = utime()
    return epoch * 1000000 + usecs
end

M.registerfunction = function(timeout, fn, name_arg)
    local name = name_arg or tostring(fn)
    if M.functions[name] then
        M.functions[name].start = microseconds()
        return
    end -- restarts the active function, instead of calling it again

    M.functions[name] = {fn = fn, timeout = timeout, start = microseconds(), registered = false}
end

M.unregisterfunction = function(name) M.functions[name] = nil end

function M.on_paint()
    for name in pairs(M.functions) do
        M.functions[name].fn()
    end
end

function M.on_timer()
    local usecs = microseconds()
    for name in pairs(M.functions) do
        if M.functions[name].start + M.functions[name].timeout >= usecs then
            if not M.functions[name].registered then
                M.functions[name].registered = true
                gui.repaint()
            end
        else
            M.functions[name] = nil
            gui.repaint()
        end
    end
end

-- local queue = {}
-- local function set_timeout(callback, miliseconds)
--     queue[callback] = true
-- end

callback.register('timer', M.on_timer) -- state!

return M
