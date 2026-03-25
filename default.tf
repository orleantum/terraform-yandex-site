terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.191.0"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "orleantum-tfstates"
    region = "ru-central1"
    key    = "orleantum-project/terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = "key.json"
}

