--[[
* Gainz - Displays FFXI recurring event time info.
* Author: Commandobill
* Version: 1.0
* License: GNU General Public License v3.0
--]]

addon.name    = 'gainz';
addon.author  = 'Commandobill';
addon.version = '1.0';
addon.desc    = 'Displays Gainz event timer info on demand.';

require('common');
local chat = require('chat');

-- Define UTC event windows (0 = Sunday)
local event_times = {
    { day = 0, start = 11 * 60, finish = 15 * 60 },   -- Sunday 11:00–15:00 UTC
    { day = 2, start = 3 * 60, finish = 7 * 60 },     -- Tuesday 03:00–07:00 UTC
    { day = 3, start = 19 * 60, finish = 23 * 60 },   -- Wednesday 19:00–23:00 UTC
}

-- Helper to format duration in h m
local function format_time(minutes)
    local h = math.floor(minutes / 60)
    local m = minutes % 60
    return string.format('%dh %dm', h, m)
end

-- Core logic
local function get_gainz_status()
    local now = os.date('!*t') -- UTC time
    local wday = now.wday - 1  -- Sunday=1 in Lua, so subtract 1
    local curr_min = now.hour * 60 + now.min

    local closest_diff = math.huge
    local next_msg = nil

    for _, event in ipairs(event_times) do
        local day_offset = (event.day - wday) % 7
        local start_min = day_offset * 1440 + event.start
        local end_min = day_offset * 1440 + event.finish
        local now_total = 0

        if day_offset == 0 then
            now_total = curr_min
            if now_total >= event.start and now_total < event.finish then
                -- Currently active
                local minutes_left = event.finish - now_total
                return chat.header(addon.name) .. chat.message('Gainz is active! Ends in ' .. format_time(minutes_left) .. '.')
            end
        end

        local time_until_start = start_min - curr_min
        if time_until_start < closest_diff then
            closest_diff = time_until_start
            next_msg = 'Gainz will start in ' .. format_time(time_until_start) .. '.'
        end
    end

    return chat.header(addon.name) .. chat.message(next_msg or 'Unable to determine gainz time.')
end

-- Register the /gainz command
ashita.events.register('command', 'gainz_command_cb', function(e)
    local args = e.command:args()
    if #args >= 1 and args[1]:lower() == '/gainz' then
        print(get_gainz_status())
        return true
    end
    return false
end)
