# Networking

`modules/networking`

## What it provides
A VPC with public and private subnets spread across multiple
Availability Zones, correctly wired routing (public subnets route to
an Internet Gateway; private subnets optionally route through a NAT
Gateway), and a deny-by-default baseline security group.

## Why this is a real abstraction
A team consuming this module does not need to know CIDR arithmetic,
how many route tables a VPC needs, or that a NAT Gateway must live in
a public subnet. They get a working, secure network foundation from
~5 inputs.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `project` | string | — | Project/platform name, used in naming |
| `environment` | string | — | `dev` or `prod` |
| `owner_team` | string | — | Owning team, used for tagging |
| `vpc_cidr` | string | `10.0.0.0/16` | VPC CIDR block |
| `az_count` | number | `2` | Number of AZs to spread subnets across (2-3) |
| `enable_nat_gateway` | bool | `true` | Whether private subnets get outbound internet access |

## Outputs
| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `default_security_group_id` | Baseline deny-by-default security group ID |

## Security considerations
- Private subnets have no route to the internet unless
  `enable_nat_gateway = true`.
- The baseline security group allows no inbound traffic by default;
  consuming modules (compute, RDS) add their own scoped ingress rules.

## Known limitations
- Does not create a VPN or Direct Connect attachment for
  on-premises connectivity.
- NAT Gateway, when enabled, is single-AZ (one NAT for the whole VPC)
  -- a future iteration could support one NAT per AZ for higher
  availability, at additional cost.
