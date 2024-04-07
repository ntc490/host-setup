local wezterm = require 'wezterm'
local config = {}
local my_opacity = 0.68

function toggler(window, pane)
   local overrides = window:get_config_overrides() or {}
   if overrides.window_background_opacity then
      wezterm.log_info 'repeat change-up!'
      if overrides.window_background_opacity < 1 then
         overrides.window_background_opacity = 1
         overrides.text_background_opacity = 1
      else
         overrides.window_background_opacity = my_opacity
         overrides.text_background_opacity = my_opacity
      end
   else
      wezterm.log_info 'first time override!'
      if config.window_background_opacity == nil then
         overrides.window_background_opacity = my_opacity
         overrides.text_background_opacity = my_opacity
      elseif config.window_background_opacity < 1 then
         overrides.window_background_opacity = 1
         overrides.text_background_opacity = 1
      else
         overrides.window_background_opacity = my_opacity
         overrides.text_background_opacity = my_opacity
      end
   end
   window:set_config_overrides(overrides)
end

config.font = wezterm.font 'SFMono Nerd Font'
config.font_size = 18
config.enable_tab_bar = false
--config.window_background_image = "/Users/ncrapo/personal/wallpaper/shell/corsair_2-wallpaper-3840x1600.jpg"
config.window_background_opacity = my_opacity
config.text_background_opacity = my_opacity
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.keys = {
   { key = 'u', mods = 'SUPER', action = wezterm.action_callback(function(win, pane)
           wezterm.log_info 'callback!'
           toggler(win, pane)
   end), },
}

return config
