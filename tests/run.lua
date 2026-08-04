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
-- Run note_exporter tests
------------------------------------------------------------

print("Running note_exporter tests...")
local note_exporter = require('anki.note_exporter')
note_exporter.run_tests()
print("note_exporter tests passed.")

------------------------------------------------------------

print("Running subtitle list tests...")
local sub_list = require('subtitles.sub_list')
local Subtitle = require('subtitles.subtitle')
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
print("subtitle list tests passed.")

------------------------------------------------------------

print("ALL TESTS PASSED")
