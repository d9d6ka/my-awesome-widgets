local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local lookup_icon = require("my-widgets.iconhelper")

local function identify_distro()
    local f = assert(io.popen([[cat /etc/os-release | grep '^ID=' | awk 'BEGIN {FS="="} {print $2}' | sed -e 's/^"//' -e 's/"$//']]))
    local s = assert(f:read('*a'))
    f:close()
    s = s:gsub("\n", "")
    return s
end

local function parse_config(path)
    local file = io.open(path, "rb")
    if not file then return {} end
    file:close()
    
    res = {}
    for line in io.lines(path) do
        if #line ~= 0 then
            local d, c = line:match("([^= ]*)[ ]+=[ ]+(.*)")
            d = d:gsub("\n$", "")
            c = c:gsub("\n$", "")
            res[d] = c
        end
    end
    return res
end

local icons = {
    updates  = lookup_icon.lookup_icon("arch-updates-symbolic"),
    uptodate = lookup_icon.lookup_icon("arch-uptodate-symbolic")
}

local function creator(user_args)
    local args = user_args or {}
    local timeout = args.timeout or 900
    local distro = args.distro or identify_distro()
    local config = args.config or "~/.config/awesome/my-widgets/newpackages.conf"
    config = config:gsub("^~", os.getenv("HOME"))

    local commands = parse_config(config)
    local command  = commands[distro] or "exit"

    local newpackages_widget = wibox.widget {
        {
            id = "iconcontainer",
            top = 4,
            bottom = 4,
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
        spacing = 4,
        layout = wibox.layout.fixed.horizontal
    }
    
    function newpackages_widget:update()
        awful.spawn.easy_async('sh -c "' .. command .. '"', function (stdout)
            self.iconcontainer.icon:set_image(((stdout == "0\n") and icons.uptodate or icons.updates):load_surface())
            self.text:set_text(stdout)
            self:emit_signal("widget::redraw_needed")
        end)
    end

    newpackages_widget:buttons(gears.table.join(
        awful.button({}, 1, nil, function ()
            newpackages_widget:update()
        end)
    ))
    
    newpackages_widget.timer = gears.timer {
        timeout = timeout,
        call_now = true,
        autostart = true,
        callback = function ()
            newpackages_widget:update()
        end
    }

    return newpackages_widget
end

return setmetatable({}, { __call = function(_, ...) return creator(...) end })

