-- Ghost definitions: put the filenames here (absolute or relative to the emulator)
-- example: { "SMW-any%.smwg", "C:/Folder/simpleghost837244.smwg"}
local ghost_dumps  = { }

local MAX_ROOMS_IN_RAM = 5  -- the maximum ammount of rooms stored in the RAM memory

-- ***********************************
-- ***********************************

local draw = require "draw"
local smw = require "smw"
local WRAM = smw.WRAM
local SMW = smw.constant

-- Compability
local unpack = unpack or table.unpack

local function table_size(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local Player_frame, Camera_x, Camera_y

-- ***********************************
-- ***********************************
-- Utility functions

local function get_last_frame(advance)
    local cf = movie.currentframe() - (advance and 0 or 1)
    if cf == -1 then cf = 0 end
    
    return cf
end

local function screen_coordinates2(x, y, camera_x, camera_y)
    x_screen = (x - camera_x) + 8
    y_screen = (y - camera_y) + 15
    
    return x_screen, y_screen
end

local function get_game_mode()
    return memory.readbyte("WRAM", WRAM.game_mode)
end

local function ghost_vs_player(index, x_mario, x_sub_mario, x_speed_mario, direction_mario, x_ghost, x_sub_ghost, direction_ghost)
    local subpixels_mario = 16*x_mario + math.floor(x_sub_mario/16)
    local subpixels_ghost = 16*x_ghost + x_sub_ghost
    local x_difference
    local frame_difference
    
    --if direction_mario == 1 then
        x_difference = (subpixels_mario - subpixels_ghost)
    --else
    --  x_difference = (subpixels_ghost - subpixels_mario)
    --end
    
    if x_speed_mario ~= 0 then
        frame_difference = x_difference/x_speed_mario
    else
        frame_difference = subpixels_mario == subpixels_ghost and 0 or math.huge
    end
    
    local color = gui.rainbow(index, 6, "cyan")
    draw.font["snes9xtext"]((index-1)*48, 0, string.format("%.1f", frame_difference), color, 0)
end

-- Gets the current room and level of the player
local function get_room()
    local room_index = 256*256*memory.readbyte("WRAM", WRAM.room_index) + 256*memory.readbyte("WRAM", WRAM.room_index + 1) + memory.readbyte("WRAM", WRAM.room_index + 2)
    room_index = string.format("%x", room_index)  -- converts room_index to hexadecimal and then to string
    return room_index
end

-- Plots ghost
local function plot_ghost(ghost, ghost_frame, camera_x, camera_y, index)
    local ghost_x = ghost[ghost_frame]["x"]
    local ghost_sub_x = ghost[ghost_frame]["sub_x"]
    local ghost_y = ghost[ghost_frame]["y"]
    local ghost_direction = ghost[ghost_frame]["direction"]
    local ghost_is_lagged = ghost[ghost_frame]["is_lagged"]
    local ghost_hitbox_size = ghost[ghost_frame]["hitbox_size"]
    
    local mario_width = 5
    local mario_up, mario_down
    if ghost_hitbox_size == 0 then
        mario_up, mario_down = 0, 16
    elseif ghost_hitbox_size == 1 then
        mario_up, mario_down = -8, 16
    elseif ghost_hitbox_size == 2 then
        mario_up, mario_down = 3, 32
    else
        mario_up, mario_down = 0, 32
    end
    
    local x_screen, y_screen = screen_coordinates2(ghost_x, ghost_y, Camera_x, Camera_y)
    draw.box(x_screen - mario_width - 1, y_screen + mario_up - 1, x_screen + mario_width + 1, y_screen + mario_down + 1, 1, gui.rainbow(index, 6, 0x8000ffff), 0xf0ff0000)
    
    local x_mario = memory.readsword("WRAM", WRAM.x)
    local x_sub_mario = memory.readbyte("WRAM", WRAM.x_sub)
    local x_speed_mario = memory.readsbyte("WRAM", WRAM.x_speed)
    local direction_mario
    if x_speed_mario >= 0 then
        direction_mario = 1
    else
        direction_mario = 0
    end
    
    ghost_vs_player(index, x_mario, x_sub_mario, x_speed_mario, direction_mario, ghost_x, ghost_sub_x, ghost_direction)
    
    return ghost_x, ghost_sub_x, ghost_y, ghost_direction, ghost_is_lagged, ghost_hitbox_size
end


-- ***********************************
-- ***********************************
-- Ghost functions

local function decode_line(line)
    local pattern = "%s*%d+%s+(%x+)%s+(%x+)%s+(%d+)%s+(%d+)%s+(%x+)%s+(%-*%d+)%s+(%d+)%s+(%d+)%s*"
    local mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size = string.match(line, pattern)
    
    -- In case anything goes wrong
    if not mode or not room_index or not is_lagged or not x or not sub_x or not y or not direction or not hitbox_size then
        print("Error:", mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size)
    end
    
    mode, is_lagged, x, sub_x, y, direction, hitbox_size = tonumber(mode, 16), tonumber(is_lagged), tonumber(x),
                                    tonumber(sub_x, 16), tonumber(y), tonumber(direction), tonumber(hitbox_size)
    ;
    
    return mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size
end

-- GITHUB
local starting_frames = {}

-- Looks for the starting line(s) of each room in a given ghost
local function scan_ghost(filename)
    local starting_line_table = {}
    local previous_mode = -1
    local line_num = 1
    
    for line in io.lines(filename) do
        local mode, room_index = decode_line(line)
        
        if (mode ~= previous_mode) and (mode == SMW.game_mode_level) then  -- entering a level
            starting_line_table[room_index] = starting_line_table[room_index] or {}
            table.insert(starting_line_table[room_index], line_num)
        end
        
        previous_mode = mode
        line_num= line_num + 1
    end
    
    return starting_line_table
end

-- Reads filename and gets the table of room, entrance and exit frames for the ghost
local function read_room_from_dump(filename, ghost_room_table, current_room_id, starting_line_table)  -- GITHUB
    ghost_room_table = ghost_room_table or {}
    
    local room_starting = starting_line_table[current_room_id]
    local entry = 1
    local good_line = room_starting[entry]
    local previous_mode = -1
    local currentframe_since_room_started
    
    ghost_room_table[current_room_id] = nil -- GITHUB TEST
    
    local line_num = 1
    for line in io.lines(filename) do
        if not good_line then break end
        if line_num >= good_line then
            local mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size = decode_line(line)
            
            if (mode ~= previous_mode) and (mode == SMW.game_mode_level) then  -- entering a level
                if ghost_room_table[room_index] == nil then
                    ghost_room_table[room_index] = {}
                end
                local size = #ghost_room_table[room_index]
                currentframe_since_room_started = 1  -- resets it, since we wanna know the n-th frame of this room
                
                ghost_room_table[room_index][size + 1] = {}
            end
            
            if (mode == SMW.game_mode_level) then
                ghost_room_table[room_index][#ghost_room_table[room_index]][currentframe_since_room_started] = {
                    ["is_lagged"] = is_lagged == 1,
                    ["x"] = x, ["sub_x"] = sub_x,
                    ["y"] = y, ["sub_y"] = sub_y,
                    ["direction"] = direction, ["hitbox_size"] = hitbox_size
                }
                
                currentframe_since_room_started = currentframe_since_room_started + 1
            end
            
            if (mode ~= previous_mode) and (previous_mode == SMW.game_mode_level) then
                entry = entry + 1
                good_line = room_starting[entry]
            end
            
            previous_mode = mode
        end
        line_num= line_num + 1
    end
    
    return ghost_room_table
end

-- GITHUB
local GGT = {}
local Room_beginning_offset = {}
local Rooms_stored_in_RAM = {}

local function initialize_starting_lines()
    for entry, filename in ipairs(ghost_dumps) do
        Room_beginning_offset[entry] = scan_ghost(filename)
    end
end
initialize_starting_lines()  -- execute!


local function read_all_ghosts_from_room(room_id)
    -- Verifies if the number of rooms stored in the RAM is big
    local size = table_size(Rooms_stored_in_RAM)
    if size > MAX_ROOMS_IN_RAM then
        for entry, filename in ipairs(ghost_dumps) do
            GGT[entry][Rooms_stored_in_RAM[1]] = nil  -- delete the 1st room recorded
            table.remove(Rooms_stored_in_RAM, 1)
            size = size - 1
        end
        
    end
    
    for entry, filename in ipairs(ghost_dumps) do
        if Room_beginning_offset[entry][room_id] then
            GGT[entry] = read_room_from_dump(filename, GGT[entry], room_id, Room_beginning_offset[entry])
        end
    end
    
    table.insert(Rooms_stored_in_RAM, room_id)
    size = size + 1
    -- print("> > > > > Existem", size, "room-ids guardados na RAM:") -- GITHUB
end

-- Display the info and hitbox of all ghosts, if possible
local function display_all_ghosts(general_ghost_table, room_index, currentframe_since_room_started)
    local ghost_num = 1
    for entry, ghost_table in ipairs(general_ghost_table) do
    
        if ghost_table[room_index] then
        
            for entrance_number, data in ipairs(ghost_table[room_index]) do
            
                if currentframe_since_room_started <= #data then
                    plot_ghost(data, currentframe_since_room_started, Camera_x, Camera_y, ghost_num)
                    
                end
                ghost_num = ghost_num + 1
                
            end
            
        end
        
    end
    
end

--------------------------
----- Main function ------

local Displaying = {}
local previous_room = nil
local From_frame_advance = false

--read_all_ghosts()

function comparison(not_synth)
    if get_game_mode() == SMW.game_mode_level then
        -- read player info
        Player_frame = Player_frame or get_last_frame(false)
        Camera_x = memory.readsword("WRAM", WRAM.camera_x)
        Camera_y = memory.readsword("WRAM", WRAM.camera_y)
        local room_index = get_room()
        
        if From_frame_advance then
            if not previous_room then  -- entering a level
                Displaying[room_index] = {}
                Displaying[room_index].offset_frame = Player_frame
                Displaying[room_index].relative_frame = 1
                
                local read_from_file = true
                for entry, value in ipairs(Rooms_stored_in_RAM) do
                    if value == room_index then read_from_file = false ; break end
                end
                if read_from_file then
                    read_all_ghosts_from_room(room_index)
                end
                --print(read_from_file)
                
                display_all_ghosts(GGT, room_index, Displaying[room_index].relative_frame)
                
            elseif Displaying[room_index] and Player_frame >= Displaying[room_index].offset_frame then
                Displaying[room_index].relative_frame = Displaying[room_index].relative_frame + 1
                
                display_all_ghosts(GGT, room_index, Displaying[room_index].relative_frame)
                
            else
                -- do nothing
            end
            
        else  -- from loadstate
            if Displaying[room_index] then
                if (not previous_room or previous_room == room_index) and Player_frame >= Displaying[room_index].offset_frame then
                    -- loaded back in the same room
                    Displaying[room_index].relative_frame = Player_frame - Displaying[room_index].offset_frame + 1
                    display_all_ghosts(GGT, room_index, Displaying[room_index].relative_frame)
                    
                elseif Player_frame < Displaying[room_index].offset_frame then
                    Displaying[room_index] = nil
                    
                end
                
            end
            
        end
        
        previous_room = room_index
        
    else  -- outside level
        
        previous_room = nil
        
    end
    
    From_frame_advance = false  -- repaints without frame advance can't advance the ghosts
end

callback.frame_emulated:register(function()
    From_frame_advance = true
    Player_frame = get_last_frame(true)
end)

callback.frame:register(function() From_frame_advance = false end)

callback.pre_load:register(function() From_frame_advance = false ; Player_frame = nil end)

print("Comparison script loaded")
