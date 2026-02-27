{ walker, ... }:
{
  imports = [ walker.homeManagerModules.default ];

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      close_when_open = true;
      selection_wrap = true;
      force_keyboard_focus = true;
      theme = "custom";

      keybinds = {
        close = [ "Escape" ];
        next = [
          "Down"
          "ctrl j"
        ];
        previous = [
          "Up"
          "ctrl k"
        ];
        toggle_exact = [ "ctrl e" ];
        resume_last_query = [ "ctrl r" ];
        quick_activate = [
          "F1"
          "F2"
          "F3"
          "F4"
        ];
      };

      providers = {
        default = [
          "desktopapplications"
          "calc"
          "runner"
          "websearch"
          "clipboard"
          "windows"
        ];
        empty = [
          "desktopapplications"
          "windows"
        ];
        max_results = 50;
        sets.windows = {
          default = [ "windows" ];
          empty = [ "windows" ];
        };
        sets.clipboard = {
          default = [ "clipboard" ];
          empty = [ "clipboard" ];
        };
        prefixes = [
          {
            prefix = ";";
            provider = "providerlist";
          }
          {
            prefix = ">";
            provider = "runner";
          }
          {
            prefix = "/";
            provider = "files";
          }
          {
            prefix = "=";
            provider = "calc";
          }
          {
            prefix = ":";
            provider = "clipboard";
          }
          {
            prefix = "$";
            provider = "windows";
          }
          {
            prefix = "@";
            provider = "websearch";
          }
        ];
      };
    };

    themes.custom = {
      style = ''
        @define-color window_bg_color #1f1f28;
        @define-color accent_bg_color #54546d;
        @define-color theme_fg_color #f2ecbc;
        @define-color error_bg_color #C34043;
        @define-color error_fg_color #DCD7BA;

        * {
          all: unset;
        }

        popover {
          background: lighter(@window_bg_color);
          border: 1px solid darker(@accent_bg_color);
          border-radius: 18px;
          padding: 10px;
        }

        .normal-icons {
          -gtk-icon-size: 16px;
        }

        .large-icons {
          -gtk-icon-size: 32px;
        }

        scrollbar {
          opacity: 0;
        }

        .box-wrapper {
          box-shadow:
            0 19px 38px rgba(0, 0, 0, 0.3),
            0 15px 12px rgba(0, 0, 0, 0.22);
          background: alpha(@window_bg_color, 0.85);
          padding: 20px;
          border-radius: 20px;
          border: 1px solid darker(@accent_bg_color);
        }

        .preview-box,
        .elephant-hint,
        .placeholder {
          color: @theme_fg_color;
        }

        .search-container {
          border-radius: 10px;
        }

        .input placeholder {
          opacity: 0.5;
        }

        .input selection {
          background: lighter(lighter(lighter(@window_bg_color)));
        }

        .input {
          caret-color: @theme_fg_color;
          background: lighter(@window_bg_color);
          padding: 10px;
          color: @theme_fg_color;
        }

        .list {
          color: @theme_fg_color;
        }

        .item-box {
          border-radius: 10px;
          padding: 10px;
        }

        .item-quick-activation {
          background: alpha(@accent_bg_color, 0.25);
          border-radius: 5px;
          padding: 10px;
        }

        child:selected .item-box,
        row:selected .item-box {
          background: alpha(@accent_bg_color, 0.25);
        }

        .item-subtext {
          font-size: 12px;
          opacity: 0.5;
        }

        .providerlist .item-subtext {
          font-size: unset;
          opacity: 0.75;
        }

        .item-image-text {
          font-size: 28px;
        }

        .preview {
          border: 1px solid alpha(@accent_bg_color, 0.25);
          border-radius: 10px;
          color: @theme_fg_color;
        }

        .calc .item-text {
          font-size: 24px;
        }

        .symbols .item-image {
          font-size: 24px;
        }

        .todo.done .item-text-box {
          opacity: 0.25;
        }

        .todo.urgent {
          font-size: 24px;
        }

        .todo.active {
          font-weight: bold;
        }

        .bluetooth.disconnected {
          opacity: 0.5;
        }

        .preview .large-icons {
          -gtk-icon-size: 64px;
        }

        .keybinds {
          padding-top: 10px;
          border-top: 1px solid lighter(@window_bg_color);
          font-size: 12px;
          color: @theme_fg_color;
        }

        .keybind-button {
          opacity: 0.5;
        }

        .keybind-button:hover {
          opacity: 0.75;
        }

        .keybind-bind {
          text-transform: lowercase;
          opacity: 0.35;
        }

        .keybind-label {
          padding: 2px 4px;
          border-radius: 4px;
          border: 1px solid @theme_fg_color;
        }

        .error {
          padding: 10px;
          background: @error_bg_color;
          color: @error_fg_color;
        }

        :not(.calc).current {
          font-style: italic;
        }

        .preview-content.archlinuxpkgs,
        .preview-content.dnfpackages {
          font-family: monospace;
        }
      '';

      layouts.layout = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <interface>
          <requires lib="gtk" version="4.0"></requires>
          <object class="GtkWindow" id="Window">
            <style>
              <class name="window"></class>
            </style>
            <property name="resizable">true</property>
            <property name="title">Walker</property>
            <child>
              <object class="GtkBox" id="BoxWrapper">
                <style>
                  <class name="box-wrapper"></class>
                </style>
                <property name="overflow">hidden</property>
                <property name="orientation">horizontal</property>
                <property name="valign">center</property>
                <property name="halign">center</property>
                <property name="width-request">800</property>
                <property name="height-request">570</property>
                <child>
                  <object class="GtkBox" id="Box">
                    <style>
                      <class name="box"></class>
                    </style>
                    <property name="orientation">vertical</property>
                    <property name="hexpand-set">true</property>
                    <property name="hexpand">true</property>
                    <property name="spacing">10</property>
                    <child>
                      <object class="GtkBox" id="SearchContainer">
                        <style>
                          <class name="search-container"></class>
                        </style>
                        <property name="overflow">hidden</property>
                        <property name="orientation">horizontal</property>
                        <property name="halign">fill</property>
                        <property name="hexpand-set">true</property>
                        <property name="hexpand">true</property>
                        <child>
                          <object class="GtkEntry" id="Input">
                            <style>
                              <class name="input"></class>
                            </style>
                            <property name="halign">fill</property>
                            <property name="hexpand-set">true</property>
                            <property name="hexpand">true</property>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="ContentContainer">
                        <style>
                          <class name="content-container"></class>
                        </style>
                        <property name="orientation">horizontal</property>
                        <property name="spacing">10</property>
                        <child>
                          <object class="GtkLabel" id="ElephantHint">
                            <style>
                              <class name="elephant-hint"></class>
                            </style>
                            <property name="label">Waiting for elephant...</property>
                            <property name="hexpand">true</property>
                            <property name="vexpand">true</property>
                            <property name="visible">false</property>
                            <property name="valign">0.5</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkLabel" id="Placeholder">
                            <style>
                              <class name="placeholder"></class>
                            </style>
                            <property name="label">No Results</property>
                            <property name="hexpand">true</property>
                            <property name="vexpand">true</property>
                            <property name="valign">0.5</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkScrolledWindow" id="Scroll">
                            <style>
                              <class name="scroll"></class>
                            </style>
                            <property name="can_focus">false</property>
                            <property name="overlay-scrolling">true</property>
                            <property name="hexpand">true</property>
                            <property name="vexpand">true</property>
                            <property name="max-content-width">700</property>
                            <property name="min-content-width">700</property>
                            <property name="max-content-height">400</property>
                            <property name="propagate-natural-height">true</property>
                            <property name="propagate-natural-width">true</property>
                            <property name="hscrollbar-policy">automatic</property>
                            <property name="vscrollbar-policy">automatic</property>
                            <child>
                              <object class="GtkGridView" id="List">
                                <style>
                                  <class name="list"></class>
                                </style>
                                <property name="max_columns">1</property>
                                <property name="min_columns">1</property>
                                <property name="can_focus">false</property>
                              </object>
                            </child>
                          </object>
                        </child>
                        <child>
                          <object class="GtkBox" id="Preview">
                            <style>
                              <class name="preview"></class>
                            </style>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkBox" id="Keybinds">
                        <property name="hexpand">true</property>
                        <property name="margin-top">10</property>
                        <style>
                          <class name="keybinds"></class>
                        </style>
                        <child>
                          <object class="GtkBox" id="GlobalKeybinds">
                            <property name="spacing">10</property>
                            <style>
                              <class name="global-keybinds"></class>
                            </style>
                          </object>
                        </child>
                        <child>
                          <object class="GtkBox" id="ItemKeybinds">
                            <property name="hexpand">true</property>
                            <property name="halign">end</property>
                            <property name="spacing">10</property>
                            <style>
                              <class name="item-keybinds"></class>
                            </style>
                          </object>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkLabel" id="Error">
                        <style>
                          <class name="error"></class>
                        </style>
                        <property name="xalign">0</property>
                        <property name="visible">false</property>
                      </object>
                    </child>
                  </object>
                </child>
              </object>
            </child>
          </object>
        </interface>
      '';
    };
  };
}
