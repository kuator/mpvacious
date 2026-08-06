--[[
Copyright: Ajatt-Tools and contributors; https://github.com/Ajatt-Tools
License: GNU GPL, version 3 or later; http://www.gnu.org/licenses/gpl.html

Standalone test runner for mpvacious.
Runs without mpv using the stubs registered by tests/setup.lua.

Usage: luajit tests/run.lua
       (run from the project root directory)
]]

require('tests.setup')

------------------------------------------------------------
-- Run helpers tests
------------------------------------------------------------

print("Running helpers tests...")
local h = require('helpers')
h.run_tests()
print("helpers tests passed.")

------------------------------------------------------------
-- Run encoder utility tests
------------------------------------------------------------

print("Running encoder utility tests...")
local eutils = require('encoder.utils')
eutils.run_tests()
print("encoder utility tests passed.")

------------------------------------------------------------
-- Run config utility tests
------------------------------------------------------------

print("Running config utility tests...")
local cfg_utils = require('config.utils')
cfg_utils.run_tests()
print("config utility tests passed.")

------------------------------------------------------------
-- Run note_exporter tests
------------------------------------------------------------

print("Running note_exporter tests...")
local note_exporter = require('anki.note_exporter')
note_exporter.run_tests()
print("note_exporter tests passed.")

------------------------------------------------------------

print("Running subtitle tests...")
local Subtitle = require('subtitles.subtitle')
Subtitle.run_tests()
print("subtitle tests passed.")

------------------------------------------------------------

print("Running subtitle list tests...")
local sub_list = require('subtitles.sub_list')
local first = Subtitle:new { text = "First line", start = 0, ['end'] = 2 }
local expanded = Subtitle:new { text = "First line\nSecond line", start = 1, ['end'] = 3 }
local secondary_subs = sub_list.new(true)
secondary_subs.insert(first)
secondary_subs.insert(expanded)
assert(secondary_subs.get_text() == "First line\nSecond line")
assert(secondary_subs.get_n_text(first, 2) == "First line\nSecond line")
local primary_subs = sub_list.new()
primary_subs.insert(first)
primary_subs.insert(expanded)
assert(primary_subs.get_text() == "First line\nFirst line\nSecond line")
assert(primary_subs.get_n_text(first, 2) == "First line\nFirst line\nSecond line")
local formatted_subs = sub_list.new(true)
formatted_subs.insert(Subtitle:new { text = "First line\n\nSecond line", start = 0, ['end'] = 2 })
assert(formatted_subs.get_text() == "First line\n\nSecond line")
local repeated_subs = sub_list.new(true)
repeated_subs.insert(Subtitle:new { text = "Yes", start = 0, ['end'] = 1 })
repeated_subs.insert(Subtitle:new { text = "No", start = 1, ['end'] = 2 })
repeated_subs.insert(Subtitle:new { text = "Yes\nAgain", start = 2, ['end'] = 3 })
assert(repeated_subs.get_text() == "Yes\nNo\nYes\nAgain")
local aligned_subs = sub_list.new(true)
aligned_subs.insert(Subtitle:new { text = "First line", start = 0, ['end'] = 1.5 })
aligned_subs.insert(Subtitle:new { text = "First line\nSecond line", start = 1.5, ['end'] = 3 })
aligned_subs.insert(Subtitle:new { text = "Outside", start = 4, ['end'] = 5 })
assert(aligned_subs.get_overlapping_text(1, 3) == "First line Second line")
assert(aligned_subs.get_overlapping_text(3, 4) == "")
assert(aligned_subs.insert(Subtitle:new { text = "First line", start = 10, ['end'] = 11 }))
assert(not aligned_subs.insert(Subtitle:new { text = "First line", start = 10.1, ['end'] = 11.1 }))
print("subtitle list tests passed.")

------------------------------------------------------------

print("Running subtitle observer tests...")
local subs_observer = require('subtitles.observer')
subs_observer.import_subs {
    Subtitle:new { text = "Japanese", start = 1, ['end'] = 3 },
    Subtitle:new { text = "First line", start = 0, ['end'] = 1.5, is_secondary = true },
    Subtitle:new { text = "First line\nSecond line", start = 1.5, ['end'] = 3, is_secondary = true },
    Subtitle:new { text = "Outside", start = 4, ['end'] = 5, is_secondary = true },
}
local mined_sub = subs_observer.collect_from_current()
assert(mined_sub.text == "Japanese")
assert(mined_sub.secondary == "First line Second line")
print("subtitle observer tests passed.")

------------------------------------------------------------

print("Running quick subtitle observer tests...")
local mp = require('mp')
local properties = {
    ['sub-text'] = "Japanese",
    ['sub-start'] = 1,
    ['sub-end'] = 3,
    ['secondary-sub-text'] = "First line",
    ['secondary-sub-start'] = 0,
    ['secondary-sub-end'] = 1.5,
    ['sub-delay'] = 0,
    ['audio-delay'] = 0,
}
mp.get_property = function(name) return properties[name] end
mp.get_property_number = function(name) return properties[name] end
mp.get_property_native = function(name) return properties[name] end
subs_observer.clear_all_dialogs()
subs_observer.all_subs_until_now()
properties['secondary-sub-text'] = "First line\nSecond line"
properties['secondary-sub-start'] = 1.5
properties['secondary-sub-end'] = 3
subs_observer.all_subs_until_now()
local quick_sub = subs_observer.collect_from_all_dialogues(1)
assert(quick_sub.text == "Japanese")
assert(quick_sub.secondary == "First line Second line")
print("quick subtitle observer tests passed.")

------------------------------------------------------------

print("ALL TESTS PASSED")
