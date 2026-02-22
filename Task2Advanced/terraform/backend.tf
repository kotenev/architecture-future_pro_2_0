terraform {
  backend "s3" {
    # --- Бакет и ключ состояния ---
    bucket = "terraform-state"
    key    = "future-2-0/terraform.tfstate"
    region = "ru-moscow-1"

    endpoint = "http://minio:9000"


    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    force_path_style            = true

    encrypt = true

    dynamodb_table = "terraform-locks"
  }
}