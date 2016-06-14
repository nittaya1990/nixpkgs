# python ./result/bin/Xspice --config ./spiceqxl.xorg.conf.example --disable-ticketing -xkbdir $PWD/xkeyboard_config/etc/X11/xkb :1.0
{ config, lib, pkgs, pkgs_i686, ... }:

with lib;

let
  # Abbreviations.
  cfg = config.services.xspice;
  dmcfg = config.services.xserver.displayManager;
  e = pkgs.enlightenment;
  xorg = pkgs.xorg;
  xspice = pkgs.xspice;
  xspiceArgs =
    [ "-terminate"
      "-config ${configFile}"
      "-xkbdir" "${cfg.xkbDir}"
    ] ++ optional (cfg.display != null) ":${toString cfg.display}"
      ++ optional (cfg.tty     != null) "vt${toString cfg.tty}"
      ++ optional (cfg.dpi     != null) "-dpi ${toString cfg.dpi}"
      ++ optionals (cfg.display != null) [ "-logfile" "/tmp/xspice.${toString cfg.display}.log" ]
      ++ optional (!cfg.enableTCP) "-nolisten tcp";
  GST_PLUGIN_PATH = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-libav ];

  fontconfig = config.fonts.fontconfig;
  xresourcesXft = pkgs.writeText "Xresources-Xft" ''
    ${optionalString (fontconfig.dpi != 0) ''Xft.dpi: ${toString fontconfig.dpi}''}
    Xft.antialias: ${if fontconfig.antialias then "1" else "0"}
    Xft.rgba: ${fontconfig.subpixel.rgba}
    Xft.lcdfilter: lcd${fontconfig.subpixel.lcdfilter}
    Xft.hinting: ${if fontconfig.hinting.enable then "1" else "0"}
    Xft.autohint: ${if fontconfig.hinting.autohint then "1" else "0"}
    Xft.hintstyle: hint${fontconfig.hinting.style}
  '';

  slimConfig = pkgs.writeText "slim.cfg"
    ''
      xauth_path ${dmcfg.xauthBin}
      default_xserver ${xorg.xorgserver.out}/bin/Xorg
      xserver_arguments ${concatStringsSep " " xspiceArgs}
      login_cmd exec ${pkgs.stdenv.shell} ${sessionLauncher}
      default_user coconnor
      focus_password yes
    '';

  slimThemesDir = "${pkgs.slim}/share/slim/themes";

  enlightenment = {
    systemPackages = [
      e.efl e.evas e.emotion e.elementary e.enlightenment
      e.terminology e.econnman
      pkgs.xorg.xauth # used by kdesu
      pkgs.gtk # To get GTK+'s themes.
      pkgs.tango-icon-theme
      pkgs.shared_mime_info
      pkgs.gnome.gnomeicontheme
      pkgs.xorg.xcursorthemes
    ];

    pathsToLink = [ "/etc/enlightenment" "/etc/xdg" "/share/enlightenment" "/share/elementary" "/share/applications" "/share/locale" "/share/icons" "/share/themes" "/share/mime" "/share/desktop-directories" ];

    start = ''
      # Set GTK_DATA_PREFIX so that GTK+ can find the themes
      export GTK_DATA_PREFIX=${config.system.path}
      # find theme engines
      export GTK_PATH=${config.system.path}/lib/gtk-3.0:${config.system.path}/lib/gtk-2.0
      export XDG_MENU_PREFIX=enlightenment

      export GST_PLUGIN_PATH="${GST_PLUGIN_PATH}"

      # make available for D-BUS user services
      #export XDG_DATA_DIRS=$XDG_DATA_DIRS''${XDG_DATA_DIRS:+:}:${config.system.path}/share:${e.efl}/share

      # Update user dirs as described in http://freedesktop.org/wiki/Software/xdg-user-dirs/
      ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update

      exec ${e.enlightenment}/bin/enlightenment_start
    '';

  };

  sessionLauncher = pkgs.writeScript "xspiceSessionLauncher"
    ''
      #! ${pkgs.bash}/bin/bash

      . /etc/profile
      cd "$HOME"

      # The first argument of this script is the session type.
      sessionType="$1"
      if [ "$sessionType" = default ]; then sessionType=""; fi

      exec > ~/.xsession-errors 2>&1

      if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
        exec ${pkgs.dbus.dbus-launch} --exit-with-session "$0" "$sessionType"
      fi

      # Handle being called by kdm.
      if test "''${1:0:1}" = /; then eval exec "$1"; fi

      # Start PulseAudio if enabled.
      ${optionalString (config.hardware.pulseaudio.enable) ''
        ${optionalString (!config.hardware.pulseaudio.systemWide)
          "${config.hardware.pulseaudio.package.out}/bin/pulseaudio --start"
        }

        # Publish access credentials in the root window.
        ${config.hardware.pulseaudio.package.out}/bin/pactl load-module module-x11-publish "display=$DISPLAY"
      ''}

      # Tell systemd about our $DISPLAY. This is needed by the
      # ssh-agent unit.
      ${config.systemd.package}/bin/systemctl --user import-environment DISPLAY

      # Load X defaults.
      ${xorg.xrdb}/bin/xrdb -merge ${xresourcesXft}
      if test -e ~/.Xresources; then
          ${xorg.xrdb}/bin/xrdb -merge ~/.Xresources
      elif test -e ~/.Xdefaults; then
          ${xorg.xrdb}/bin/xrdb -merge ~/.Xdefaults
      fi

      # Speed up application start by 50-150ms according to
      # http://kdemonkey.blogspot.nl/2008/04/magic-trick.html
      rm -rf $HOME/.compose-cache
      mkdir $HOME/.compose-cache

      # Work around KDE errors when a user first logs in and
      # .local/share doesn't exist yet.
      mkdir -p $HOME/.local/share

      # Allow the user to execute commands at the beginning of the X session.
      if test -f ~/.xprofile; then
          source ~/.xprofile
      fi

      # Allow the user to setup a custom session type.
      if test -x ~/.xsession; then
          exec ~/.xsession
      else
          if test "$sessionType" = "custom"; then
              sessionType="" # fall-thru if there is no ~/.xsession
          fi
      fi

      ${enlightenment.start}

      ${pkgs.glib}/bin/gdbus call --session \
        --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.UpdateActivationEnvironment \
        "{$(env | ${pkgs.gnused}/bin/sed "s/'/\\\\'/g; s/\([^=]*\)=\(.*\)/'\1':'\2'/" \
                | ${pkgs.coreutils}/bin/paste -sd,)}"

      test -n "$waitPID" && wait "$waitPID"
      exit 0
    '';
  fontsForXServer =
    config.fonts.fonts ++
    # We don't want these fonts in fonts.conf, because then modern,
    # fontconfig-based applications will get horrible bitmapped
    # Helvetica fonts.  It's better to get a substitution (like Nimbus
    # Sans) than that horror.  But we do need the Adobe fonts for some
    # old non-fontconfig applications.  (Possibly this could be done
    # better using a fontconfig rule.)
    [ pkgs.xorg.fontadobe100dpi
      pkgs.xorg.fontadobe75dpi
    ];


  configFile = pkgs.stdenv.mkDerivation {
    name = "xspice-5900.conf";

    xfs = optionalString (cfg.useXFS != false)
      ''FontPath "${toString cfg.useXFS}"'';

    inherit (cfg) config;

    buildCommand =
      ''
        echo 'Section "Files"' >> $out
        echo $xfs >> $out

        for i in ${toString fontsForXServer}; do
          if test "''${i:0:''${#NIX_STORE}}" == "$NIX_STORE"; then
            for j in $(find $i -name fonts.dir); do
              echo "  FontPath \"$(dirname $j)\"" >> $out
            done
          fi
        done

        for i in $(find ${toString cfg.modules} -type d); do
          if test $(echo $i/*.so* | wc -w) -ne 0; then
            echo "  ModulePath \"$i\"" >> $out
          fi
        done

        echo 'EndSection' >> $out

        echo "$config" >> $out
      ''; # */
  };

in

{

  imports =
    [ ./display-managers/default.nix
      ./window-managers/default.nix
      ./desktop-managers/default.nix
    ];


  ###### interface

  options = {

    services.xspice = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the XSpice server. This is a X server accessible over the Spice
          protocol.
        '';
      };

      enableTCP = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to allow the XSpice server to accept TCP connections.
        '';
      };

      modules = mkOption {
        type = types.listOf types.path;
        default = [];
        example = literalExample "[ pkgs.xf86_input_wacom ]";
        description = "Packages to be added to the module search path of the X server.";
      };

      resolutions = mkOption {
        type = types.listOf types.attrs;
        default = [];
        example = [ { x = 1600; y = 1200; } { x = 1024; y = 786; } ];
        description = ''
          The screen resolutions for the X server.  The first element
          is the default resolution.  If this list is empty, the X
          server will automatically configure the resolution.
        '';
      };

      dpi = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "DPI resolution to use for X server.";
      };

      startDbusSession = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to start a new DBus session when you log in with dbus-launch.
        '';
      };

      updateDbusEnvironment = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to update the DBus activation environment after launching the
          desktop manager.
        '';
      };

      layout = mkOption {
        type = types.str;
        default = "us";
        description = ''
          Keyboard layout.
        '';
      };

      xkbModel = mkOption {
        type = types.str;
        default = "pc104";
        example = "presario";
        description = ''
          Keyboard model.
        '';
      };

      xkbOptions = mkOption {
        type = types.str;
        default = "terminate:ctrl_alt_bksp";
        example = "grp:caps_toggle, grp_led:scroll";
        description = ''
          X keyboard options; layout switching goes here.
        '';
      };

      xkbVariant = mkOption {
        type = types.str;
        default = "";
        example = "colemak";
        description = ''
          X keyboard variant.
        '';
      };

      xkbDir = mkOption {
        type = types.path;
        description = ''
          Path used for -xkbdir xserver parameter.
        '';
      };

      config = mkOption {
        type = types.lines;
        description = ''
          The contents of the configuration file of the X server
          (<filename>xspice-5900.conf</filename>).
        '';
      };

      serverFlagsSection = mkOption {
        default = "";
        example =
          ''
          Option "BlankTime" "0"
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
          '';
        description = "Contents of the ServerFlags section of the X server configuration file.";
      };

      moduleSection = mkOption {
        type = types.lines;
        default = "";
        example =
          ''
            SubSection "extmod"
            EndSubsection
          '';
        description = "Contents of the Module section of the X server configuration file.";
      };

      serverLayoutSection = mkOption {
        type = types.lines;
        default = "";
        example =
          ''
            Option "AIGLX" "true"
          '';
        description = "Contents of the ServerLayout section of the X server configuration file.";
      };

      extraDisplaySettings = mkOption {
        type = types.lines;
        default = "";
        example = "Virtual 2048 2048";
        description = "Lines to be added to every Display subsection of the Screen section.";
      };

      defaultDepth = mkOption {
        type = types.int;
        default = 0;
        example = 8;
        description = "Default colour depth.";
      };

      useXFS = mkOption {
        # FIXME: what's the type of this option?
        default = false;
        example = "unix/:7100";
        description = "Determines how to connect to the X Font Server.";
      };

      tty = mkOption {
        type = types.nullOr types.int;
        default = 7;
        description = "Virtual console for the X server.";
      };

      display = mkOption {
        type = types.nullOr types.int;
        default = 0;
        description = "Display number for the X server.";
      };

      enableCtrlAltBackspace = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the DontZap option, which binds Ctrl+Alt+Backspace
          to forcefully kill X. This can lead to data loss and is disabled
          by default.
        '';
      };
    };

  };



  ###### implementation

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 5900 ];

    assertions =
      [ { assertion = config.security.polkit.enable;
          message = "X11 requires Polkit to be enabled (‘security.polkit.enable = true’).";
        }
      ];

    environment.systemPackages =
      [ xorg.xorgserver.out
        xorg.xrandr
        xorg.xrdb
        xorg.setxkbmap
        xorg.iceauth # required for KDE applications (it's called by dcopserver)
        xorg.xlsclients
        xorg.xset
        xorg.xsetroot
        xorg.xinput
        xorg.xprop
        xorg.xauth
        pkgs.xterm
        pkgs.xdg_utils
        pkgs.slim
      ] ++ enlightenment.systemPackages;

    environment.pathsToLink =
      [ "/etc/xdg" "/share/xdg" "/share/applications" "/share/icons" "/share/pixmaps" ]
      ++ enlightenment.pathsToLink;

    systemd.services.xspice-5900 =
      { description = "XSpice Server for port 5900";

        after = [ "systemd-udev-settle.service" "local-fs.target" "acpid.service" "systemd-logind.service" ];
        wantedBy = [ "multi-user.target" ];

        restartIfChanged = false;

        environment =
          {
            XKB_BINDIR = "${xorg.xkbcomp}/bin"; # Needed for the Xkb extension.
            XORG_DRI_DRIVER_PATH = "/run/opengl-driver/lib/dri"; # !!! Depends on the driver selected at runtime.
            LD_LIBRARY_PATH = concatStringsSep ":" [ "${xorg.libX11.out}/lib" "${xorg.libXext.out}/lib" "${xspice.out}/lib" ];
            SLIM_CFGFILE = slimConfig;
            SLIM_THEMESDIR = slimThemesDir;
          };

        preStart =
          ''
            rm -f /var/log/xspice-slim-5900.log
            rm -f /tmp/.X${toString cfg.display}-lock
          '';

        script = "exec ${pkgs.slim}/bin/slim";

        serviceConfig = {
          Restart = "always";
          RestartSec = "200ms";
        };
      };

    security.pam.services.slim = { allowNullPassword = true; startSession = true; };

    # Allow slimlock to work.
    security.pam.services.slimlock = {};

    services.xspice.modules =
      [ xorg.xorgserver.out
        xorg.xf86inputevdev
        xspice
      ];

    services.xspice.xkbDir = mkDefault "${pkgs.xkeyboard_config}/etc/X11/xkb";

    services.xspice.config =
      ''
        Section "ServerFlags"
          Option "AutoAddDevices" "False"
          Option "AllowMouseOpenFail" "on"
          Option "DontZap" "${if cfg.enableCtrlAltBackspace then "off" else "on"}"
          ${cfg.serverFlagsSection}
        EndSection

        Section "Module"
          ${cfg.moduleSection}
        EndSection

        Section "InputClass"
          Identifier "Keyboard catchall"
          MatchIsKeyboard "on"
          Option "XkbRules" "base"
          Option "XkbModel" "${cfg.xkbModel}"
          Option "XkbLayout" "${cfg.layout}"
          Option "XkbOptions" "${cfg.xkbOptions}"
          Option "XkbVariant" "${cfg.xkbVariant}"
        EndSection

        Section "ServerLayout"
          Identifier "Layout[all]"
          ${cfg.serverLayoutSection}
          Screen "XSPICE Screen"
          InputDevice "XSPICE KEYBOARD"
          InputDevice "XSPICE POINTER"
        EndSection

        Section "Device"
            Identifier "XSPICE"
            Driver "spiceqxl"

            # Enable regular port. Either this or SpiceTlsPort, or one of XSPICE_PORT or
            # XSPICE_TLS_PORT environment variables must be specified
            # Defaults to 5900.
            Option "SpicePort" "5900"

            # Enable a TLS (encrypted) port. Either this or SpicePort must be specified,
            # either here or via environment varialbes or via xspice --port or --tls-port
            #Option "SpiceTlsPort" "5901"

            # Listen to a specific interface. Default is to listen to all (0.0.0.0)
            #Option "SpiceAddr" ""

            # Enable usage of SASL supported by spice-gtk client. Not required,
            # defaults to false.
            #Option "SpiceSasl" "True"

            # Do not request any password from client
            Option "SpiceDisableTicketing" "1"

            # Set directory where cacert, server key and server cert are searched
            # using the same predefined names qemu uses:
            #   cacert.pem, server-key.pem, server-cert.pem
            #Option "SpiceX509Dir" ""

            # Set password client will be required to produce.
            #Option "SpicePassword" ""

            # Set spice server key file.
            #Option "SpiceX509KeyFile" ""

            # Set cert file location.
            #Option "SpiceX509CertFile" ""

            # Set key file password.
            #Option "SpiceX509KeyPassword" ""

            # Set tls ciphers used.
            #Option "SpiceTlsCiphers" ""

            # Set cacert file.
            #Option "SpiceCacertFile" ""

            # Set dh file used.
            #Option "SpiceDhFile" ""

            # Set streaming video method. Options are filter, off, all
            # defaults to filter.
            #Option "SpiceStreamingVideo" ""

            # Set zlib glz wan compression. Options are auto, never, always.
            # defaults to auto.
            #Option "SpiceZlibGlzWanCompression" ""

            # Set jpeg wan compression. Options are auto, never, always
            # defaults to auto.
            #Option "SpiceJpegWanCompression" ""

            # Set image compression. Options are off,auto_glz,auto_lz,quic,glz,lz.
            # defaults to auto_glz.
            #Option "SpiceImageCompression" ""

            # Set to true to only listen on ipv4 interfaces.
            # defaults to false.
            #Option "SpiceIPV4Only" ""

            # Set to true to only listen on ipv6 interfaces.
            # defaults to false.
            #Option "SpiceIPV6Only" ""

            # If non zero, the driver will render all operations to the frame buffer,
            #  and keep track of a changed rectangle list.  The changed rectangles
            #  will be transmitted at the rate requested (e.g. 10 Frames Per Second)
            # This can dramatically reduce network bandwidth for some use cases.
            Option "SpiceDeferredFPS" "10"

            # If set, the Spice Server will exit when the first client disconnects
            #Option "SpiceExitOnDisconnect" "1"

            # Enable caching of images directly written with uxa->put_image
            # defaults to True
            Option "EnableImageCache" "True"

            # Enable caching of images created by uxa->prepare_access
            # defaults to True
            Option "EnableFallbackCache" "True"

            # Enable the use of off screen srufaces
            # defaults to True
            Option "EnableSurfaces" "True"

            # The number of heads to allocate by default
            # defaults to 4
            Option "NumHeads" "1"

            #--------------------------------------------------------------
            # Buffer Size notes:
            #  The following buffer sizes are used for Xspice only
            #  If you are using the DFPS mode, surface ram is not used,
            #  and you can set it to 1.
            #  Otherwise, the surface buffer should be at least as large
            #   as the frame buffer, and probably a multiple like 8.
            #  The command buffer ram should also be substantially larger
            #   than the frame buffer, and note that the frame buffer occupies
            #   the front of the command buffer.  Hence, our default size
            #   is a command buffer 7x the size of the frame buffer.
            #  If you see 'Out of memory' errors in your xorg.log, you probably need
            #   to increase the surface or command buffer sizes.
            #--------------------------------------------------------------

            # The amount of surface buffer ram, in megabytes, to allocate
            # defaults to 128
            #Option "SurfaceBufferSize" "128"

            # The amount of command buffer ram, in megabytes, to allocate
            # defaults to 128
            #Option "CommandBufferSize" "128"

            # The amount of frame buffer ram, in megabytes, to reserve
            #  This is reserved out of the CommandBuffer RAM
            #  This governs the maximum size the X screen can be;
            #   4 Heads at 1920x1080 require 32M of RAM
            # defaults to 16
            #Option "FrameBufferSize" "16"

            # Set Spice Agent Mouse
            # defaults to false
            #Option "SpiceAgentMouse" "False"

            # Set Spice Playback compression
            # defaults to true
            #Option "SpicePlaybackCompression" "True"

            # Disable copy and paste
            # defaults to false
            #Option "SpiceDisableCopyPaste" "False"

            # If a directory is given, any file in that
            #  directory will be read for audio data to be sent
            #  to the client.   Default is no mixing.
            #Option "SpicePlaybackFIFODir"  "/tmp/"

        EndSection

        Section "InputDevice"
            Identifier "XSPICE POINTER"
            Driver     "xspice pointer"
        EndSection

        Section "InputDevice"
            Identifier "XSPICE KEYBOARD"
            Driver     "xspice keyboard"
        EndSection

        Section "InputClass"
          Identifier "Keyboard catchall"
          MatchIsKeyboard "on"
          Option "XkbRules" "base"
          Option "XkbModel" "pc104"
          Option "XkbLayout" "us"
          Option "XkbOptions" "terminate:ctrl_alt_bksp"
          Option "XkbVariant" ""
        EndSection

        Section "Monitor"
            Identifier    "Configured Monitor"
        EndSection

        Section "Screen"
            Identifier     "XSPICE Screen"
            Monitor        "Configured Monitor"
            Device        "XSPICE"
            DefaultDepth    24
            # Modes ${concatMapStrings (res: "${toString res.x}x${toString res.y}") cfg.resolutions}
        EndSection
      '';

    services.dbus.packages = [ e.efl ];

    systemd.user.services.efreet =
      { enable = true;
        description = "org.enlightenment.Efreet";
        serviceConfig =
          { ExecStart = "${e.efl}/bin/efreetd";
            StandardOutput = "null";
          };
      };

    systemd.user.services.ethumb =
      { enable = true;
        description = "org.enlightenment.Ethumb";
        serviceConfig =
          { ExecStart = "${e.efl}/bin/ethumbd";
            StandardOutput = "null";
          };
      };
  };

}
