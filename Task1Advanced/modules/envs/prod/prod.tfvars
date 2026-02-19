cloud_id       = "b1g0000000000000000"
folder_id      = "b1g3333333333333333"
zone           = "ru-central1-a"
secondary_zone = "ru-central1-b"

environment = "prod"

subnet_cidr           = ["10.30.0.0/24"]
secondary_subnet_cidr = ["10.30.1.0/24"]
allowed_ssh_cidrs     = ["10.0.0.100/32"]   # Bastion host only
allowed_https_cidrs   = ["0.0.0.0/0"]
nat_enabled           = false                # No public IPs in prod

platform_id    = "standard-v3"
image_id       = "fd8vmcue7aajpmeo39kk"
disk_type      = "network-ssd"               # SSD for production
ssh_user       = "ubuntu"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-key"

dwh_cores          = 8
dwh_memory         = 32
dwh_core_fraction  = 100   # Full CPU guaranteed
dwh_boot_disk_size = 50
dwh_data_disk_size = 500   # Large storage for DWH

integration_cores          = 4
integration_memory         = 16
integration_core_fraction  = 100
integration_boot_disk_size = 50
integration_data_disk_size = 100

bi_cores          = 8
bi_memory         = 32
bi_core_fraction  = 100
bi_boot_disk_size = 50
bi_data_disk_size = 200

ai_cores          = 8
ai_memory         = 32
ai_core_fraction  = 100
ai_boot_disk_size = 50
ai_data_disk_size = 200

fintech_cores          = 4
fintech_memory         = 16
fintech_core_fraction  = 100
fintech_boot_disk_size = 50
fintech_data_disk_size = 100