{pkgs, ...}: {
  home.packages = with pkgs; [
    # GUI apps
    foliate # e-book viewer(.epub/.mobi/...),do not support .pdf

    localsend

    telegram-desktop # instant messaging
    # discord # update too frequently, use the web version instead

    # remote desktop(rdp connect)
    remmina
    freerdp # required by remmina

    # misc
    ventoy # multi-boot usb creator

    # my custom hardened packages
    pkgs.nixpaks.qq
    pkgs.nixpaks.qq-desktop-item

    wechat-uos
    # pkgs.nixpaks.wechat-uos
    # pkgs.nixpaks.wechat-uos-desktop-item
  ];

  # GitHub CLI tool
  programs.gh.enable = true;

  # allow fontconfig to discover fonts and configurations installed through home.packages
  fonts.fontconfig.enable = false; # Install fonts at system-level, not user-level
}
