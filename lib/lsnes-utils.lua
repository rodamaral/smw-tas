local lsnes_utils = {}

local config = require "config"
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH

lsnes_utils.LSNES, lsnes_utils.CONTROLLER, lsnes_utils.MOVIE = {}, {}, {}
local LSNES, CONTROLLER, MOVIE = lsnes_utils.LSNES, lsnes_utils.CONTROLLER, lsnes_utils.MOVIE

local draw = require "draw"

local raw_input = require "raw-input"
local User_input = raw_input.key_state

local floor = math.floor


-- Returns frames-time conversion
function LSNES.frame_time(frame)
    local total_seconds = frame / movie.get_game_info().fps  -- edit: don't read it every frame
    local hours, minutes, seconds = bit.multidiv(total_seconds, 3600, 60)
    seconds = floor(seconds)
    
    local miliseconds = 1000* (total_seconds%1)
    if hours == 0 then hours = "" else hours = string.format("%d:", hours) end
    local str = string.format("%s%.2d:%.2d.%03.0f", hours, minutes, seconds, miliseconds)
    return str
end


local function get_last_frame(advance)
    local cf = movie.currentframe() - (advance and 0 or 1)
    if cf == -1 then cf = 0 end
    
    return cf
end


function LSNES.lsnes_status()
    LSNES.Runmode = gui.get_runmode()
    LSNES.Lsnes_speed = settings.get_speed()
    
    LSNES.Readonly = movie.readonly()
    LSNES.Framecount = movie.framecount()
    LSNES.Subframecount = movie.get_size()
    LSNES.Lagcount = movie.lagcount()
    LSNES.Rerecords = movie.rerecords()
    
    -- Last frame info
    if not LSNES.Lastframe_emulated then LSNES.Lastframe_emulated = get_last_frame(false) end
end


function LSNES.get_controller_info()
    local info = CONTROLLER
    
    info.ports = {}
    info.total_ports = 0
    info.total_controllers = 0
    info.total_buttons = 0
    info.complete_input_sequence = ""  -- the sequence of buttons/axis for background in the movie editor
    info.total_width = 0  -- how many horizontal cells are necessary to draw the complete input
    info.button_pcid = {}  -- array that maps the n-th button of the sequence to its port/controller/button index
    
    for port = 0, 2 do  -- SNES
        info.ports[port] = input.port_type(port)
        if not info.ports[port] then break end
        info.total_ports = info.total_ports + 1
    end
    
    for lcid = 1, 8 do  -- SNES
        local port, controller = input.lcid_to_pcid2(lcid)
        local ci = (port and controller) and input.controller_info(port, controller) or nil
        
        if ci then
            info[lcid] = {port = port, controller = controller}
            info[lcid].type = ci.type
            info[lcid].class = ci.class
            info[lcid].classnum = ci.classnum
            info[lcid].button_count = ci.button_count
            info[lcid].symbol_sequence = ""
            info[lcid].controller_width = 0
            
            for button, inner in pairs(ci.buttons) do
                -- button level
                info[lcid][button] = {}
                info[lcid][button].type = inner.type
                info[lcid][button].name = inner.name
                info[lcid][button].symbol= inner.symbol
                info[lcid][button].hidden = inner.hidden
                info[lcid][button].button_width = inner.symbol and 1 or 1  -- TODO: 'or 7' for axis
                
                -- controller level
                info[lcid].controller_width = info[lcid].controller_width + info[lcid][button].button_width
                info[lcid].symbol_sequence = info[lcid].symbol_sequence .. (inner.symbol or " ")  -- TODO: axis: 7 spaces
                
                -- port level (nothing)
                
                -- input level
                info.button_pcid[#info.button_pcid + 1] = {port = port, controller = controller, button = button}
            end
            
            -- input level
            info.total_buttons = info.total_buttons + info[lcid].button_count
            info.total_controllers = info.total_controllers + 1
            info.total_width = info.total_width + info[lcid].controller_width
            info.complete_input_sequence = info.complete_input_sequence .. info[lcid].symbol_sequence
            
        else break
        end
    end
    
    info.info_loaded = true
end


-- cannot be "end" in a repaint, only in authentic paints. When script starts, it should never be authentic
function LSNES.get_movie_info()
    LSNES.pollcounter = movie.pollcounter(0, 0, 0)
    
    -- DEBUG
    if LSNES.frame_boundary ~= "middle" and LSNES.Runmode == "pause_break" then error"Frame boundary: middle case not accounted!" end
    
    MOVIE.framecount = movie.framecount()
    MOVIE.subframe_count = movie.get_size()
    
    -- CURRENT
    MOVIE.current_frame = movie.currentframe() + ((LSNES.frame_boundary == "end") and 1 or 0)
    if MOVIE.current_frame == 0 then MOVIE.current_frame = 1 end  -- after the rewind, the currentframe isn't updated to 1
    
    MOVIE.current_poll = (LSNES.frame_boundary ~= "middle") and 1 or LSNES.pollcounter + 1
    -- TODO: this should be incremented after all the buttons have been polled
    
    MOVIE.size_past_frame = LSNES.size_frame(MOVIE.current_frame - 1)  -- somehow, the order of calling size_Frame matters!
    MOVIE.size_current_frame = LSNES.size_frame(MOVIE.current_frame)  -- how many subframes of current frames are stored in the movie
    MOVIE.last_frame_started_movie = MOVIE.current_frame - (LSNES.frame_boundary == "middle" and 0 or 1) --test
    if MOVIE.last_frame_started_movie <= MOVIE.framecount then
        MOVIE.current_starting_subframe = movie.current_first_subframe() + 1
        if LSNES.frame_boundary == "end" then
            MOVIE.current_starting_subframe = MOVIE.current_starting_subframe + MOVIE.size_past_frame  -- movie.current_first_subframe() isn't updated
        end                                                                                        -- until the frame boundary is "start"
    else
        MOVIE.current_starting_subframe = MOVIE.subframe_count + (MOVIE.current_frame - MOVIE.framecount)
    end
    
    if MOVIE.size_current_frame == 0 then MOVIE.size_current_frame = 1 end  -- fix it
    MOVIE.current_internal_subframe = (MOVIE.current_poll > MOVIE.size_current_frame) and MOVIE.size_current_frame or MOVIE.current_poll
    MOVIE.current_subframe = MOVIE.current_starting_subframe + MOVIE.current_internal_subframe - 1
    -- for frames with subframes, but not written in the movie
    
    -- PAST SUBFRAME
    MOVIE.frame_of_past_subframe = MOVIE.current_frame - (MOVIE.current_internal_subframe == 1 and 1 or 0)
    
    -- TEST INPUT
    MOVIE.last_input_computed = LSNES.get_input(MOVIE.subframe_count)
end


function LSNES.size_frame(frame)
    return frame > 0 and movie.frame_subframes(frame) or -1
end


function LSNES.get_input(subframe)
    local total = MOVIE.subframe_count or movie.get_size()
    
    return (subframe <= total and subframe > 0) and movie.get_frame(subframe - 1) or false
end


function LSNES.set_input(subframe, data)
    local total = MOVIE.subframe_count or movie.get_size()
    local current_subframe = MOVIE.current_subframe
    
    if subframe <= total and subframe > current_subframe then
        movie.set_frame(subframe - 1, data)
    --[[
    elseif subframe == current_subframe then
        local lcid = 
        input.joyset(lcid, )
    --]]
    end
end


function LSNES.treat_input(input_obj)
    local presses = {}
    local index = 1
    local number_controls = CONTROLLER.total_controllers
    for lcid = 1, number_controls do
        local port, cnum = CONTROLLER[lcid].port, CONTROLLER[lcid].controller
        local is_gamepad = CONTROLLER[lcid].class == "gamepad"
        
        -- Currently shows all ports and controllers
        for control = 1, CONTROLLER[lcid].button_count do
            local button_value, str
            if is_gamepad or control > 2 then  -- only the first 2 buttons can be axis
                button_value = input_obj:get_button(port, cnum, control-1)
                str = button_value and CONTROLLER[lcid][control].symbol or " "
            else
                str = control == 1 and "x" or "y"  -- TODO: should display the whole number for axis
                --[[
                str = fmt("%+.5d ", input_obj:get_axis(port, cnum, control-1))
                --]]
            end
            
            presses[index] = str
            index = index + 1
        end
    end
    
    return table.concat(presses)
end


function LSNES.display_input()
    -- Font
    local default_color = LSNES.Readonly and COLOUR.text or 0xffff00
    local width  = LSNES_FONT_WIDTH
    local height = LSNES_FONT_HEIGHT
    
    -- Input grid settings
    local grid_width, grid_height = width*CONTROLLER.total_width, draw.Buffer_height
    local x_grid, y_grid = - grid_width, 0
    local grid_subframe_slots = grid_height//height - 1  -- discount the header
    grid_height = (grid_subframe_slots + 1)*height  -- if grid_height is not a multiple of height, cut it
    local past_inputs_number = (grid_subframe_slots - 1)//2  -- discount the present
    local future_inputs_number = grid_subframe_slots - past_inputs_number  -- current frame is included here
    local y_present = y_grid + (past_inputs_number + 1)*height  -- add header
    local x_text, y_text = x_grid, y_present - height
    
    -- Extra settings
    local color, subframe_around = nil, false
    local input
    local subframe = MOVIE.current_subframe
    local frame = MOVIE.frame_of_past_subframe -- frame corresponding to subframe-1
    local length_frame_string = #tostringx(subframe + future_inputs_number - 1)
    local x_frame = x_text - length_frame_string*width - 2
    local starting_subframe_grid = subframe - past_inputs_number
    local last_subframe_grid = subframe + future_inputs_number - 1
    
    -- Draw background
    local complete_input_sequence = CONTROLLER.complete_input_sequence
    for y = 1, grid_subframe_slots do
        gui.text(x_text, 16*y, complete_input_sequence, 0xc0ffffff)
    end
    -- Draw grid
    local colour = 0x909090
    gui.line(x_text, y_present, x_text + grid_width - 1, y_present, 0xff0000)  -- drawing the bottom base of the rectangle is misleading
    gui.rectangle(x_text, y_present, grid_width, height, 1, -1, 0xc0ff0000)  -- users should know where the past ends
    gui.rectangle(x_grid, y_grid, grid_width, grid_height, 1, colour)
    local total_previous_button = 0
    for line = 1, CONTROLLER.total_controllers, 1 do
        gui.text(x_grid + width*total_previous_button + 1, y_grid, line, colour, nil, COLOUR.halo)
        if line == CONTROLLER.total_controllers then break end
        total_previous_button = total_previous_button + CONTROLLER[line].button_count
        gui.line(x_grid + width*total_previous_button, y_grid, x_grid + width*total_previous_button, grid_height - 1, colour)
    end
    
    for subframe_id = subframe - 1, subframe - past_inputs_number, -1 do  -- discount header?
        if subframe_id <= 0 then
            starting_subframe_grid = 1
            break
        end
        
        local is_nullinput, is_startframe, is_delayedinput
        local raw_input = LSNES.get_input(subframe_id)
        if raw_input then
            input = LSNES.treat_input(raw_input)
            is_startframe = raw_input:get_button(0, 0, 0)
            if not is_startframe then subframe_around = true end
            color = is_startframe and default_color or 0xff
        elseif frame == MOVIE.current_frame then
            gui.text(0, 0, "frame == MOVIE.current_frame", "red", nil, "black") -- test -- delete
            input = LSNES.treat_input(MOVIE.last_input_computed)
            is_delayedinput = true
            color = 0x00ffff
        else
            input = "NULLINPUT"
            is_nullinput = true
            color = 0xff8080
        end
        
        gui.text(x_frame, y_text, frame, color, nil, COLOUR.halo)
        gui.text(x_text, y_text, input, color)
        
        if is_startframe or is_nullinput then
            frame = frame - 1
        end
        y_text = y_text - height
    end
    
    y_text = y_present
    frame = MOVIE.current_frame
    
    for subframe_id = subframe, subframe + future_inputs_number - 1 do
        local raw_input = LSNES.get_input(subframe_id)
        local input = raw_input and LSNES.treat_input(raw_input) or "Unrecorded"
        
        if raw_input and raw_input:get_button(0, 0, 0) then
            if subframe_id ~= MOVIE.current_subframe then frame = frame + 1 end
            color = default_color
        else
            if raw_input then
                subframe_around = true
                color = 0xff
            else
                if subframe_id ~= MOVIE.current_subframe then frame = frame + 1 end
                color = 0x00ff00
            end
        end
        
        gui.text(x_frame, y_text, frame, color, nil, COLOUR.halo)
        gui.text(x_text, y_text, input, color)
        y_text = y_text + height
        
        if not raw_input then
            last_subframe_grid = subframe_id
            break
        end
    end
    
    -- TEST -- edit
    LSNES.subframe_update = subframe_around
    gui.subframe_update(LSNES.subframe_update)
    
    -- Button settings
    local x_button = (User_input.mouse_x - x_grid)//width
    local y_button = (User_input.mouse_y - (y_grid + y_present))//height
    if x_button >= 0 and x_button < CONTROLLER.total_width and
    y_button >= 0 and y_button <= last_subframe_grid - subframe then
        gui.solidrectangle(width*(User_input.mouse_x//width), height*(User_input.mouse_y//height), width, height, 0xb000ff00)
    end
    
    x_button = x_button + 1  -- FIX IT
    local tab = CONTROLLER.button_pcid[x_button]
    if tab and LSNES.Runmode == "pause" then
        return MOVIE.current_subframe + y_button, tab.port, tab.controller, tab.button - 1  -- FIX IT, hack to edit 'B' button
    end
end


function lsnes_utils.movie_editor()
    if OPTIONS.display_controller_input then
        local subframe = LSNES.frame
        local port = LSNES.port
        local controller = LSNES.controller
        local button = LSNES.button
        if subframe and port and controller and button then
            local INPUTFRAME = LSNES.get_input(subframe)
            if INPUTFRAME then
                local status = INPUTFRAME:get_button(port, controller, button)
                if subframe <= MOVIE.subframe_count and subframe >= MOVIE.current_subframe then
                    movie.edit(subframe - 1, port, controller, button, not status)  -- 0-based
                    return true
                end
                
            end
        end
    end
    
    return false
end


function lsnes_utils.init()
    -- Get initial frame boudary state:
    LSNES.frame_boundary = movie.pollcounter(0, 0, 0) ~= 0 and "middle" or "start"  -- test / hack
    LSNES.subframe_update = false
    gui.subframe_update(LSNES.subframe_update)
    
    callback.register("input", function() LSNES.frame_boundary = "middle"; LSNES.Controller_latch_happened = false end)
    callback.register("frame_emulated", function() LSNES.frame_boundary = "end"; LSNES.Lastframe_emulated = get_last_frame(true) end)
    callback.register("frame", function() LSNES.frame_boundary = "start" end)
    callback.register("latch", function() LSNES.Controller_latch_happened = true end)
    callback.register("pre_load", function() LSNES.frame_boundary = "start"; LSNES.Lastframe_emulated = nil; LSNES.Controller_latch_happened = false end)
    callback.register("rewind", function() LSNES.frame_boundary = "start"; LSNES.Controller_latch_happened = false end)
    callback.register("movie_lost", function(kind)
        if kind == "reload" then  -- just before reloading the ROM in rec mode or closing/loading new ROM
            CONTROLLER.info_loaded = false
        elseif kind == "load" then -- this is called just before loading / use on_post_load when needed
            CONTROLLER.info_loaded = false
        end
    end)
end


return lsnes_utils