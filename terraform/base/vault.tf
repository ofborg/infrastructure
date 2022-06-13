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
