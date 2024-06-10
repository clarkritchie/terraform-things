locals {
  public_subnet_ids_list         = tolist(module.vpc.public_subnets)
  public_subnet_ids_random_index = random_id.index.dec % length(module.vpc.public_subnets)
  # random_public_subnet_id is a random subnet id
  random_public_subnet_id = local.public_subnet_ids_list[local.public_subnet_ids_random_index]

  # debugging
  everything = flatten([
    for k, v in module.vpc : {
      k = k,
      v = v
    }
  ])

  # Makes a list of FQDNs, goes from "api" --> "api-test.mycompany.app"
  fully_qualified_host_names = formatlist("%s-${var.environment}.${var.site_domain}", var.host_names)

  # this is a little verbose, but produce a list of maps like this -- where each hostname maps to an IP on the LB
  # ip_fqdn                = [
  # {
  #   ip_address   = "54.67.7.242"
  #   fqdn = "api-chaos.mycompany.app"
  # },
  #   ]
  ip_fqdn_tmp_1 = [
    for fqdn in local.fully_qualified_host_names : {
      ip_address = aws_eip.nlb[0].public_ip
      fqdn       = fqdn
    }
  ]
  ip_fqdn_tmp_2 = [
    for fqdn in local.fully_qualified_host_names : {
      ip_address = aws_eip.nlb[1].public_ip
      fqdn       = fqdn
    }
  ]

  ip_fqdn = concat(local.ip_fqdn_tmp_1, local.ip_fqdn_tmp_2)

  tags = {
    Terraform   = "True"
    Environment = var.environment
  }

  # make a object of instances to instance_id
  all_instances = {
    ec2_leader  = [aws_instance.ec2_leader.id]
    ec2_group_a = [for instance in aws_instance.ec2_group_a : instance.id]
    ec2_group_b = [for instance in aws_instance.ec2_group_b : instance.id]
    worker      = [for instance in aws_instance.worker : instance.id]
  }

  # just a list of all instance ids
  all_instance_ids = flatten(values(local.all_instances))

  # make an object of device IDs
  root_block_devices = {
    ec2_leader  = [aws_instance.ec2_leader.root_block_device]
    ec2_group_a = [for instance in aws_instance.ec2_group_a : instance.root_block_device]
    ec2_group_b = [for instance in aws_instance.ec2_group_b : instance.root_block_device]
    worker      = [for instance in aws_instance.worker : instance.root_block_device]
  }

  # all_root_block_devices = flatten([
  #   for k, v in local.all_root_block_devices_tmp : [
  #     v
  #   ]
  # ])

  # all_root_block_devices = [] # merge(local.group_a_root_block_devices, local.group_b_root_block_devices, local.worker_root_block_devices)
  all_root_block_devices = flatten(values(local.root_block_devices))
}