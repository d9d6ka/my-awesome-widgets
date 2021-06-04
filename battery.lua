local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local xresources   = require("beautiful.xresources")

local dpi = xresources.apply_dpi
local lookup_icon = require("my-awesome-widgets.iconhelper")

local icon_template = "battery-level-%s%s-symbolic"
local icon_caution  = "battery-caution-symbolic"
local icon_missing  = "battery-missing-symbolic"

local function battery_status(s)
    local input = s:gsub("\n$", "")
    local batteries = {}
    local total_charge = 0
    local total_capacity = 0
    local is_charging = false
    local popup_text = ""
    for line in input:gmatch("[^\r\n]*") do
        if line ~= "" then
            status, charge, time = line:match(".*: (%a*), (%d*%d)%%,?(.*)")
            if status ~= nil then
                if time ~= "" then
                    time = time:match("%D*(%d%d:%d%d).*")
                end
                table.insert(batteries, {
                    status = status,
                    charge = tonumber(charge),
                    time = time or ""
                })
            else
                capacity = line:match(".*, last full capacity (%d*).*")
                batteries[#batteries].capacity = tonumber(capacity)
            end
        end
    end
    for _, battery in pairs(batteries) do
        total_charge = total_charge + battery.charge * battery.capacity / 100
        total_capacity = total_capacity + battery.capacity
        is_charging = (battery.status == "Charging") or is_charging
        popup_text = popup_text .. "\n" .. battery.status .. ((battery.time ~= "") and (", " .. battery.time .. " remaining") or "")
    end
    popup_text = popup_text:gsub("^\n", "")
    return is_charging, total_charge, total_capacity, popup_text, batteries
end

local function creator(user_args)
    local args = user_args or {}
    local timeout = args.timeout or 30

    local battery_widget = wibox.widget {
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
    
    function battery_widget:update(s)
        local is_charging, charge, capacity, popup, batteries = battery_status(s)
        local percent = #batteries > 0 and math.floor(100 * charge / capacity) or ""
        local icon = ""
        if #batteries == 0 then
            icon = lookup_icon.lookup_icon(icon_missing)
        elseif percent < 10 and not is_charging then
            icon = lookup_icon.lookup_icon(icon_caution)
        else
            icon = lookup_icon.lookup_icon(string.format(icon_template, percent - percent % 10, is_charging and "-charging" or ""))
        end
        self.tooltip_text = popup
        self.text:set_text((percent ~= "") and percent .. "%" or "")
        self.iconcontainer.icon:set_image(icon:load_surface())
        self:emit_signal("widget::redraw_needed")
    end
    
    battery_widget.tooltip = awful.tooltip {
        objects = {
            battery_widget
        },
    }
    battery_widget:connect_signal("mouse::enter", function ()
        battery_widget.tooltip:set_text(battery_widget.tooltip_text)
    end)

    battery_widget.timer = gears.timer {
        timeout = timeout,
        call_now = true,
        autostart = true,
        callback = function()
            awful.spawn.easy_async_with_shell([[acpi -i]], function (stdout)
                battery_widget:update(stdout or "")
            end)
        end
    }

    return battery_widget
end

return setmetatable({}, { __call = function(_, ...) return creator(...) end })
