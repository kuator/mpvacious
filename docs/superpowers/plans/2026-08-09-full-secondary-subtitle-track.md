# Full Secondary Subtitle Track Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Include every secondary cue overlapping the mined primary cue, including cues playback has not reached, without slowing card creation.

**Architecture:** A new subtitle-track module directly parses external ASS/SRT files and asynchronously asks `ffmpeg` for embedded subtitle streams whenever the media file or secondary selection changes. It caches one `sub_list`; the observer queries that cache synchronously and falls back to its observed list until the cache is ready.

**Tech Stack:** Lua 5.1/LuaJIT, mpv Lua API, existing `helpers.subprocess` and `subtitles.sub_list`, ffmpeg.

## Global Constraints

- Card creation must never launch or wait for `ffmpeg`.
- External ASS/SRT tracks must not require `ffmpeg`; embedded tracks may use it asynchronously.
- Extraction failure, missing ffmpeg, and image subtitles must preserve current observed-cue behavior.
- A callback for an old file or track must not replace the active cache.
- Do not add a configuration option or dependency.

---

### Task 1: Parse ASS and SRT text

**Files:**
- Create: `mpvacious/subtitles/full_track.lua`
- Modify: `tests/run.lua`

**Interfaces:**
- Produces: `full_track.parse_srt(text) -> sub_list`
- Produces: `full_track.parse_ass(text) -> sub_list`
- Produces: `full_track.run_tests()`

- [ ] **Step 1: Write the failing parser test**

Add module tests containing timed SRT and ASS cues with inline formatting, and assert that `get_overlapping_text(1, 5)` returns their cleaned lines.

- [ ] **Step 2: Run the test and verify failure**

Run: `luajit tests/run.lua`

Expected: FAIL because `subtitles.full_track` does not exist.

- [ ] **Step 3: Implement the minimal parser**

Parse SRT timing blocks and ASS `[Events]` dialogue fields, remove inline formatting, and insert `Subtitle:from_text(...)` values into an existing `sub_list`.

- [ ] **Step 4: Run the tests**

Run: `luajit tests/run.lua`

Expected: `ALL TESTS PASSED`.

### Task 2: Load and cache the active secondary track

**Files:**
- Modify: `mpvacious/subtitles/full_track.lua`

**Interfaces:**
- Produces: `full_track.new() -> cache`
- Produces: `cache.refresh(track_list, media_path)`
- Produces: `cache.get_overlapping_text(start_time, end_time, delay) -> string|nil`

- [ ] **Step 1: Write failing cache tests**

Assert that external ASS/SRT files are read directly without a subprocess. Inject a fake subprocess for embedded tracks and verify the `ffmpeg -v error -nostdin -i INPUT -map 0:FF_INDEX -f srt -` contract, delayed availability, and rejection of stale callbacks.

- [ ] **Step 2: Run the tests and verify failure**

Run: `luajit tests/run.lua`

Expected: FAIL because the cache interface is absent.

- [ ] **Step 3: Implement the cache**

Keep only the active cache key, parsed list, and request generation. Directly parse supported external files; asynchronously extract embedded streams. Accept only the active callback generation. At lookup, subtract the current subtitle/audio delay from the requested interval before querying raw track timings.

- [ ] **Step 4: Run the tests**

Run: `luajit tests/run.lua`

Expected: `ALL TESTS PASSED`.

### Task 3: Use cached cues during card collection

**Files:**
- Modify: `mpvacious/subtitles/observer.lua`

**Interfaces:**
- Consumes: `cache.refresh(track_list, media_path)`
- Consumes: `cache.get_overlapping_text(start_time, end_time, delay)`

- [ ] **Step 1: Add a failing observer-level regression test**

Extract a small selection helper and assert that a ready full-track cache containing a future overlapping cue wins over the observed list, while an unavailable cache returns the observed text.

- [ ] **Step 2: Run the tests and verify failure**

Run: `luajit tests/run.lua`

Expected: FAIL because the observer still queries only observed secondary cues.

- [ ] **Step 3: Integrate the cache**

Observe native `track-list`; refresh with `mp.get_property('path')`. Replace both overlap lookups in `collect_from_current` and `collect_from_all_dialogues` with the helper that queries the full-track cache first and observed cues second.

- [ ] **Step 4: Run focused and full verification**

Run: `luajit tests/run.lua`

Expected: `ALL TESTS PASSED`.

Run: `git diff --check`

Expected: no output.

### Task 4: Update the live installation and bootstrap pin

**Files:**
- Modify: `/home/evakuator/dotfiles/scripts/optional/japanese/setup.sh`
- Modify: `/home/evakuator/dotfiles/tests/bootstrap.sh`

**Interfaces:**
- Consumes: the verified mpvacious commit containing Tasks 1-3.

- [ ] **Step 1: Update the PR branch**

Commit only the implementation and tests on `fix/deduplicate-secondary-lines`, then push that branch.

- [ ] **Step 2: Rebuild the combined deployment ref**

Combine the updated overlap branch with `fix/normalize-anki-field-comparison`, create a new immutable deployment tag, and update both dotfiles pin constants to its exact commit.

- [ ] **Step 3: Verify bootstrap and installed code**

Run: `bash tests/bootstrap.sh`

Expected: `All checks passed!`

Run the installed checkout's `luajit tests/run.lua` and verify its HEAD equals the new pinned commit.
