{ ... }:
{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        position = "top";

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];

        modules-center = [
          "hyprland/window"
        ];

        modules-right = [
          "tray"
          "cpu"
          "memory"
          "backlight"
          "pulseaudio#audio"
          # "network#wlo1",
          # "network#eno1",
          "battery"
          "clock"
        ];

        "hyprland/workspaces" = {
          onClick = "activate";
          format = "{icon}";
          formatIcons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            default = "1";
          };
        };

        "hyprland/submap" = {
          format = "{}";
          tooltip = false;
        };

        "hyprland/window" = {
          format = "<span font_desc='Iosevka Fixed 12'>{:.40}</span>";
          separateOutputs = false;
        };

        "tray" = {
          iconSize = 18;
          spacing = 10;
        };

        "cpu" = {
          interval = 1;
          format = " {usage}%";
          tooltip = false;
        };

        "memory" = {
          format = " {percentage}%";
          tooltip = true;
        };

        "backlight" = {
          format = "{percent}% {icon}";
          formatIcons = [ "" "" ];
        };

        "pulseaudio#audio" = {
          format = "{icon} {volume}%";
          formatBluetooth = "{icon} {volume}%";
          formatBluetoothMuted = "󰂯󰖁 {volume}%";
          formatMuted = " {volume}%";
          formatIcons = {
            headphone = "󰋋";
            handsFree = "󰋋";
            headset = "󰋋";
            phone = "";
            portable = "";
            car = "";
            default = [ "" ];
          };
          onClick = "pavucontrol";
          tooltip = true;
          tooltipFormat = "{icon} {desc}";
        };

        "network#wlo1" = {
          interval = 1;
          interface = "wlp1s0";
          formatIcons = [ "" "" "" "" "" ];
          formatWifi = "{icon}";
          formatDisconnected = "";
          onClick = "nm-connection-editor";
          tooltip = true;
          tooltipFormat = "{ifname}\n{ipaddr}/{cidr}\n{icon} {essid}\n{signalStrength}% {signaldBm} dBm {frequency} MHz\n{bandwidthDownBytes}\n{bandwidthUpBytes}";
        };

        "network#eno1" = {
          interval = 1;
          interface = "enxf4a80d052f4c";
          formatIcons = [ "" ];
          formatEthernet = "{icon}";
          formatDisconnected = "";
          onClick = "";
          tooltip = true;
          tooltipFormat = "{ifname}\n{ipaddr}/{cidr}\n{bandwidthDownBytes}\n{bandwidthUpBytes}";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          formatCharging = " {capacity}%";
          formatPlugged = " {capacity}%";
          formatIcons = [ "" "" "" "" "" "" "󰁹" ];
          onClick = "";
          tooltip = false;
        };

        "clock" = {
          interval = 1;
          format = "{: %A %d %B |  %I:%M:%S %p}";
          onClick = "";
          tooltip = false;
          tooltipFormat = "{:󰣆 %A, %B %d, %Y | %I:%M:%S %p}";
        };
      }
    ];

    style = ''
        @define-color white      #F2F2F2;
        @define-color black      #000203;
        @define-color text       #BECBCB;
        @define-color lightgray  #686868;
        @define-color darkgray   #353535;
        @define-color red        #F38BA8;

        @define-color black-transparent-1 rgba(0, 0, 0, 0.1);
        @define-color black-transparent-2 rgba(0, 0, 0, 0.2);
        @define-color black-transparent-3 rgba(0, 0, 0, 0.3);
        @define-color black-transparent-4 rgba(0, 0, 0, 0.4);
        @define-color black-transparent-5 rgba(0, 0, 0, 0.5);
        @define-color black-transparent-6 rgba(0, 0, 0, 0.6);
        @define-color black-transparent-7 rgba(0, 0, 0, 0.7);
        @define-color black-transparent-8 rgba(0, 0, 0, 0.8);
        @define-color black-transparent-9 rgba(0, 0, 0, 0.9);

        * {
          font-family: Iosevka, Material Design Icons Desktop;
          font-size: 14px;
        }

        window#waybar {
          background-color: transparent;
          color: @text;
          /* border-radius: 20px; */
          /*border: 1px solid @black;*/
        }

        window#waybar.empty {
            background-color: transparent;
        }

        tooltip {
          background: @black-transparent-9;
          border: 1px solid @darkgray;
          border-radius: 10px;
        }
        tooltip label {
          color: @text;
        }

        #workspaces {
          /* border: 1px solid #10171b; */
          /* border-radius: 20px; */
          margin-top: 0;
          margin-bottom: 0;
          /* margin-left: 1px; */
          margin-right: 5px;
        }

        #workspaces button {
          background: @black-transparent-9;
          color: @text;
          border: 1px solid @darkgray;
          padding: 1px 8px;
          margin-top: 5px;
          margin-bottom: 5px;
          margin-left: 1px;
          margin-right: 1px;
          border-radius: 20px;
          transition: all 0.3s ease;
        }

        #workspaces button:hover {
          box-shadow: inherit;
          text-shadow: inherit;
          background: @black-transparent-9;
          border: 1px solid @lightgray;
          color: @white;
          min-width: 30px;
          transition: all 0.3s ease;
        }

        #workspaces button.focused,
        #workspaces button.active {
          /* background-color: @darkgray; */
          border: 1px solid @lightgray;
          color: @white;
          min-width: 30px;
          transition: all 0.3s ease;
          animation: colored-gradient 10s ease infinite;
        }

        /* #workspaces button.focused:hover,
        #workspaces button.active:hover {
          background-color: @white;
          transition: all 1s ease;
        } */

        #workspaces button.urgent {
          background-color: @red;
          color: @black;
          transition: all 0.3s ease;
        }

        /* #workspaces button.hidden {} */

        #taskbar {
          border-radius: 8px;
          margin-top: 4px;
          margin-bottom: 4px;
          margin-left: 1px;
          margin-right: 1px;
        }

        #taskbar button {
          color: @text;
          padding: 1px 8px;
          margin-left: 1px;
          margin-right: 1px;
        }

        #taskbar button:hover {
          background: transparent;
          border: 1px solid @darkgray;
          border-radius: 8px;
          transition: all 0.3s ease;
          animation: colored-gradient 10s ease infinite;
        }

        /* #taskbar button.maximized {} */

        /* #taskbar button.minimized {} */

        #taskbar button.active {
          border: 1px solid @darkgray;
          border-radius: 8px;
          transition: all 0.3s ease;
          animation: colored-gradient 10s ease infinite;
        }

        /* #taskbar button.fullscreen {} */

        /* -------------------------------------------------------------------------------- */

        #custom-launcher,
        #window,
        #submap,
        #mode,
        /* #tray, */
        #cpu,
        #memory,
        #backlight,
        #pulseaudio.audio,
        #pulseaudio.microphone,
        #network,
        #bluetooth,
        #battery,
        #clock,
        #custom-powermenu {
          background: @black-transparent-9;
          color: @text;
          padding: 1px 8px;
          margin-top: 5px;
          margin-bottom: 5px;
          margin-left: 2px;
          margin-right: 2px;
          border: 1px solid @darkgray;
          border-radius: 20px;
          transition: all 0.3s ease;
        }

        #submap {
          border: 0;
        }

        /* -------------------------------------------------------------------------------- */

        /* #custom-launcher {
          background-color: @darkgray;
          color: @black;
        } */

        /* #custom-launcher:hover {
          color: @white;
        } */

        /* #custom-powermenu {
          background-color: @red;
          color: @black;
        }

        #custom-powermenu:hover {
          color: @white;
        } */

        /* -------------------------------------------------------------------------------- */

        /* If workspaces is the leftmost module, omit left margin */
        /* .modules-left > widget:first-child > #workspaces, */
        .modules-left > widget:first-child > #workspaces button,
        .modules-left > widget:first-child > #taskbar button,
        .modules-left > widget:first-child > #custom-launcher,
        .modules-left > widget:first-child > #window,
        .modules-left > widget:first-child > #tray,
        .modules-left > widget:first-child > #cpu,
        .modules-left > widget:first-child > #memory,
        .modules-left > widget:first-child > #backlight,
        .modules-left > widget:first-child > #pulseaudio.audio,
        .modules-left > widget:first-child > #pulseaudio.microphone,
        .modules-left > widget:first-child > #network,
        .modules-left > widget:first-child > #bluetooth,
        .modules-left > widget:first-child > #battery,
        .modules-left > widget:first-child > #clock,
        .modules-left > widget:first-child > #custom-powermenu {
          margin-left: 5px;
        }

        /* If workspaces is the rightmost module, omit right margin */
        /* .modules-right > widget:last-child > #workspaces, */
        /* .modules-right > widget:last-child > #workspaces, */
        .modules-right > widget:last-child > #workspaces button,
        .modules-right > widget:last-child > #taskbar button,
        .modules-right > widget:last-child > #custom-launcher,
        .modules-right > widget:last-child > #window,
        .modules-right > widget:last-child > #tray,
        .modules-right > widget:last-child > #cpu,
        .modules-right > widget:last-child > #memory,
        .modules-right > widget:last-child > #backlight,
        .modules-right > widget:last-child > #pulseaudio.audio,
        .modules-right > widget:last-child > #pulseaudio.microphone,
        .modules-right > widget:last-child > #network,
        .modules-right > widget:last-child > #bluetooth,
        .modules-right > widget:last-child > #battery,
        .modules-right > widget:last-child > #clock,
        .modules-right > widget:last-child > #custom-powermenu {
          margin-right: 5px;
        }

        /* -------------------------------------------------------------------------------- */

        #tray {
          background-color: transparent;
          padding: 1px 8px;
        }
        #tray > .passive {
          -gtk-icon-effect: dim;
        }
        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: @red;
        }
    '';
  };

}
