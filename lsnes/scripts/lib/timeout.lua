local lsnes_callback, utime, set_timer_timeout_micro = _G.callback, _G.utime, _G.set_timer_timeout

assert(_G.on_timer == nil, 'The global function "on_timer" should not exist when using this module')

-- Returns how many miliseconds have passed since UNIX epoch
local function get_miliseconds()
    local epoch, usecs = utime()
    return epoch * 1000 + math.floor(usecs / 1000)
end

-- Redefine set_timer_timeout to use miliseconds
local function set_timer_timeout_mili(time)
    set_timer_timeout_micro(1000 * time)
end

--------------------------------------------------------

local M = {}

local initial_miliseconds = get_miliseconds()
local scheduler = {}
local current_handle = 0

local function get_miliseconds_since_instanciation()
    return get_miliseconds() - initial_miliseconds
end

local function get_and_increment_handle()
    current_handle = current_handle + 1
    return current_handle
end

local function remove_id(handle_id)
    local pos
    for index, entry in ipairs(scheduler) do
        if entry.id == handle_id then
            pos = index
        end
    end

    if pos then
        table.remove(scheduler, pos)
    end
end

local function execute_next_if_exists()
    if #scheduler == 0 then
        error'Internal error: scheduler is empty'
    end

    table.remove(scheduler, 1).callback()
end

local function schedule_next_if_exists()
    local next = scheduler[1]
    if next ~= nil then
        set_timer_timeout_mili(next.time - get_miliseconds_since_instanciation())
    end
end

local function execute()
    execute_next_if_exists()
    schedule_next_if_exists()
end

local function get_position(finish)
    local position
    for index, task in ipairs(scheduler) do
        if finish < task.time then
            position = index
            break
        end
    end
    position = position or #scheduler + 1

    return position
end

function M.set_timeout(callback, time)
    local finish = time + get_miliseconds_since_instanciation()
    local entry = { callback = callback, time = finish }
    local position = get_position(finish)
    entry.id = get_and_increment_handle()
    table.insert(scheduler, position, entry)

    if position == 1 then
        set_timer_timeout_mili(scheduler[1].time)
    end

    return entry.id
end

function M.clear_timeout(id)
    print('canceling ' .. id, 'in', scheduler)
    local index
    for num, item in ipairs(scheduler) do
        if item.id == id then
            index = num
            break
        end
    end

    if index ~= nil then
        remove_id(scheduler[index].id)
        table.remove(scheduler, index)
    end
end

lsnes_callback.register('timer', function()
    execute()
    print('sizeof', #scheduler)
end)

return M
