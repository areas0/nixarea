{ ... }:
{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        position = "top";

        modules-left =  [
              "custom/arch"
              "hyprland/workspaces"
          ];
        modules-center = [
            "hyprland/window"
        ];
        modules-right = [
            "idle_inhibitor"
            "pulseaudio"
            "network"
            "cpu"
            "memory"
            # "temperature"
            "hyprland/language"
            "battery"
            # "battery#bat2"
            "clock"
        ];

        hyprland = {
          workspaces = {
            disable-scroll = true;
            all-outputs = true;
            warp-on-scroll = false;
            format = "{name}";
            format-icons = {
              urgent = "";
              active = "";
              default = "";
            };
          };
          language = {
            format = "  {}";
            format-en = "EN";
            format-ru = "RU";
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-bluetooth = "{icon} {volume}%  {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            "hands-free" = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "", "", "" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "   {essid} ({signalStrength}%)";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          on-click = "sh ~/scripts/rofi-wifi-menu/rofi-wifi-menu.sh";
        };

        cpu = {
          format = "  {usage}%";
          tooltip = true;
        };

        memory = {
          format = "  {}%";
          tooltip = true;
        };

        temperature = {
          interval = 10;
          hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input";
          critical-threshold = 100;
          format-critical = " {temperatureC}";
          format = " {temperatureC}°C";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-full = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-alt = "{time}  {icon}";
          format-icons = [ "", "", "", "", "" ];
        };

        "battery#bat2" = {
          bat = "BAT2";
        };

        clock = {
          format = "{:%H:%M | %e %B} ";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
      }
    ];

    style = ''
              * {
                  /* `otf-font-awesome` and SpaceMono Nerd Font are required to be installed for icons */
                  font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
                  font-size: 15px;
                  transition: background-color .3s ease-out;
              }

              window#waybar {
                  background: rgba(26, 27, 38, 0.75);
                  color: #c0caf5;
                  font-family: 
                      SpaceMono Nerd Font,
                      feather;
                  transition: background-color .5s;
              }

              .modules-left,
              .modules-center,
              .modules-right
              {
                  background: rgba(0, 0, 8, .7);
                  margin: 5px 10px;
                  padding: 0 5px;
                  border-radius: 15px;
              }
              .modules-left {
                  padding: 0;
              }
              .modules-center {
                  padding: 0 10px;
              }

              #clock,
              #battery,
              #cpu,
              #memory,
              #disk,
              #temperature,
              #backlight,
              #network,
              #pulseaudio,
              #wireplumber,
              #custom-media,
              #tray,
              #mode,
              #idle_inhibitor,
              #scratchpad,
              #power-profiles-daemon,
              #language,
              #mpd {
                  padding: 0 10px;
                  border-radius: 15px;
              }

              #clock:hover,
              #battery:hover,
              #cpu:hover,
              #memory:hover,
              #disk:hover,
              #temperature:hover,
              #backlight:hover,
              #network:hover,
              #pulseaudio:hover,
              #wireplumber:hover,
              #custom-media:hover,
              #tray:hover,
              #mode:hover,
              #idle_inhibitor:hover,
              #scratchpad:hover,
              #power-profiles-daemon:hover,
              #language:hover,
              #mpd:hover {
                  background: rgba(26, 27, 38, 0.9);
              }


              #workspaces button {
                background: transparent;
                font-family:
                  SpaceMono Nerd Font,
                  feather;
                font-weight: 900;
                font-size: 13pt;
                color: #c0caf5;
                border:none;
                border-radius: 15px;
              }

              #workspaces button.active {
                  background: #13131d; 
              }

              #workspaces button:hover {
                background: #11111b;
                color: #cdd6f4;
                box-shadow: none;
              }

    '';
  };

}
