-- collage.lua: poster-style collage of the current movie or season.
-- Bound to ctrl+shift+c in input.conf; the work is done by mpv-collage.
-- If the file's folder holds several videos (a season) the collage uses the
-- whole folder, otherwise just this file.
local mp = require 'mp'
local utils = require 'mp.utils'

local bindir = os.getenv('XDG_BIN_HOME') or (os.getenv('HOME') .. '/.local/bin')
local script = bindir .. '/mpv-collage'
local video_ext = { mkv = 1, mp4 = 1, m4v = 1, avi = 1, mov = 1, webm = 1, ts = 1, wmv = 1 }
local running = false

local function video_count(dir)
    local n = 0
    for _, f in ipairs(utils.readdir(dir, 'files') or {}) do
        if video_ext[(f:match('%.(%w+)$') or ''):lower()] then n = n + 1 end
    end
    return n
end

local function make_collage()
    local path = mp.get_property('path')
    if not path or path:match('^%a[%w+.-]*://') then
        mp.osd_message('Collage: local files only')
        return
    end
    if running then
        mp.osd_message('Collage: already running')
        return
    end
    path = mp.command_native({ 'normalize-path', path })
    local dir = utils.split_path(path):gsub('/$', '')
    local target = video_count(dir) > 1 and dir or path
    running = true
    mp.osd_message('Collage: working...', 120)
    mp.command_native_async({
        name = 'subprocess',
        args = { script, target },
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, res)
        running = false
        if success and res.status == 0 then
            local out = res.stdout:gsub('%s+$', ''):match('[^\n]+$')
            mp.osd_message('Collage saved: ' .. out, 8)
            mp.msg.info('collage: ' .. out)
        else
            mp.osd_message('Collage failed (see log)', 6)
            mp.msg.error(success and res.stderr or 'could not start the script')
        end
    end)
end

mp.add_key_binding(nil, 'collage', make_collage)
