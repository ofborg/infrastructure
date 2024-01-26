variable "evaluators" {
  default = 5
}

variable "project_id" {
  default = "86d5d066-b891-4608-af55-a481aa2c0094"
}

variable "tags" {
  type    = list(string)
  default = ["terraform-ofborg"]
}

variable "user_data" {
  default = <<USERDATA
#!nix
{
  users.users.root.openssh.authorizedKeys.keys = [
    ''cert-authority,principals="root" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3fMouUnMVF/sHXiuhwiz0+91J24SA/bGvKGrdOEwM0r5EF0rA0NhJ6v2r8qSm+QgjaxHjbaYVyBtdc3G4mrC4UaDF30ttoB/z4HP8ilhIlv5pnd85yEq61qLILKy4xs8hIIB/Eg4dFuaBVyhz8HJk/QwAo8yfdVgus8jBuiFxi1Hx/Po6p4Ou8cM1wMrs96mCHsTr39pVkGszJWFK7LWXZ2M+rkPdHb80Ht+TI9OJnPVY6J7Q/9A55FNdfnhC5cHyfKOZnsEr7UupM5PVKMDLYWHw5JVAyZqDVwrfL+XeaIej2Er+dCS9aTkhPHXHJ898w5Mchugxe8cPOQ/smmF+kN1WTITmL838N/H7bnP0AQBpglEq4Gcu9SSX1tTtonhqUdNKg9JcTwo94sH5jdxqYNEJH2527D8E7kDa+7vLka5PKg5xwCGCsFbux1/TIyr1qm5TYWzfyNWFhNQbJ90276Gq/d59SjNGhHx6tblbL6p3Wi7g0Qwrg1LkAmtEf2hyRP1SZfOLvMxiqj1yq6o6bYf3v0QEXPKoq0md0gokZ9oGE3rPr622ey5KC7ZbbcisYxKKwPT9lE/7kJHzxH1kpdHNdP6MfF00jbIAZjf7E0qohjC4gPAN3iammlitt9xvHwd3XopA96g5YO+KkFXlFSpN4BsWfGUb17BcRkGtyQ==''
    ''cert-authority,principals="root" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2PF03p9TpixE+sPKdOTX9L4tE85eyf3u2BFVAVovkIpnhJBlCBGUANlliIkn2s/dtlvkzuoz4imD4TauUZpPt8amKEXA1ffeTOwrY13XqpZobx4JqnK5Q3Z1nyRKrmPCLYxo600CBwjm4C8xhmxybdHUol1Ru2aXbcp5LUeF+2QqwxrqyC3eutMBC5oAmh9rkz8oqWZw7DcqMidKGaYzY71ZHzuDSKwZtLyY5H9oNYhpoWg5rx6oLWQB406nIBgJdnYB1oyPx+Nx9mhSkTBgVqLpVnIeotiE7hiru8Pp2F6ISFqDQjmKYa3kNu5FUj0/6yLv0P17jdfBBx5blLwvYwrVYDE8NI1H9BnEH4D9zfvMBiWHqlSumj4nrCzTVkAP6CDcd7yd+3aqLCUrS9pgT1OSorgwTIOvpJpIsh2GjOFOOq4zTrwZbOShzDOcju8VYzRk3cU+mux5hYjX8X/7YQgzEifAuFtD+2CVYqDU4a0qenrNMs22YRftKVBewVT7V5Q7gimChgKxzVCgHqc7aIjT7M2cnCZvH1je8CSR/r9KWZcktnbYf6SfahYl8SpBR5t4AU3PrajDQ+SbgHjeTBYfL3C8DANkoGZ7RBBvpRYdJv3ktqjnl6QG+ALMQyy2KEqgzlFLrvGKiyxS2tjWCZLBcf33jEup8IQP22HDDFw==''
   ];
}
USERDATA
}

variable "metro" {
  default = "dc"
}
