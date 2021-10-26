# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.useDHCP = false;
  networking.interfaces.ens1.useDHCP = true;

  services.openssh.enable = true;

  system.stateVersion = "20.09"; # Did you read the comment?
  services.tailscale.enable = true;
}

