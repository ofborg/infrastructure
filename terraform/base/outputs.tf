output "deploy_targets" {
  value = merge(
    {
      core = {
        ip          = metal_device.ofborg-core.network.0.address
        expression  = "{ roles.core.enable = true; }"
        provisioner = "metal"
      },
    },
    { for e in metal_device.evaluator : e.hostname => {
      ip          = e.network.0.address
      expression  = "{ services.ofborg = { builder.enable = true; evaluator.enable = true; }; }"
      provisioner = "metal"
    } },
    { for idx, e in module.evaluators : e.hostname => {
      ip          = e.public_ipv4
      expression  = "{ services.ofborg = { builder.enable = true; evaluator.enable = true; }; }"
      provisioner = "metal"
    } },
  )
}
