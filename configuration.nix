{ config, pkgs, lib, ... }:

let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
      }))
    ];
  };
  vim-colors-github = pkgs.vimUtils.buildVimPlugin {
    name = "vim-colors-github";
    src = pkgs.fetchFromGitHub {
      owner = "cormacrelf";
      repo = "vim-colors-github";
      rev = "ee42a68d95078f5a3d1c0fb14462cc781b244ee2";
      sha256 = "1kvvd38nsbpq7a3lf7yj94mbydyb7yiz3mvwbyf6xlhida3y95p3";
    };
  };
in {
  ### Local config files ###
  # hardware-configuration.nix should be generated during install.
  # hostname.nix must contain ` networking.hostName = "rx570-nixos"; `.
  imports = [
    /etc/nixos/hardware-configuration.nix
    /etc/nixos/hostname.nix
    /etc/nixos/cachix.nix
  ];

  config = lib.mkMerge [{
    ### Packages ###
    environment.systemPackages = with pkgs; [
      # gui apps
      alacritty chromium qutebrowser tdesktop zathura sublime3 thunderbird birdtray gimp
      libreoffice minecraft lyx teams feh unstable.musescore
      # cli system-wide tools
      curl fzf git htop lazygit p7zip ripgrep wget zsh
      aria2 tmux python3
      # terminal file manager
      ranger ueberzug
      # desktop supplementary tools
      wmctrl xdotool play-with-mpv xsel
      # multimedia
      elisa mpc_cli mpd mpdris2 mpv ncmpcpp ffmpeg imagemagick
      # sync
      syncthing
      # texlive
      texlive.combined.scheme-full
      # kde supplementaries
      kwallet-pam plasma-browser-integration libnotify ark unrar libappindicator-gtk3
      # theme gtk apps properly
      gnome.adwaita-icon-theme
      # virtualization
      libvirt virt-manager
      # container
      podman
      # for lorri
      direnv
      # customized vim
      (pkgs.neovim.override {
       viAlias = true;
       vimAlias = true; 
        configure = {
          customRC = ''
            colo github
            set termguicolors bg=light
            set et is si ai rnu hls hidden mouse=a ts=4 sts=4 sw=4
            set clipboard=unnamed,unnamedplus
            nn ; :
            vn ; :
            nn <silent> <CR> :noh<CR><CR>
            syn on
            filet plugin indent on
          '';
          packages.myPlugins = with pkgs.vimPlugins; {
            start = [ vim-nix vim-colors-github ];
            opt = [];
          };
      };
    })
  ];

    # Font packages
    fonts.fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      source-han-serif
      fira-code
      fira-mono
    ];

    # Allow some nonfree packages
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "sublimetext3" "minecraft-launcher" "unrar" "nvidia-x11" "nvidia-settings" "nvidia-persistenced" "cudatoolkit"
      "libtorch" "pytorch" "teams"
    ];

    ### Basics ###
    # Bootloader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Networking
    networking.useDHCP = false;
    networking.networkmanager.enable = true;
    networking.firewall.enable = false;

    # Firmware thing
    hardware.enableRedistributableFirmware = true;

    # Decrease systemd timeout
    systemd.extraConfig = ''
      DefaultTimeoutStopSec=15s
    '';

    ### X settings ###
    services.xserver.enable = true;
    services.xserver.xkbOptions = "altwin:swap_alt_win";
    # KDE Plasma
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
    # Touchpad
    services.xserver.libinput.enable = true;
    # Printers
    services.printing.enable = true;
    # Audio
    hardware.pulseaudio.enable = true;
    sound.enable = true;

    # Lorri
    services.lorri.enable = true;

    ### MPD ###
    hardware.pulseaudio.extraConfig = "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1";
    services.mpd = {
      enable = true;
      user = "akitaki";
      group = "users";
      extraConfig = ''
        music_directory "/home/akitaki/Music"
        follow_outside_symlinks "yes"
        follow_inside_symlinks "yes"
        audio_output {
            type "pulse"
            name "Pulseaudio"
            server "127.0.0.1"
        }
      '';
    };

    ### User ###
    users.users.akitaki = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "input" ];
      shell = pkgs.zsh;
    };

    ### System env ###
    environment.variables.EDITOR = "nvim";
    system.stateVersion = "21.05";

    ### Virtualisation
    virtualisation = {
      libvirtd.enable = true;
      podman = {
        enable = true;
        enableNvidia = true;
      };
    };

    ### Syncthing ###
    services.syncthing = {
      enable = true;
      user = "akitaki";
      dataDir = "/home/akitaki/Sync";
      configDir = "/home/akitaki/.config/syncthing";
    };

    ### Localization ###
    time.timeZone = "Asia/Taipei";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_TW.UTF-8/UTF-8" "ja_JP.UTF-8/UTF-8" ];
      inputMethod = {
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-mozc
          fcitx5-rime
          fcitx5-gtk
          fcitx5-configtool
        ];
      };
    };
  } (lib.mkIf (config.networking.hostName == "x13-nixos") {
    environment.systemPackages = with pkgs; [
      fprintd libinput-gestures tlp
    ];

    # Larger tty font
    console.font = "ter-132n";
    console.packages = with pkgs; [
      terminus
    ];

    # TLP
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNER_ON_BAT = "powersave";
        CPU_SCALING_GOVERNER_ON_AC = "performance";
      };
    };

    # Fingerprint
    services.fprintd.enable = true;
  }) (lib.mkIf (config.networking.hostName == "rtx3070-nixos") {
    environment.systemPackages = with pkgs; [
      nvidia-docker nvidia-podman cudatoolkit_11_1 cudnn_cudatoolkit_11_1
      python3Packages.pytorch-bin
      (libtorch-bin.override { cudaSupport = true; })
    ];

    # Nvidia driver
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.opengl.enable = true;
    hardware.opengl.driSupport32Bit = true;
    # ssh server
    services.sshd.enable = true;
    services.openssh.ports = import /etc/nixos/ssh-ports.nix;
  }) {
    # Emacs with native-comp
    # To use community cachix:
    # # nix-env -iA cachix -f https://cachix.org/api/v1/install
    # # cachix use nix-community
    environment.systemPackages = [
      unstable.emacsGcc
    ];
  }];
}

