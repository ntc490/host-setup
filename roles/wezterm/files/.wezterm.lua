local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font 'SFMono Nerd Font'
config.font_size = 18
config.enable_tab_bar = false
-- config.window_background_image = "/Users/ncrapo/personal/wallpaper/shell/corsair_2-wallpaper-3840x1600.jpg"
config.window_background_opacity = 0.68
config.text_background_opacity = 0.68
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"

return config
