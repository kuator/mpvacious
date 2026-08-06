--[[
Copyright: Ajatt-Tools and contributors; https://github.com/Ajatt-Tools
License: GNU GPL, version 3 or later; http://www.gnu.org/licenses/gpl.html

Subtitle list remembers selected subtitle lines.
]]

local h = require('helpers')
local CONCAT_CHR = '\n' -- character used to concatenate subtitle lines

local new_sub_list = function(deduplicate_lines)
    local subs_list = {}

    local append_text = function(speech, text)
        if not deduplicate_lines then
            table.insert(speech, text)
            return
        end
        local normalized_text = text:gsub('\r\n', '\n'):gsub('\r', '\n')
        local lines = {}
        for line in (normalized_text .. '\n'):gmatch('(.-)\n') do
            table.insert(lines, line)
        end
        local overlap = math.min(#speech, #lines)
        while overlap > 0 do
            local matches = true
            for i = 1, overlap do
                if speech[#speech - overlap + i] ~= lines[i] then
                    matches = false
                    break
                end
            end
            if matches then
                break
            end
            overlap = overlap - 1
        end
        for i = overlap + 1, #lines do
            table.insert(speech, lines[i])
        end
    end

    local get_time = function(position)
        local i = position == 'start' and 1 or #subs_list
        return subs_list[i][position]
    end
    local get_text = function()
        local speech = {}
        for _, sub in ipairs(subs_list) do
            append_text(speech, sub['text'])
        end
        return table.concat(speech, CONCAT_CHR)
    end
    local get_n_text = function(sub, n_lines)
        local speech = {}
        local end_sub = sub
        local n_subs = 0
        for _, v in ipairs(subs_list) do
            if v['start'] - end_sub['end'] >= 20 then
                break
            end
            if v >= sub and n_subs < n_lines then
                append_text(speech, v['text'])
                end_sub = v
                n_subs = n_subs + 1
            end
        end
        return table.concat(speech, CONCAT_CHR), end_sub
    end
    local get_overlapping_text = function(start_time, end_time)
        local speech = {}
        for _, sub in ipairs(subs_list) do
            if sub.start < end_time and sub['end'] > start_time then
                append_text(speech, sub.text)
            end
        end
        local normalized = {}
        for _, text in ipairs(speech) do
            text = text:gsub('%s+', ' '):match('^%s*(.-)%s*$')
            if not h.is_empty(text) then
                table.insert(normalized, text)
            end
        end
        return table.concat(normalized, ' ')
    end
    local insert = function(sub)
        if sub == nil or h.is_empty(sub.text) then
            return false
        end
        local lookup_window_size = 25
        local n_latest_subs = {h.unpack(subs_list, math.max(#subs_list - lookup_window_size, 1), #subs_list)}
        for _, known_sub in ipairs(n_latest_subs) do
            if known_sub:is_same_event(sub) then
                return false
            end
        end
        table.insert(subs_list, (#subs_list - #n_latest_subs) + h.find_insertion_point(n_latest_subs, sub), sub)
        return true
    end
    local get_subs_list = function()
        local copy = {}
        for key, value in pairs(subs_list) do
            copy[key] = value
        end
        return copy
    end
    return {
        get_subs_list = get_subs_list,
        get_time = get_time,
        get_text = get_text,
        get_n_text = get_n_text,
        get_overlapping_text = get_overlapping_text,
        insert = insert,
        is_empty = function()
            return h.is_empty(subs_list)
        end,
    }
end

return {
    new = new_sub_list,
}
