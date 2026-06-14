-- =============================================================================
-- ACTIVE: Hyprland 0.55+ Lua config. Wired in home/desktop/hyprland/default.nix
-- as `xdg.configFile."hypr/hyprland.lua".source`. Because Hyprland loads this
-- in preference to hyprland.conf when both are present, settings.nix and
-- bindings.nix are currently INERT — kept on disk as a hyprlang fallback you
-- can revert to by removing the xdg.configFile line.
--
-- API names, field names, and dispatcher names below were verified against
-- the upstream source at github.com/hyprwm/Hyprland under src/config/lua/.
-- =============================================================================
--
-- Lua quick reference for nix-natives:
--   --  line comment        --[[ ... ]]  block comment
--   local x = 1             local-scoped binding (no `local` => global, avoid)
--   t = { a = 1, b = 2 }    table with string keys (a "record")
--   t = { 1, 2, 3 }         table with integer keys (a "list", 1-indexed)
--   "foo" .. "bar"          string concat (`..`, not `+`)
--   for i = 1, 9 do ... end inclusive on both ends; step defaults to 1
--   if c then ... end       no parens needed; `then`/`end` delimit
--   function() ... end      anonymous function; `end` closes it
--   obj:method(x)           sugar for obj.method(obj, x)  ("self" passed in)
--
-- The Hyprland API exposes a single global `hl` table:
--   hl.config{...}        merge a settings block (callable many times)
--   hl.env(key, val)      set an environment variable
--   hl.monitor{output=..} register a monitor rule (output is REQUIRED)
--   hl.workspace_rule{...}, hl.window_rule{...}, hl.layer_rule{...}
--   hl.curve(name, ...)   define a bezier/spring
--   hl.animation{...}     configure one animation leaf
--   hl.gesture{...}, hl.device{...}, hl.permission(...)
--   hl.bind(keys, action, opts?)   register a keybind
--   hl.define_submap("name", fn)   declare a submap; binds inside fn belong to it
--   hl.unbind(keys) / hl.unbind("all")
--   hl.on(event, fn)      subscribe to a lifecycle event
--   hl.timer(fn, {timeout=ms, type="oneshot"|"repeat"})
--   hl.exec_cmd(cmd)      run a command (top-level helper, distinct from
--                         hl.dsp.exec_cmd which is the dispatcher)
--
-- Dispatchers live under `hl.dsp`. Each dispatcher returns an action object
-- that you pass as the second argument to hl.bind. Confirmed names:
--   hl.dsp.exec_cmd(cmd)              hl.dsp.exec_raw(cmd)
--   hl.dsp.exit()                     hl.dsp.submap("name")  hl.dsp.no_op()
--   hl.dsp.layout("togglesplit")      hl.dsp.dpms{...}        hl.dsp.event(...)
--   hl.dsp.global(name)               hl.dsp.pass{window=...} hl.dsp.send_shortcut(...)
--   hl.dsp.send_key_state(...)        hl.dsp.force_renderer_reload() hl.dsp.force_idle(n)
--   hl.dsp.focus{...}                 -- direction|monitor|workspace|window|urgent_or_last|last
--   hl.dsp.window.{close,kill,signal,float,fullscreen,fullscreen_state,pseudo,
--                  move,swap,center,cycle_next,tag,clear_tags,toggle_swallow,
--                  pin,bring_to_top,alter_zorder,set_prop,deny_from_group,
--                  drag,resize}
--   hl.dsp.group.{toggle,next,prev,active,move_window,lock,lock_active}
--   hl.dsp.workspace.{rename,move,swap_monitors,toggle_special}
--   hl.dsp.cursor.{move_to_corner,move}
--
-- For a full runnable upstream example see:
--   https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
-- =============================================================================


-- ----------------------------------------------------------------------------
-- HOST SELECTION
-- ----------------------------------------------------------------------------
-- In the Nix module these are passed via `additionalConfig`. Here, since each
-- host gets its own deployed file, the simplest path is to hardcode per-host.
-- For the prototype we Lua-detect NVIDIA presence so one file works on all
-- three hosts; in production you'd probably template this from Nix.
local isNvidia = io.open("/proc/driver/nvidia/version", "r") ~= nil
-- io.open returns a file handle or nil; `~=` is "not equal to" in Lua
-- (yes, really; `!=` is invalid syntax).


-- ----------------------------------------------------------------------------
-- VARIABLES (replaces `$mod`, `$terminal`, ... from hyprlang)
-- ----------------------------------------------------------------------------
-- In hyprlang you wrote `$mod = SUPER` and used `$mod` later. In Lua you just
-- use a regular local variable; there are no special "$" variables.
local mod         = "SUPER"
local terminal    = "kitty"
local fileManager = "thunar"

-- noctalia wrapper command. Runtime-detected so one file works across hosts:
--   workstation has the v5 binary `noctalia`; the laptops have v4's
--   `noctalia-shell`. We probe `command -v` once at config load.
local function commandExists(cmd)
    -- io.popen runs the command and gives us its stdout as a file handle.
    -- :read("*l") pulls one line; nil/empty means the command wasn't found.
    local f = io.popen("command -v " .. cmd .. " 2>/dev/null")
    if not f then return false end
    local line = f:read("*l")
    f:close()
    return line ~= nil and line ~= ""
end

local noctaliaV5    = commandExists("noctalia")
local noctalia      = noctaliaV5 and "noctalia msg" or "noctalia-shell ipc call"
local noctaliaLaunch = noctaliaV5 and "noctalia"
                                   or "env QT_QPA_PLATFORMTHEME= noctalia-shell"


-- ----------------------------------------------------------------------------
-- ENVIRONMENT VARIABLES
-- ----------------------------------------------------------------------------
-- hl.env(KEY, VALUE) — both strings. One call per variable.
hl.env("NIXOS_OZONE_WL",                    "1")
hl.env("MOZ_ENABLE_WAYLAND",                "1")
hl.env("MOZ_WEBRENDER",                     "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING",       "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORM",                   "wayland")
hl.env("SDL_VIDEODRIVER",                   "wayland")
hl.env("GDK_BACKEND",                       "wayland")

if isNvidia then
    -- `if` blocks end with `end`. No `endif`, no braces.
    hl.env("GBM_BACKEND",               "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("LIBVA_DRIVER_NAME",         "nvidia")
    -- No AQ_DRM_DEVICES: single GPU, and the card number is unstable across
    -- boots (card0 vs card1). Aquamarine auto-detects the one card.
end


-- ----------------------------------------------------------------------------
-- AUTOSTART (replaces `exec-once`)
-- ----------------------------------------------------------------------------
-- The Lua API uses an event hook instead of a top-level list. Subscribe a
-- function to "hyprland.start" and call hl.exec_cmd for each program.
hl.on("hyprland.start", function()
    hl.exec_cmd("code")
    hl.exec_cmd(noctaliaLaunch)  -- v4 / v5 picked by commandExists() above
    hl.exec_cmd("wl-paste --watch cliphist store")
end)


-- ----------------------------------------------------------------------------
-- INPUT
-- ----------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout    = "us,fr",
        kb_options   = "grp:win_space_toggle",
        follow_mouse = 1,
        mouse_refocus = true,
        touchpad = {
            natural_scroll = true,  -- Lua has real booleans, no "yes"/"no" strings
        },
    },
})


-- ----------------------------------------------------------------------------
-- LOOK & FEEL
-- ----------------------------------------------------------------------------
-- Multiple hl.config calls merge — they don't overwrite. The upstream example
-- splits by concern; we keep one big block since it mirrors settings.nix.
hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 0,
        border_size = 1,
    },

    dwindle = {
        -- `pseudotile` is NOT a config key in 0.55 — it's the dispatcher
        -- `hl.dsp.window.pseudo()`, bound below to SUPER+P. The hyprlang
        -- config had `pseudotile = true` which was always a no-op key.
        preserve_split = true,
        force_split    = 2,
    },

    render = {
        -- NOTE: `cm_fs_passthrough` was REMOVED in 0.55 (verified: not in
        -- src/config/values/ConfigValues.cpp). The current settings.nix line 73
        -- already silently errors out on a 0.55 rebuild — independent of Lua.
        -- cm_fs_passthrough = 2,  -- removed
        cm_auto_hdr = 2,  -- range 0..2, or "disable"/"hdr"/"hdredid"
    },

    decoration = {
        rounding = 4,
        blur = {
            enabled  = true,
            size     = 8,
            passes   = 3,
            vibrancy = 0.17,  -- frosted-glass tint of what's behind
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
})


-- ----------------------------------------------------------------------------
-- MONITORS
-- ----------------------------------------------------------------------------
-- In hyprlang you had two lists: `monitor` (legacy) and `monitorv2`. The Lua
-- API exposes a single `hl.monitor{}` per output, with all HDR fields as
-- typed siblings. `output` is REQUIRED; for EDID-based matching, prefix it
-- with "desc:" exactly as you did in hyprlang. There is no separate
-- `description` field.
--
-- Re sdr_eotf: the field is now CLuaConfigString (was int in hyprlang). The
-- transfer-function table in src/helpers/TransferFunction.cpp accepts both
-- numeric strings AND named values:
--   "0" / "default"      → TF_DEFAULT
--   "1" / "gamma22"      → TF_GAMMA22
--   "2" / "gamma22force" → TF_FORCED_GAMMA22
--   "3" / "srgb"         → TF_SRGB
--   "auto"               → TF_AUTO
-- Lua auto-coerces numbers to strings via lua_isstring/lua_tostring, so
-- `sdr_eotf = 2` works the same as `sdr_eotf = "2"`. The named form is
-- self-documenting; the user's existing int values are preserved below.
-- `cm = "hdredid"`/`"auto"` remain valid strings.

-- Laptops (eDP-1 etc. — these calls are no-ops on a host that doesn't have
-- the output, hyprland just ignores monitors it can't find)
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 })

hl.monitor({
    -- "desc:" prefix matches by EDID description — same convention as hyprlang.
    output   = "desc:Iiyama North America PL2770H 0x30393235",
    mode     = "1920x1080@144",
    position = "1920x0",
    scale    = 1,
})

hl.monitor({
    output   = "desc:BNQ BenQ LCD 89L03574019",
    mode     = "2560x1440@59.95",
    position = "3840x0",
    scale    = 1,
})

-- Workstation HDR (formerly `monitorv2`)
hl.monitor({
    output              = "DP-2",
    mode                = "2560x1440@360.00Hz",
    position            = "auto",
    scale               = 1,
    sdr_min_luminance   = 0,
    sdr_max_luminance   = 200,
    cm                  = "hdredid",
    supports_hdr        = 1,
    bitdepth            = 10,
    vrr                 = 1,
    sdr_eotf            = "gamma22force",  -- was 2 in hyprlang ("2" also works)
    supports_wide_color = 1,
    sdrbrightness       = 1.1,
    sdrsaturation       = 1.0,
})
hl.monitor({
    output              = "DP-3",
    mode                = "1920x1080@143.98100Hz",
    position            = "1920x0",
    scale               = 1,
    sdr_min_luminance   = 0,
    sdr_max_luminance   = 200,
    cm                  = "auto",
    supports_hdr        = 0,
    bitdepth            = 8,
    vrr                 = 1,
    sdr_eotf            = "gamma22",  -- was 1 in hyprlang ("1" also works)
    supports_wide_color = 0,
    sdrbrightness       = 1.1,
    sdrsaturation       = 1.0,
    transform           = 3,
})


-- ----------------------------------------------------------------------------
-- WORKSPACE RULES (replaces `workspace = [...]`)
-- ----------------------------------------------------------------------------
-- Old: `workspace = "r[1-4], monitor:eDP-1"` (comma-separated string)
-- New: typed table per rule. Confirmed fields: monitor, default, persistent,
-- gaps_in, gaps_out, float_gaps, border_size, no_border, no_rounding,
-- decorate, no_shadow, on_created_empty, default_name, layout, animation.
hl.workspace_rule({ workspace = "r[1-4]", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "r[5-9]", monitor = "DP-7"  })

-- Smart gaps / "no gaps when only" — when a workspace has a single tiled
-- window, drop gaps and rounding for that window. The pattern is two rules:
--   1. workspace_rule sets gaps_in/gaps_out=0 on workspaces matching `w[tv1]`
--      (built-in selector: "all visible, exactly 1 tiled window").
--   2. window_rule strips border/rounding on tiled windows on those WSes.
-- This is most visible on the laptops where gaps_out > 0 was eating real estate;
-- workstation already runs gaps_out=0 so this is mostly a no-op there.
hl.workspace_rule({ workspace = "w[tv1]", gaps_in = 0, gaps_out = 0 })
hl.window_rule({
    name        = "no-gaps-when-only",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})


-- ----------------------------------------------------------------------------
-- LAYER RULES
-- ----------------------------------------------------------------------------
-- Confirmed properties (from src/config/lua/bindings/LuaBindingsConfigRules.cpp):
-- no_anim, blur, blur_popups, ignore_alpha (0..1), dim_around, xray,
-- animation, order, above_lock (0..2), no_screen_share.
hl.layer_rule({
    name  = "noctalia-blur",
    match = { namespace = "^noctalia" },
    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.3,
    xray         = true,
})


-- ----------------------------------------------------------------------------
-- WINDOW RULES
-- ----------------------------------------------------------------------------
-- The hyprlang `windowrule = "PROP, match:KEY VAL, match:KEY VAL"` collapses
-- into one table per rule with `match = {...}` and the rule props as siblings.
-- "on"/"yes" → `true`, regex strings stay as Lua strings. Each rule needs a
-- unique `name` (hyprlang didn't require this).

hl.window_rule({
    name  = "idle-inhibit-fullscreen",
    match = { fullscreen = true },  -- was `match:fullscreen 1` in hyprlang; fullscreen is a bool match
    idle_inhibit = "fullscreen",
})

hl.window_rule({ name = "code-opacity", match = { class = "code"     }, opacity = 0.95 })
hl.window_rule({ name = "zen-opacity",  match = { class = "zen-beta" }, opacity = 0.90 })

-- ---- Gaming: Steam games -------------------------------------------------
-- Multiple properties on one rule, single match.
hl.window_rule({
    name  = "steam-games",
    match = { class = "^(steam_app)" },
    immediate  = true,
    fullscreen = true,
    no_blur    = true,
    no_shadow  = true,
    no_anim    = true,
})

-- ---- Gaming: Steam client ------------------------------------------------
hl.window_rule({ name = "steam-float",          match = { class = "^(steam)$" }, float = true })
hl.window_rule({ name = "steam-friends-float",  match = { class = "^(steam)$", title = "^(Friends)" },        float = true })
hl.window_rule({ name = "steam-settings-float", match = { class = "^(steam)$", title = "^(Steam Settings)" }, float = true })

-- ---- Gaming: Gamescope ---------------------------------------------------
hl.window_rule({
    name  = "gamescope",
    match = { class = "^(gamescope)" },
    immediate = true, fullscreen = true,
    no_blur = true, no_shadow = true, no_anim = true,
})

-- ---- Gaming: Launchers (float) -------------------------------------------
-- Loop over a list of class regexes. `ipairs` iterates {1, 2, 3, ...} keys
-- in order; the underscore is just a conventional name for "ignored variable".
local launcherClasses = {
    "^(lutris)",
    "^(com.usebottles.bottles)",
    "^(heroic)",
    "^(net.davidotek.pupgui2)",
}
for _, cls in ipairs(launcherClasses) do
    hl.window_rule({
        name  = "launcher-float-" .. cls,
        match = { class = cls },
        float = true,
    })
end

-- ---- Gaming: Emulators ---------------------------------------------------
local emulatorClasses = {
    "^(retroarch)",
    "^(Ryujinx|ryubing)",
    "^(azahar|citra)",
}
for _, cls in ipairs(emulatorClasses) do
    hl.window_rule({
        name  = "emulator-" .. cls,
        match = { class = cls },
        immediate = true, no_blur = true, no_shadow = true,
    })
end

-- ---- Gaming: Star Citizen ------------------------------------------------
hl.window_rule({ name = "rsi-float", match = { class = "^(rsi)" }, float = true })
hl.window_rule({
    name  = "star-citizen",
    match = { class = "^(star_citizen|starcitizen)" },
    immediate = true, no_blur = true, no_shadow = true, no_anim = true,
})

-- ---- Gaming: Wine/Proton fallback ----------------------------------------
hl.window_rule({
    name  = "wine-exe",
    match = { class = "\\.exe$" },  -- Lua strings: \\ is one backslash
    no_blur = true, no_shadow = true,
})


-- ----------------------------------------------------------------------------
-- KEYBINDINGS
-- ----------------------------------------------------------------------------
-- hl.bind(KEYSTROKE, ACTION, OPTIONS?)
--   KEYSTROKE: Tokens separated by `+`. EVERY modifier needs its own `+`
--              (the parser splits on `+` and rejects any token containing a
--              space). Examples:
--                  "SUPER + Q"             (one modifier + key)
--                  "SUPER + SHIFT + Q"     (two modifiers — both joined by +)
--                  "XF86AudioPlay"         (no modifier — bare keysym)
--                  "ALT + mouse:272"       (modifier + mouse button)
--                  "SUPER + code:11"       (modifier + raw keycode)
--              NOT "SUPER SHIFT + Q" — that errors with "did you forget a +?"
--              because "SUPER SHIFT" is parsed as one token.
--              Modifiers: SHIFT, CAPS, CTRL, ALT, MOD1..MOD5, SUPER/WIN/LOGO/META.
--   ACTION:    A dispatcher (e.g. hl.dsp.window.close()) or a Lua function.
--   OPTIONS:   Optional table. Booleans: repeating, locked, release,
--              non_consuming, auto_consuming, transparent, ignore_mods,
--              dont_inhibit, long_press, submap_universal, click, drag.
--              Plus: description / desc (string),
--                    device = { inclusive = true, list = {"foo","bar"} }.

-- ---- Window management ---------------------------------------------------
hl.bind(mod .. " + SHIFT + Q",   hl.dsp.window.close())
hl.bind(mod .. " + RETURN",      hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SHIFT + E",   hl.dsp.exec_cmd(noctalia .. " lockScreen lock"))
hl.bind(mod .. " + SHIFT + I",   hl.dsp.exit())
hl.bind(mod .. " + E",           hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + V",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",           hl.dsp.window.fullscreen())  -- toggle by default

-- ---- Launcher ------------------------------------------------------------
hl.bind(mod .. " + D",       hl.dsp.exec_cmd(noctalia .. " launcher toggle"))
hl.bind("ALT + SPACE",       hl.dsp.exec_cmd(noctalia .. " launcher toggle"))
hl.bind(mod .. " + W",       hl.dsp.exec_cmd(noctalia .. " launcher windows"))
hl.bind(mod .. " + C",       hl.dsp.exec_cmd(noctalia .. " launcher clipboard"))

-- ---- Desktop widgets -----------------------------------------------------
hl.bind(mod .. " + period",         hl.dsp.exec_cmd(noctalia .. " desktopWidgets edit"))
hl.bind(mod .. " + SHIFT + period", hl.dsp.exec_cmd(noctalia .. " desktopWidgets toggle"))

-- ---- Dwindle layout ------------------------------------------------------
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + O", hl.dsp.layout("togglesplit"))

-- ---- Workspace overview --------------------------------------------------
hl.bind(mod .. " + Tab", hl.dsp.exec_cmd(noctalia .. " plugin:workspace-overview toggle"))

-- ---- Window groups -------------------------------------------------------
-- The 0.55 API renamed these into hl.dsp.group.*:
--   togglegroup           → hl.dsp.group.toggle()
--   changegroupactive f   → hl.dsp.group.next()
--   changegroupactive b   → hl.dsp.group.prev()
hl.bind(mod .. " + G",                  hl.dsp.group.toggle())
hl.bind(mod .. " + ALT + Tab",          hl.dsp.group.next())
hl.bind(mod .. " + ALT + SHIFT + Tab",  hl.dsp.group.prev())

-- ---- App focus shortcuts (focus-or-launch) -------------------------------
-- A Lua-function bind: try to focus an existing window matching a selector;
-- if no such window exists, exec the launch command. This is something the
-- old hyprlang couldn't express directly — it would have needed a shell
-- script. Now it's a 4-line helper.
local function focusOrLaunch(selector, launchCmd)
    -- We pass a function (not a dispatcher action) to hl.bind. The function
    -- runs every time the bind fires.
    return function()
        if hl.get_window(selector) ~= nil then
            -- Window exists — fire the focus dispatcher imperatively.
            hl.dispatch(hl.dsp.focus({ window = selector }))
        else
            -- No window — launch it. (Hyprland's exec doesn't wait/return,
            -- so we don't try to focus the new window here; the next press
            -- will catch it.)
            hl.exec_cmd(launchCmd)
        end
    end
end
hl.bind(mod .. " + Z", focusOrLaunch("class:zen-beta", "zen-beta"),
        { description = "focus or launch Zen browser" })
hl.bind(mod .. " + S", focusOrLaunch("class:slack",    "slack"),
        { description = "focus or launch Slack" })

-- ---- Focus + move (arrows + hjkl) ----------------------------------------
-- A small table-driven loop — much tidier than the hyprlang repetition.
local focusKeys = {
    { key = "left",  dir = "left"  }, { key = "right", dir = "right" },
    { key = "up",    dir = "up"    }, { key = "down",  dir = "down"  },
    { key = "H",     dir = "left"  }, { key = "L",     dir = "right" },
    { key = "K",     dir = "up"    }, { key = "J",     dir = "down"  },
}
for _, b in ipairs(focusKeys) do
    hl.bind(mod .. " + "         .. b.key, hl.dsp.focus({ direction = b.dir }))
    -- group_aware = true: if focused window is in a group (mod+G), shift-move
    -- traverses group members instead of jumping past them. Pairs with the
    -- existing togglegroup / changegroupactive binds.
    hl.bind(mod .. " + SHIFT + " .. b.key,
            hl.dsp.window.move({ direction = b.dir, group_aware = true }))
end

-- ---- Screenshots ---------------------------------------------------------
-- Multi-line shell commands need careful quoting; Lua's `[[...]]` long-string
-- syntax avoids escape hell.
hl.bind(mod .. " + SHIFT + S",
        hl.dsp.exec_cmd([[bash -c 'grim -g "$(slurp)" - | tee ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png | wl-copy']]),
        { description = "screenshot (region) -> file + clipboard" })
hl.bind(mod .. " + SHIFT + P",
        hl.dsp.exec_cmd([[bash -c 'grim - | tee ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png | wl-copy']]),
        { description = "screenshot (full) -> file + clipboard" })

-- ---- Audio ---------------------------------------------------------------
-- Note: no leading comma like hyprlang's `, XF86...`. A bare keysym means
-- "no modifier required". `{ locked = true }` was the old `bindl`.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctalia .. " volume increase"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctalia .. " volume decrease"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctalia .. " volume muteOutput"))
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ---- Brightness ----------------------------------------------------------
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctalia .. " brightness increase"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctalia .. " brightness decrease"))

-- ---- Mouse binds (was `bindm`) -------------------------------------------
-- The "mouse:NNN" token in the keystring is what the parser uses to flag
-- the bind as mouse-driven; `{ mouse = true }` is the upstream example's
-- convention even though hlBind doesn't currently read the flag (kb.mouse
-- is a struct field never set from Lua in 0.55). Match the example pattern
-- for forward compatibility in case the handler starts honoring it.
hl.bind("ALT + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("ALT + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- no-arg = mouse drag-resize

-- ---- Workspace switching (was the `genList` loop in bindings.nix) --------
-- Lua's for loop is a near-perfect match for genList. AZERTY top row:
-- code:10..code:18 are the keys producing &"é"'(-è_ç" — workspaces 1..9.
for i = 0, 8 do
    local ws = i + 1
    hl.bind(mod .. " + code:1" .. i,           hl.dsp.focus({ workspace = ws }))
    hl.bind(mod .. " + SHIFT + code:1" .. i,   hl.dsp.window.move({ workspace = ws }))
end


-- ----------------------------------------------------------------------------
-- SUBMAPS  (was `extraConfig` raw text in bindings.nix:108)
-- ----------------------------------------------------------------------------
-- Confirmed API:
--   hl.define_submap("name", function() ... binds ... end)
--     -- binds inside the function are scoped to the submap.
--   hl.dsp.submap("name")  -- enter submap
--   hl.dsp.submap("reset") -- leave (any submap)
-- "Resize active" is the dispatcher hl.dsp.window.resize{x=DX, y=DY, relative=true}.

hl.define_submap("resize", function()
    -- Inside a submap, `repeating = true` is what the old `binde` was for.
    hl.bind("right", hl.dsp.window.resize({ x =  30, y =   0, relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -30, y =   0, relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x =   0, y = -30, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x =   0, y =  30, relative = true }), { repeating = true })
    hl.bind("L",     hl.dsp.window.resize({ x =  30, y =   0, relative = true }), { repeating = true })
    hl.bind("H",     hl.dsp.window.resize({ x = -30, y =   0, relative = true }), { repeating = true })
    hl.bind("K",     hl.dsp.window.resize({ x =   0, y = -30, relative = true }), { repeating = true })
    hl.bind("J",     hl.dsp.window.resize({ x =   0, y =  30, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)
hl.bind(mod .. " + R", hl.dsp.submap("resize"),
        { description = "enter resize submap (escape/return to exit)" })

hl.define_submap("gamemode", function()
    -- Exit on the same chord that entered.
    hl.bind(mod .. " + F9",            hl.dsp.submap("reset"))
    -- Volume directly via wpctl while in gamemode (bypasses noctalia).
    hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"))
    hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
    hl.bind("XF86AudioMute",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
    hl.bind("XF86AudioMicMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
    hl.bind("XF86AudioPlay",           hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext",           hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPrev",           hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
end)
hl.bind(mod .. " + F9", hl.dsp.submap("gamemode"),
        { description = "enter gamemode submap (override volume controls)" })


-- =============================================================================
-- REACTIVE AUTOMATION (capabilities the old hyprlang couldn't express)
-- =============================================================================
-- Everything below uses hl.on(<event>, <callback>) to react to compositor
-- events. There are 27 event names; see the upstream
-- src/config/lua/LuaEventHandler.cpp for the full list. The callback signature
-- depends on the event — for window.* you get a window object, for monitor.*
-- you get a monitor object, etc.


-- ----------------------------------------------------------------------------
-- AUTO-GAMEMODE
-- ----------------------------------------------------------------------------
-- Enter the `gamemode` submap automatically when a Steam / gamescope / Star
-- Citizen window goes fullscreen; exit when no game is fullscreened anymore.
-- Replaces the manual SUPER+F9 dance for the common case.

-- Lua "set" of game class regexes. Lookup is via string.match against w.class.
local gameClassPatterns = {
    "^steam_app",
    "^gamescope",
    "^star_citizen",
    "^starcitizen",
}

-- Helper: does a window match any game pattern?
local function isGameWindow(w)
    if not w or not w.class then return false end
    for _, pat in ipairs(gameClassPatterns) do
        if w.class:match(pat) then return true end
    end
    return false
end

-- Helper: is this window fullscreened? `w.fullscreen` is the integer
-- fullscreen-mode enum (0=none, 1=maximized, 2=fullscreen), NOT a boolean
-- (LuaWindow.cpp pushes m_fullscreenState.internal as an integer). In Lua
-- every number including 0 is truthy and `not 0` is false, so a bare
-- `if w.fullscreen` / `not w.fullscreen` test is always true / always false
-- and the gamemode exit logic never fires. Compare against 0 explicitly.
local function isFullscreen(w)
    return w and w.fullscreen ~= nil and w.fullscreen ~= 0
end

-- Helper: is at least one game window currently fullscreened anywhere?
-- Iterates all windows via the query API; cheap (compositor's window list is
-- in-memory, not an IPC call). `excludeAddr` skips a specific window by address
-- -- needed on the close path, where the dying window is still in the list AND
-- still fullscreen at window.close emit time (Window.cpp clears fullscreen only
-- a few lines after the emit), so it would otherwise count itself.
local function anyGameFullscreen(excludeAddr)
    for _, w in ipairs(hl.get_windows()) do
        if w.address ~= excludeAddr and isFullscreen(w) and isGameWindow(w) then
            return true
        end
    end
    return false
end

-- Helper: leave gamemode if we were in it and no game is fullscreen anymore.
-- Used by both window.fullscreen (un-fullscreen) and window.close (game crash/quit).
local function maybeExitGamemode(excludeAddr)
    if hl.get_current_submap() == "gamemode" and not anyGameFullscreen(excludeAddr) then
        hl.dispatch(hl.dsp.submap("reset"))
    end
end

hl.on("window.fullscreen", function(w)
    -- Event fires on BOTH enter and exit fullscreen. The event payload `w`
    -- already reflects the new state (verified at Compositor.cpp:2284 — emit
    -- happens after m_fullscreenState assignment).
    local inGamemode = (hl.get_current_submap() == "gamemode")

    if isFullscreen(w) and isGameWindow(w) and not inGamemode then
        -- Game went fullscreen and we're not already in gamemode → enter.
        hl.dispatch(hl.dsp.submap("gamemode"))
    elseif not isFullscreen(w) and isGameWindow(w) then
        -- Only the un-fullscreen of a GAME window can auto-exit gamemode.
        -- This protects the case where the user manually entered gamemode
        -- (no games involved) and then un-fullscreens an unrelated window.
        maybeExitGamemode()
    end
end)

-- window.fullscreen does NOT fire when a fullscreen window is destroyed
-- (verified: Compositor.cpp:884 emits window.destroy without a fullscreen
-- event). So if a game crashes or you close it while fullscreen, we'd be
-- stuck in gamemode. Hook window.close to cover that path.
hl.on("window.close", function(w)
    if isGameWindow(w) then
        -- Exclude the closing window: at window.close emit time it is still in
        -- the window list and still fullscreen, so it would count itself.
        maybeExitGamemode(w.address)
    end
end)


-- ----------------------------------------------------------------------------
-- LAPTOP DOCK WORKFLOW
-- ----------------------------------------------------------------------------
-- When the laptop is undocked (only eDP-1 present), workspaces 5-9 collapse
-- onto eDP-1. When an external monitor connects, move workspaces 5-9 there.
-- Gated by a startup detection: skip the whole hook on hosts without eDP-1
-- (workstation), since they always have multi-monitor.

-- One-time check at config eval. `hl.get_monitor("eDP-1")` is nil on the
-- workstation. We snapshot this rather than checking on every event.
local hasInternalLaptopDisplay = (hl.get_monitor("eDP-1") ~= nil)

-- Helper: target workspace migration.
-- The monitor argument is the new external display (post-add) or nil (pre-remove).
local function migrateLaptopWorkspaces(targetMonitorName)
    -- Workspaces 5..9 follow the external monitor; 1..4 stay on eDP-1.
    -- hl.dsp.workspace.move{} requires both `monitor` and `workspace` selectors.
    for ws = 5, 9 do
        hl.dispatch(hl.dsp.workspace.move({
            workspace = tostring(ws),
            monitor   = targetMonitorName,
        }))
    end
end

if hasInternalLaptopDisplay then
    hl.on("monitor.added", function(mon)
        -- Don't migrate if the "new" monitor is just eDP-1 (e.g., on resume).
        if mon.name == "eDP-1" then return end
        -- Defer briefly: the monitor needs a moment to be fully usable for
        -- workspace moves. 200ms is enough; tune if you see misses.
        hl.timer(function()
            migrateLaptopWorkspaces(mon.name)
        end, { timeout = 200, type = "oneshot" })
    end)

    hl.on("monitor.removed", function(mon)
        if mon.name == "eDP-1" then return end  -- shouldn't happen, but safe
        -- The external just left; pull workspaces 5-9 back to eDP-1.
        migrateLaptopWorkspaces("eDP-1")
    end)
end


-- =============================================================================
-- TRANSLATION FIDELITY NOTES
-- =============================================================================
--   * env: 1:1 mapping, plus an `if isNvidia` runtime branch (vs Nix-eval-time).
--   * exec-once: fan-out of hl.exec_cmd inside an "hyprland.start" handler.
--   * settings: hl.config{} calls are merged across the file.
--   * monitor + monitorv2: collapsed into hl.monitor() per output. EDID match
--     uses output = "desc:..."; sdr_eotf is now a string with both numeric
--     and named values supported (see TransferFunction.cpp comment above).
--   * windowrule "PROP, match:K V, match:K V": rule props alongside a single
--     `match = {...}` table. `name` is optional but enables update-by-name.
--   * Generated workspace binds: Lua's for loop replaces builtins.genList.
--   * extraConfig submaps: hl.define_submap("name", fn). Repeat keys via
--     `{ repeating = true }` opt instead of `binde`.
--
-- Open questions:
--   * `output = "desc:..."` follows the hyprlang convention and is recognized
--     in src/helpers/Monitor.cpp:1172 / WorkspaceRuleManager.cpp:61, but I
--     haven't end-to-end-tested the Lua path against a real EDID-matched
--     monitor. Sanity-check after deploy.
--
-- Independent of Lua migration:
--   * `render.cm_fs_passthrough` was REMOVED in 0.55. The current settings.nix
--     line 73 will silently error on the first 0.55 rebuild (regardless of
--     whether you migrate to Lua). Drop that key from settings.nix now.
--
-- What's NICER than hyprlang:
--   * Real loops/conditionals at file-eval time, no genList gymnastics.
--   * hl.dsp.focus({window = "class:..."}) instead of shelling out via bash.
--   * Typed properties on rules; no string parsing of "PROP, match:K V".
--   * Shared local strings (terminal, noctalia) instead of $vars.
--   * Submaps are declarative blocks via hl.define_submap, not stateful
--     `submap = name` sentinels in raw text.
--
-- What's WORSE / bookkeeping:
--   * Rules can have a `name`; passing the same name re-registers (updates)
--     the existing rule rather than duplicating. Optional, but useful for
--     identifying rules in logs / the eventual hyprctl introspection.
--   * No home-manager `wayland.windowManager.hyprland.settings` typing — if
--     we ship this, we lose the Nix-side schema and have to duplicate per host.
-- =============================================================================
