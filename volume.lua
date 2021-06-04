local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local xresources = require("beautiful.xresources")

local dpi = xresources.apply_dpi
local lookup_icon = require("my-awesome-widgets.iconhelper")

local function pulse_detect()
    local status = os.execute("command -v pactl")
    return status and "pulse" or "alsa"
end

local icons = {
    high   = lookup_icon.lookup_icon("audio-volume-high-symbolic"),
    medium = lookup_icon.lookup_icon("audio-volume-medium-symbolic"),
    low    = lookup_icon.lookup_icon("audio-volume-low-symbolic"),
    muted  = lookup_icon.lookup_icon("audio-volume-muted-symbolic")
}

local function creator(user_args)
    local args = user_args or {}
    local daemon = args.daemon or pulse_detect()
    local device = args.device or ((daemon == "pulse") and "0" or "Master")
    if type(device) ~= "string" then device = tostring(device) end
    local step = args.step or 1
    local jump = args.jump or (step * 5)
    local command = {}
    if daemon == "pulse" then
        command.get = "pacmd list-sinks | sed -n -e '/index/p;/base volume/d;/volume:/p;/muted:/p;/device\\.string/p'"
        command.dec = "pactl set-sink-volume " .. device .. " -%s%%"
        command.inc = "pactl set-sink-volume " .. device .. " +%s%%"
        command.mut = "pactl set-sink-mute "   .. device .. " toggle"
    else
        command.get = "amixer sget " .. device
        command.dec = "amixer sset " .. device .. " %s%%-"
        command.inc = "amixer sset " .. device .. " %s%%+"
        command.mut = "amixer sset " .. device .. " toggle"
    end
    local timeout = args.timeout or 5

    local volume_widget = wibox.widget {
        {
            id = "iconcontainer",
            top = dpi(2),
            bottom = dpi(2),
            layout = wibox.container.margin,
            {
                id = "icon",
                resize = true,
                widget = wibox.widget.imagebox
            }
        },
        {
            id = "text",
            widget = wibox.widget.textbox
        },
        spacing = dpi(4),
        layout = wibox.layout.fixed.horizontal
    }
    
    function volume_widget:update()
        awful.spawn.easy_async('sh -c "' .. command.get .. '"', function (stdout)
            local level = (daemon == "pulse") and stdout:match("(%d+)%%") or stdout:match("%[(%d+)%%%]")

            local muted = (daemon == "pulse") and stdout:match("muted: (%D%D%D?)") or stdout:match("%[(%D%D%D?)%]")
            if muted == "on"  then muted = "yes" end
            if muted == "off" then muted = "no"  end

            local text = nil
            local icon = nil
            
            if level == nil or muted == "yes" then
                icon = icons.muted
            else
                local nlevel = tonumber(level)
                if nlevel <= 30 then
                    icon = icons.low
                elseif nlevel >= 70 then
                    icon = icons.high
                else
                    icon = icons.medium
                end
                text = level
            end

            self.text:set_text(text or "")
            self.iconcontainer.icon:set_image(icon:load_surface())
            self:emit_signal("widget::redraw_needed")
        end)
    end
    
    function volume_widget:dec(s)
        awful.spawn.easy_async(command.dec:format(s), function ()
            self:update()
        end)
    end

    function volume_widget:inc(s)
        awful.spawn.easy_async(command.inc:format(s), function ()
            self:update()
        end)
    end

    function volume_widget:mut()
        awful.spawn.easy_async(command.mut, function ()
            self:update()
        end)
    end
    
    volume_widget:buttons(gears.table.join(
        awful.button({}, 3, nil, function ()
            volume_widget:mut()
        end),
        awful.button({}, 5, nil, function ()
            volume_widget:inc(step)
        end),
        awful.button({ "Shift" }, 5, nil, function ()
            volume_widget:inc(jump)
        end),
        awful.button({}, 4, nil, function ()
            volume_widget:dec(step)
        end),
        awful.button({ "Shift" }, 4, nil, function ()
            volume_widget:dec(jump)
        end)
    ))
    
    volume_widget.timer = gears.timer {
        timeout = timeout,
        call_now = true,
        autostart = true,
        callback = function ()
            volume_widget:update()
        end
    }

    return volume_widget
end

return setmetatable({}, { __call = function(_, ...) return creator(...) end })

