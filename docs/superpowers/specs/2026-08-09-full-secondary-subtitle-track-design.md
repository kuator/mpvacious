# Full secondary subtitle track

## Goal

When a primary subtitle spans secondary cues that have not appeared onscreen yet, include every overlapping secondary cue in the exported note without delaying card creation.

## Design

Load the selected secondary subtitle track when the media file or secondary track changes. Parse external ASS/SRT files directly; asynchronously use `ffmpeg` only to extract embedded text-subtitle streams. Cache the resulting subtitle list.

Card collection remains synchronous and small: query the cached list for cues overlapping the primary timing. If the cache is unavailable, still loading, or extraction fails, fall back to the secondary cues already observed by mpvacious.

Cache only the active file and secondary track in memory. Replacing either invalidates the old list. Unsupported external formats, image subtitles, and embedded tracks without `ffmpeg` use the existing fallback.

## Errors

Parsing or extraction failure is logged once and must not prevent note creation. Stale asynchronous results must not replace the cache after the user changes files or tracks.

## Verification

Add a regression test where only the first secondary cue has appeared but the cached full track includes a later cue overlapping the primary interval. Keep the existing subtitle-list tests and run the complete test suite.
