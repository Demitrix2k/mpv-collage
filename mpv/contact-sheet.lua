-- contact-sheet.lua: save an MPC-HC style thumbnail sheet of the current file.
-- Bound to ctrl+shift+s in input.conf; the work is done by mpv-contact-sheet.
local mp = require 'mp'

local script = (os.getenv('XDG_BIN_HOME') or (os.getenv('HOME') .. '/.local/bin')) .. '/mpv-contact-sheet'
local running = false

local function make_sheet()
    local path = mp.get_property('path')
    if not path or path:match('^%a[%w+.-]*://') then
        mp.osd_message('Contact sheet: local files only')
        return
    end
    if running then
        mp.osd_message('Contact sheet: already running')
        return
    end
    running = true
    mp.osd_message('Contact sheet: working...', 60)
    mp.command_native_async({
        name = 'subprocess',
        args = { script, mp.command_native({ 'normalize-path', path }) },
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, res)
        running = false
        if success and res.status == 0 then
            local out = res.stdout:gsub('%s+$', '')
            mp.osd_message('Contact sheet saved: ' .. out, 6)
            mp.msg.info('contact sheet: ' .. out)
        else
            local err = success and res.stderr or 'could not start the script'
            mp.osd_message('Contact sheet failed (see log)', 6)
            mp.msg.error(err)
        end
    end)
end

mp.add_key_binding(nil, 'contact-sheet', make_sheet)
