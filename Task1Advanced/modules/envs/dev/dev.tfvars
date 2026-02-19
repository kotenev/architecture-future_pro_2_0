cloud_id  = "b1g0000000000000000"  # Cloud ID
folder_id = "b1g1111111111111111"  # Folder ID
zone      = "ru-central1-a"

environment = "dev"

subnet_cidr       = ["10.10.0.0/24"]
allowed_ssh_cidrs = ["0.0.0.0/0"]  # Не для продуктивной среды!
nat_enabled       = true

platform_id     = "standard-v3"
image_id        = "fd8vmcue7aajpmeo39kk"   # Ubuntu 22.04 LTS
disk_type       = "network-hdd"            # HDD для dev-среды (экономия средств)
use_preemptible = true                     # Preemptible для dev-среды (экономия средств)
ssh_user        = "ubuntu"

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-key"

dwh_cores          = 2
dwh_memory         = 4
dwh_core_fraction  = 20   # 20% гарантировнного CPU (экономия средств)
dwh_boot_disk_size = 20
dwh_data_disk_size = 50

integration_cores          = 2
integration_memory         = 4
integration_core_fraction  = 20
integration_boot_disk_size = 20
integration_data_disk_size = 30

bi_cores          = 2
bi_memory         = 4
bi_core_fraction  = 20
bi_boot_disk_size = 20