{
  roles.darwin-builder.enable = true;
  services.ofborg.macos_vm.version = "catalina";
  macosGuest = {
    guest = {
      sockets = 1;
      cores = 4;
      threads = 1;
      memoryInMegs = 13 * 1024;
    };
    network.externalInterface = "ens1";
  };
}

