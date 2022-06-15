provider "vault" {
  address = "https://vault.detsys.dev:8200"
}

# * create ip reservation (/32)
# * create machine w/ reserved ip
# * create "push" token
#   * with machine id
#   * ip address (ip reservation)
#   * 1 use only
# * startup: use id from metadata as secret id

data "vault_auth_backend" "approle" {
  path = "${var.network}/${var.project_name}/approle"
}

resource "vault_approle_auth_backend_role_secret_id" "id" {
  backend   = vault_auth_backend.approle.path
  role_name = "equinix-vault-auth"

  secret_id = metal_device.evaluator.id
  cidr_list = [metal_reserved_ip_block.evaluator_block.cidr_notation]
}
