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
--config.pane_focus_follows_mouse = true

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
  {
    key = 'h',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitPane { 
      direction = "Left",
    },
  },
  {
    key = 'j',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitPane { 
      direction = "Down",
    },
  },
  {
    key = 'k',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitPane { 
      direction = "Up",
    },
  },
  {
    key = 'l',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitPane { 
      direction = "Right",
    },
  },
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { 
      confirm = true,
    },
  },
  {
    key = 'h',
    mods = 'CMD',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'CMD',
    action = act.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CMD',
    action = act.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'CMD',
    action = act.ActivatePaneDirection 'Down',
  },
  {
    key = 'H',
    mods = 'CTRL|SHIFT',
    action = act.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'J',
    mods = 'CTRL|SHIFT',
    action = act.AdjustPaneSize { 'Down', 5 },
  },
  { key = 'K', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  {
    key = 'L',
    mods = 'CTRL|SHIFT',
    action = act.AdjustPaneSize { 'Right', 5 },
  },
}

return config
