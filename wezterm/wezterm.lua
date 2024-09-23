local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Your settings here
config.color_scheme = 'tokyonight_storm'
config.font = wezterm.font 'Inconsolata Nerd Font Mono'
config.font_size = 28.0
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.default_prog = { 'bash', '-cl', '/Users/rob/.nix-profile/bin/fish' }
config.audible_bell = "Disabled"

local act = wezterm.action

config.keys = {
  -- CMD-y starts `top` in a new tab
  {
    key = 't',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { 'bash', '-cl', '/Users/rob/.nix-profile/bin/fish' },
      cwd = "/Users/rob/",
      domain = "CurrentPaneDomain",
    },
  },
}

return config
