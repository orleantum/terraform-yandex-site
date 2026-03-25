locals {
  # Имя бакета мы удалили, потому что оно теперь в переменных!
  # А вот имя индексного файла оставляем здесь. 
  # Это хорошая практика: мы не хотим, чтобы пользователь снаружи мог случайно изменить "index.html" на "petya.html" и сломать логику сайта.
  index = "index.html"
}

// Create SA
resource "yandex_iam_service_account" "sa" {
  folder_id = var.folder_id
  name      = "tf-test-sa"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

# Искусственная пауза на 15 секунд, чтобы права успели разлететься по серверам Яндекса
resource "time_sleep" "wait_for_iam" {
  create_duration = "15s"

  # Таймер начнется ТОЛЬКО после того, как права будут назначены
  depends_on = [
    yandex_resourcemanager_folder_iam_member.sa-editor
  ]
}

// Use keys to create bucket
resource "yandex_storage_bucket" "orleantum-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = var.site_bucket_name

  anonymous_access_flags {
    read        = true
    list        = false
    config_read = false
  }

  website {
    index_document = local.index
  }

  depends_on = [
    time_sleep.wait_for_iam
  ]
}

resource "yandex_storage_object" "index" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  acl        = "public-read"
  bucket     = yandex_storage_bucket.orleantum-bucket.id
  key        = local.index
  # source     = "site/${local.index}"ы
  content_base64 = base64encode(local.index_template)
  content_type   = "text/html"
}

resource "yandex_storage_object" "image" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  acl        = "public-read"
  # Неявная зависимость от бакета (depends_on больше не нужен!)
  bucket = yandex_storage_bucket.orleantum-bucket.id
  # each.key будет содержать путь, например: "image/logo.png"
  key = each.key
  # Надежный абсолютный путь до файла на вашем жестком диске
  source = "${path.module}/site/${each.key}"
  # Ищем все файлы внутри папки image/
  # each.key будет равен строке "image/hustlers.jpg"
  for_each = fileset("${path.module}/site", "image/*")
}

locals {
  index_template = templatefile("${path.module}/site/${local.index}.tpl", {
    endpoint = yandex_storage_bucket.orleantum-bucket.website_endpoint
  })
}

output "orleantum_site" {
  value = yandex_storage_bucket.orleantum-bucket.website_endpoint
}
