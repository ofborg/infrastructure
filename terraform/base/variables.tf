variable "evaluators" {
  default = 7
}

variable "project_id" {
  default = "86d5d066-b891-4608-af55-a481aa2c0094"
}

variable "bootstrap_expr" {
  default = <<EXPR
{
  users.users.root.openssh.authorizedKeys.keys = [
    ''cert-authority,principals="root" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3fMouUnMVF/sHXiuhwiz0+91J24SA/bGvKGrdOEwM0r5EF0rA0NhJ6v2r8qSm+QgjaxHjbaYVyBtdc3G4mrC4UaDF30ttoB/z4HP8ilhIlv5pnd85yEq61qLILKy4xs8hIIB/Eg4dFuaBVyhz8HJk/QwAo8yfdVgus8jBuiFxi1Hx/Po6p4Ou8cM1wMrs96mCHsTr39pVkGszJWFK7LWXZ2M+rkPdHb80Ht+TI9OJnPVY6J7Q/9A55FNdfnhC5cHyfKOZnsEr7UupM5PVKMDLYWHw5JVAyZqDVwrfL+XeaIej2Er+dCS9aTkhPHXHJ898w5Mchugxe8cPOQ/smmF+kN1WTITmL838N/H7bnP0AQBpglEq4Gcu9SSX1tTtonhqUdNKg9JcTwo94sH5jdxqYNEJH2527D8E7kDa+7vLka5PKg5xwCGCsFbux1/TIyr1qm5TYWzfyNWFhNQbJ90276Gq/d59SjNGhHx6tblbL6p3Wi7g0Qwrg1LkAmtEf2hyRP1SZfOLvMxiqj1yq6o6bYf3v0QEXPKoq0md0gokZ9oGE3rPr622ey5KC7ZbbcisYxKKwPT9lE/7kJHzxH1kpdHNdP6MfF00jbIAZjf7E0qohjC4gPAN3iammlitt9xvHwd3XopA96g5YO+KkFXlFSpN4BsWfGUb17BcRkGtyQ==''
   ];
}
EXPR
}

variable "tags" {
  type    = list(string)
  default = ["terraform-ofborg"]
}
