local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local lookup_icon = require("my-widgets.iconhelper")

local icon = lookup_icon.lookup_icon('alarm-symbolic')

local function creator(user_args)
    local clock_widget = wibox.widget {
        {
            top = 4,
            bottom = 4,
            layout = wibox.container.margin,
            id = 'iconcontainer',
            {
                id = 'icon',
                resize = true,
                image = icon:load_surface(),
                widget = wibox.widget.imagebox
            }
        },
        {
            format = "%H:%M",
            widget = wibox.widget.textclock
        },
        spacing = 4,
        layout = wibox.layout.fixed.horizontal
    }

    clock_widget.tooltip = awful.tooltip {
        objects = {
            clock_widget
        },
    }
    clock_widget:connect_signal("mouse::enter", function ()
        clock_widget.tooltip:set_text(os.date("%A\n%d %B %Y"))
    end)

    return clock_widget
end

return setmetatable({}, { __call = function(_, ...) return creator(...) end })
