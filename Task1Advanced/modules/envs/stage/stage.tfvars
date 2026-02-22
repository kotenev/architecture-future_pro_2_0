cloud_id  = "b1g0000000000000000"
folder_id = "b1g2222222222222222"
zone      = "ru-central1-b"

environment = "stage"

subnet_cidr       = ["10.20.0.0/24"]
allowed_ssh_cidrs = ["10.0.0.0/8", "172.16.0.0/12"]  # Internal networks only
nat_enabled       = true

platform_id     = "standard-v3"
image_id        = "fd8vmcue7aajpmeo39kk"
disk_type       = "network-ssd"          # SSD for better performance
use_preemptible = false                  # Stable instances for staging
ssh_user        = "ubuntu"
ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-key"

dwh_cores          = 4
dwh_memory         = 8
dwh_core_fraction  = 50
dwh_boot_disk_size = 30
dwh_data_disk_size = 100

integration_cores          = 4
integration_memory         = 8
integration_core_fraction  = 50
integration_boot_disk_size = 30
integration_data_disk_size = 50

bi_cores          = 4
bi_memory         = 8
bi_core_fraction  = 50
bi_boot_disk_size = 30
bi_data_disk_size = 50

ai_cores          = 4
ai_memory         = 16
ai_core_fraction  = 50
ai_boot_disk_size = 30
ai_data_disk_size = 100