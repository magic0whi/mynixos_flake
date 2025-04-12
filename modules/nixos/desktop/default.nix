{pkgs, config, lib, mylib, myvars, ...}:
let
  cfg = config.modules.desktop.wayland;
in {
  options.modules.desktop.wayland.enable = lib.mkEnableOption "Wayland Display Server";
  imports = mylib.scan_path ./.;
  config = (lib.mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk # For GTK
      ];
      config = {
        common = {
          # Use xdg-desktop-portal-gtk for every portal interface...
          default = ["gtk"];
          # except the secret portal, which is handled by gnome-keyring
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        };
      };
    };
    services = {
      xserver.enable = false; # disable xorg server
      # https://wiki.archlinux.org/title/Greetd
      greetd = {
        enable = true;
        settings = {
          default_session = { # Wayland Desktop Manager is installed only for user via home-manager!
            user = myvars.username;
            # .wayland-session is a script generated by home-manager, which links to the current wayland compositor(sway/hyprland or others).
            # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config here.
            command = "$HOME/.wayland-session"; # start a wayland session directly without a login manager
            # command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd $HOME/.wayland-session";  # start wayland session with a TUI login manager
          };
        };
      };
      gvfs.enable = true; # Mount, trash, and other functionalities
      tumbler.enable = true; # Thumbnail support for images
    };
    security.pam.services.swaylock = {}; # fix https://github.com/ryan4yin/nix-config/issues/10

    ## START peripherals.nix
    # Audio(PipeWire)
    environment.systemPackages = with pkgs; [
      pulseaudio # Provides `pactl`, which is required by some apps(e.g. sonic-pi)
      wl-clipboard
    ];
    # PipeWire is a new low-level multimedia framework.
    # It aims to offer capture and playback for both audio and video with minimal latency.
    # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
    # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
    # https://nixos.wiki/wiki/PipeWire
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault true;
      wireplumber.enable = lib.mkDefault true;
    };
    security.rtkit.enable = lib.mkDefault true; # rtkit is optional but recommended
    services.pulseaudio.enable = false; # Disable pulseaudio, it conflicts with pipewire.
    # Bluetooth
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    # Misc
    services = {
      printing.enable = lib.mkDefault true; # Enable CUPS to print documents.
      geoclue2.enable = true; # Enable geolocation services.
      udev.packages = with pkgs; [
        gnome-settings-daemon
        platformio # udev rules for platformio
        openocd # required by paltformio, see https://github.com/NixOS/nixpkgs/issues/224895
        android-udev-rules # required by adb
        openfpgaloader
      ];
      # A key remapping daemon for linux.
      # https://github.com/rvaiya/keyd
      keyd = {
        enable = true;
        keyboards.default.settings = {
          main = { # overloads the capslock key to function as both escape (when tapped) and control (when held)
            capslock = "overload(control, esc)";
            esc = "capslock";
          };
        };
      };
    };
    ## END peripherals.nix
    ## START fonts.nix
    fonts = { # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
      enableDefaultPackages = lib.mkOverride 999 false; # use fonts specified by user rather than default ones
      fontDir.enable = lib.mkDefault true;

      packages = with pkgs; [
        # icon fonts
        material-design-icons # TODO: Remove
        font-awesome # TODO: Remove

        noto-fonts noto-fonts-emoji noto-fonts-cjk-sans noto-fonts-cjk-serif
        inter-nerdfont # NerdFont patch of the Inter font
        # nerdfonts
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
        nerd-fonts.symbols-only # symbols icon only
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.iosevka
      ];
      fontconfig = {
        subpixel.rgba = "rgb";
        defaultFonts = {
          serif = ["Noto Serif" "FZYaSongS-R-GB" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP"];
          sansSerif = ["Inter Nerd Font" "Noto Sans" "Noto Sans CJK SC" "Noto Sans CJK TC" "Noto Sans CJK JP"];
          monospace = ["Iosevka Nerd Font Mono" "JetBrainsMono Nerd Font" "Iosevka Term Extended" "Noto Sans Mono" "Noto Sans Mono CJK SC" "Noto Sans Mono CJK TC" "Noto Sans Mono CJK JP"];
          emoji = ["Noto Color Emoji"];
        };
      };
    };

    # https://wiki.archlinux.org/title/KMSCON
    services.kmscon = {
      # Use kmscon as the virtual console instead of gettys.
      # kmscon is a kms/dri-based userspace virtual terminal implementation.
      # It supports a richer feature set than the standard linux console VT,
      # including full unicode support, and when the video card supports drm should be much faster.
      enable = true;
      fonts = [
        {
          name = "Iosevka Nerd Font Mono";
          package = pkgs.nerd-fonts.iosevka;
        }
      ];
      extraOptions = "--term xterm-256color";
      extraConfig = "font-size=12";
      # Whether to use 3D hardware acceleration to render the console.
      hwRender = true;
    };
    ## END fonts.nix
    ## START misc.nix
    # fix for `sudo xxx` in kitty/wezterm/foot and other modern terminal emulators
    # security.sudo.keepTerminfo = true; # TODO, may be unnecessary
    # The OpenSSH agent remembers private keys for you
    # so that you don’t have to type in passphrases every time you make an SSH connection.
    # Use `ssh-add` to add a key to the agent.
    programs = {
      ssh.startAgent = true;
      dconf.enable = true;
      thunar = { # thunar file manager(part of xfce)
        enable = true;
        plugins = with pkgs.xfce; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
      light.enable = true;
    };
    ## END misc.nix
    ## START security.nix
    security.polkit.enable = true; # security with polkit
    # security with gnome-kering
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
    programs.gnupg.agent = { # gpg agent with pinentry
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
      enableSSHSupport = false;
      settings.default-cache-ttl = 4 * 60 * 60; # 4 hours
    };
    ## END security.nix
  });
}
