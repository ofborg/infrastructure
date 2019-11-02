{
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUy2CGT6P3q2kApZEuyCHsuCruwdRzeWMdQe/WjdCak grahamc@Petunia"
  ];
}
