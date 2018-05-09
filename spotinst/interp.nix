let
  dup = f: x: f x x;
  trace = dup builtins.trace;
  instanceListToAttrset = instances:
    builtins.listToAttrs
      (builtins.map (i: {
        name = i.terraform.name;
        value = i;
      }) instances);

  tagsToRoles = tags: builtins.listToAttrs
      (builtins.map (t: {
        name = "${t}";
        value = {enable = true;};
      }) tags);
  ipToTerraformLookalike = ip_block: {
    inherit (ip_block) address;
    cidr = (builtins.toString ip_block.cidr);
    gateway = (builtins.toString ip_block.gateway);
    family = builtins.toString ip_block.address_family;
    public = if ip_block.public then "1" else "0";
  };
  toInstance = { hostname, short_id, ip_addresses, plan, tags, ... } @ data: {
    terraform.name = "${hostname}-${short_id}";
    networking.hostName = "${short_id}.packethost.net";
    packet.plan = plan.slug;
    packet.network_data = builtins.toJSON
      (builtins.map ipToTerraformLookalike ip_addresses);
    roles = tagsToRoles tags;
  };
in instanceListToAttrset (map toInstance
  (builtins.fromJSON
    (builtins.readFile ./instances.json)))
