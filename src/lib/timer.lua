-- This makes <fn> be called for <timeout> microseconds
-- Timer.functions is a table of tables. Each inner table contains the function, the period of its call, the start(right now) and whether it's already registered
local Timer = {}
Timer.functions = {}

-- Returns the current microsecond since UNIX epoch
local function microseconds()
  local epoch, usecs = utime()
  return epoch*1000000 + usecs
end

Timer.registerfunction = function(timeout, fn, name)
  local name = name or tostring(fn)
  if Timer.functions[name] then Timer.functions[name].start = microseconds() ; return end  -- restarts the active function, instead of calling it again

  Timer.functions[name] = {fn = fn, timeout = timeout, start = microseconds(), registered = false}
end

Timer.unregisterfunction = function(name)
  Timer.functions[name] = nil
end

function Timer.on_paint()
  for name in pairs(Timer.functions) do
    --print(Timer.functions[name])  -- debug
    Timer.functions[name].fn()
  end
end

function Timer.on_timer()
  local usecs = microseconds()
  for name in pairs(Timer.functions) do

    if Timer.functions[name].start + Timer.functions[name].timeout >= usecs then
      if not Timer.functions[name].registered then
        Timer.functions[name].registered = true
        gui.repaint()
      end
    else
      Timer.functions[name] = nil
      gui.repaint()
    end

  end
end

callback.register("timer", Timer.on_timer)  -- state!

return Timer
