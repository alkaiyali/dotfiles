# mpv (Windows)

Config for [mpv](https://mpv.io/) on Windows.

## Install

1. Install mpv (the current machine uses the shinchiro `MPV Player` build).
2. Copy this folder to `%APPDATA%\mpv`:

   ```powershell
   New-Item -ItemType Directory -Force "$env:APPDATA\mpv" | Out-Null
   Copy-Item .\windows\mpv\* "$env:APPDATA\mpv\" -Recurse -Force
   ```

3. Restart mpv.

## What's here

- `mpv.conf` — hardware decode, resume, subtitle autoload, and no duplicate seek OSD.
- `script-opts/osc.conf` — floating OSC layout with a flat seekbar (`seekbarstyle=bar`).
- `empty.ffmetadata` — empty chapter list used by the `no-chapter-markers` profile.
- The `no-chapter-markers` profile matches files with `Spider-Man` in the path and hides
  the seekbar's chapter triangles. Remove it if you want those chapters/markers back.

`gpu-api=d3d11` is Windows-only; don't use this config unchanged on Linux.
