-- Ghost definitions: put the filenames here (absolute or relative to the emulator)
-- example: { "SMW-any%.smwg", "C:/Folder/simpleghost837244.smwg"}
local ghost_dumps  = { "SDW-any%-bruno%amarat.smwg", "SDW-120-WIP-Dawn.smwg"--[[, "SDW-120exit-Panga.smwg"]]}

-- ***********************************
-- ***********************************
-- Compability
local unpack = unpack or table.unpack

local SMW = {
    -- Game Modes
    game_mode_overworld = 0x0e,
    game_mode_level = 0x14,
    
    sprite_max = 12, -- maximum number of sprites
}
local Camera_x, Camera_y

-- ***********************************
-- ***********************************
-- Utility functions

local function screen_coordinates2(x, y, camera_x, camera_y)
    x_screen = (x - camera_x) + 8
    y_screen = (y - camera_y) + 15
    
    return x_screen, y_screen
end

-- Works like Bizhawk's function: draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function draw_box(x1, y1, x2, y2, ...)
    x = 2*x1
    y = 2*y1
    w = 2 * (x2 - x1) + 2  -- adds thickness
    h = 2 * (y2 - y1) + 2  -- adds thickness
    gui.rectangle(x, y, w, h, ...)
end

function get_game_mode()
    return memory.readbyte("WRAM", WRAM.game_mode)
end

function ghost_vs_player(index, x_mario, x_sub_mario, x_speed_mario, direction_mario, x_ghost, x_sub_ghost, direction_ghost)
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
        frame_difference = math.huge
    end
    
    local color = gui.rainbow(index, 6, "cyan")
    draw_font["snes9xtext"]((index-1)*48, 0, string.format("%.1f", frame_difference), color, 0)
end

-- Gets the current room and level of the player
function get_room()
    local room_index = 256*256*memory.readbyte("WRAM", WRAM.room_index) + 256*memory.readbyte("WRAM", WRAM.room_index + 1) + memory.readbyte("WRAM", WRAM.room_index + 2)
    room_index = string.format("%x", room_index)  -- converts room_index to hexadecimal and then to string
    return room_index
end

-- Plots ghost
function plot_ghost(ghost, ghost_frame, camera_x, camera_y, index)
    local ghost_x = ghost[ghost_frame]["x"]
    local ghost_sub_x = ghost[ghost_frame]["sub_x"]
    local ghost_y = ghost[ghost_frame]["y"]
    local ghost_direction = ghost[ghost_frame]["direction"]
    local ghost_is_lagged = ghost[ghost_frame]["is_lagged"]
    local ghost_hitbox_size = ghost[ghost_frame]["hitbox_size"]
    
    local mario_width = 5
    local mario_up, mario_down
    if ghost_hitbox_size == 0 then
        mario_up = 0
        mario_down = 16
    elseif ghost_hitbox_size == 1 then
        mario_up = -8
        mario_down = 16
    elseif ghost_hitbox_size == 2 then
        mario_up = 3
        mario_down = 32
    else
        mario_up = 0
        mario_down = 32
    end
    
    local x_screen, y_screen = screen_coordinates2(ghost_x, ghost_y, Camera_x, Camera_y)
    draw_box(x_screen - mario_width - 1, y_screen + mario_up - 1, x_screen + mario_width + 1, y_screen + mario_down + 1, 1, gui.rainbow(index, 6, 0x8000ffff), 0xf0ff0000)
    
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

-- Reads filename and gets the table of room, entrance and exit frames for the ghost
function read_ghost_from_dump(filename)
    local ghost_room_table = {}
    
    local pattern = "%s*%d+%s+(%x+)%s+(%x+)%s+(%d+)%s+(%d+)%s+(%x+)%s+(%-*%d+)%s+(%d+)%s+(%d+)%s*"
    --                1486 11 f71fc1 1    0 0    0 0 0
    
    local previous_mode = -1
    local currentframe_since_room_started
    
    local count = 0  -- Amarat
    for line in io.lines(filename) do
        --local frame = tonumber(string.match(line, "%s*(%d+)"))  -- unused
        local mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size = string.match(line, pattern)
        
        -- In case anything goes wrong
        if not mode or not room_index or not is_lagged or not x or not sub_x or not y or not direction or not hitbox_size then
            print(mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size)
        end
        
        mode, is_lagged, x, sub_x, y, direction, hitbox_size = tonumber(mode, 16), tonumber(is_lagged), tonumber(x),
                                        tonumber(sub_x, 16), tonumber(y), tonumber(direction), tonumber(hitbox_size)
        ;
        
        if (mode ~= previous_mode) and (mode == SMW.game_mode_level) then  -- entering a level
            if ghost_room_table[room_index] == nil then
                ghost_room_table[room_index] = {}
            end
            local size = #ghost_room_table[room_index]
            currentframe_since_room_started = 1  -- resets it, since we wanna know the n-th frame of this room
            
            ghost_room_table[room_index][size + 1] = {}
        end
        
        if (mode == SMW.game_mode_level) then
            if not ghost_room_table[room_index] then print( count) end
            ghost_room_table[room_index][#ghost_room_table[room_index]][currentframe_since_room_started] = {
                ["is_lagged"] = is_lagged == 1,
                ["x"] = x, ["sub_x"] = sub_x,
                ["y"] = y, ["sub_y"] = sub_y,
                ["direction"] = direction, ["hitbox_size"] = hitbox_size
            }
            
            currentframe_since_room_started = currentframe_since_room_started + 1
        end
        
        previous_mode = mode
        count = count + 1
    end
    
    --print(count.." linhas")  -- Amarat
    return ghost_room_table
end


-- Put all ghosts in a general table
local general_ghost_table = {}
local function read_all_ghosts()
    for entry, filename in ipairs(ghost_dumps) do
        --print(entry, filename)  -- Amarat
        general_ghost_table[entry] = read_ghost_from_dump(filename)
    end
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

read_all_ghosts()

function comparison(not_synth)
    gui.text(0, 432, tostringx(Displaying[get_room()]), "white", 0x20000000) -- Amarat
    if get_game_mode() == SMW.game_mode_level then
        -- read player info
        local player_frame = movie.currentframe() + 1
        if not not_synth then player_frame = player_frame - 1 end  -- if current frame is not the result of a frame advance
        
        local room_index = get_room()
        Camera_x = memory.readsword("WRAM", WRAM.camera_x)
        Camera_y = memory.readsword("WRAM", WRAM.camera_y)
        
        
        if From_frame_advance then
            if not previous_room then  -- entering a level
                Displaying[room_index] = {}
                Displaying[room_index].offset_frame = player_frame
                Displaying[room_index].relative_frame = 1
                
                display_all_ghosts(general_ghost_table, room_index, Displaying[room_index].relative_frame)
                
            elseif Displaying[room_index] and player_frame >= Displaying[room_index].offset_frame then
                Displaying[room_index].relative_frame = Displaying[room_index].relative_frame + 1
                
                display_all_ghosts(general_ghost_table, room_index, Displaying[room_index].relative_frame)
                
            else
                -- do nothing
            end
            
        else  -- from loadstate
            if Displaying[room_index] then
                if (not previous_room or previous_room == room_index) and player_frame >= Displaying[room_index].offset_frame then
                    -- loaded back in the same room
                    Displaying[room_index].relative_frame = player_frame - Displaying[room_index].offset_frame + 1
                    display_all_ghosts(general_ghost_table, room_index, Displaying[room_index].relative_frame)
                    
                else
                    Displaying[room_index] = nil
                    
                end
                
            end
            
        end
        
        previous_room = room_index
        
    else  -- outside level
        
        previous_room = nil
        
    end
end

callback.frame_emulated:register(function()
    From_frame_advance = true
end)

callback.frame:register(function() From_frame_advance = false end)

callback.pre_load:register(function() From_frame_advance = false end)

print("Comparison script loaded")
