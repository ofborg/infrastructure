rec {
  cole-h = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMcTaqUZSwv6YW8lx/JhsAZTdNSSC2fR8Pgk8woeFKh vin@scadrial";
  lilyinstarlight = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGKYH3ivyXgnhXL6xgZxZifRclw+2xsxWNdNe1ghjw7A lily@bina";
  zimbatm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuiDoBOxgyer8vGcfAIbE6TC4n4jo8lhG9l01iJ0bZz zimbatm";
  hexa-gaia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWQRR7dspgQ6kCwyFnoVlgmmPR4iWL1+nvq6a5ad2Ug hexa@gaia";
  hexa-helix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSpdtIxIBFtd7TLrmIPmIu5uemAFJx4sNslRsJXfFxr hexa@helix";
  mic92-turingmachine = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEVSsc5mlP8aWiUVwWWM3gKlB5LHVpmKSifnDyox/BnVAAAABHNzaDo= yubikey1";
  mic92-evo = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCsjXKHCkpQT4LhWIdT0vDM/E/3tw/4KHTQcdJhyqPSH0FnwC8mfP2N9oHYFa2isw538kArd5ZMo5DD1ujL5dLk= ssh@secretive.Joerg’s-Laptop.local";

  infra-build = [
    cole-h
    lilyinstarlight
    zimbatm
    hexa-gaia
    hexa-helix
    mic92-turingmachine
    mic92-evo
  ];
}
