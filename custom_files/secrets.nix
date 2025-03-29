# This file is not imported into your NixOS configuration. It is only used for the agenix CLI.
# agenix use the public keys defined in this file to encrypt the secrets.
# and users can decrypt the secrets by any of the corresponding private keys.

let
  # Get system's ssh public key by command:
  #    cat /etc/ssh/ssh_host_ed25519_key.pub
  # If you do not have this file, you can generate all the host keys by command:
  #    sudo ssh-keygen -A
  proteus-sp4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXsaDf55GqKAtSaeE8Kj29ZvrMqIgxhu+Lg9j7T1FC/ root@proteus-sp4";
  idol_ai = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHZtzeaQyXwuRMLzoOAuTu8P9bu5yc5MBwo5LI3iWBV root@ai";
  harmonica = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINT7Pgy/Yl+t6UkHp5+8zfeyJqeJ8EndyR1Vjf/XBe5f root@harmonica";
  fern = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMokXUYcUy7tysH4tRR6pevFjyOP4cXMjpBSgBZggm9X root@fern";

  # A key for recovery purpose, generated by `ssh-keygen -t ed25519 -a 256 -C "ryan@agenix-recovery"` with a strong passphrase
  # and keeped it offline in a safe place.
  recovery_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGhtVHEggEx+kIZlDnUQreFOJYTgHo6i2JKCFpQjYc5 proteus@agenix-recovery";
  machines = [
    proteus-sp4
    idol_ai
    harmonica
    fern

    recovery_key
  ];
in {
  "./test.key.age".publicKeys = machines;
}
