☁️ Serverless Static Website Deployment (Yandex Cloud + Terraform)

![alt text](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)


![alt text](https://img.shields.io/badge/Yandex%20Cloud-FF0000.svg?style=for-the-badge&logo=yandex&logoColor=white)


![alt text](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

Этот проект представляет собой полностью автоматизированный конвейер (CI/CD) для развертывания статического веб-сайта в Yandex Cloud (S3 Object Storage) с использованием подхода Infrastructure as Code (IaC).

🎯 Архитектура и реализованные Best Practices

Проект не просто создает бакет, а демонстрирует "взрослые" практики DevOps:

🔒 Security & Least Privilege: Инфраструктура разделена на 2 уровня прав. Главный сервисный аккаунт используется только для доступа к tfstate. Для управления самим сайтом Terraform динамически создает отдельный ограниченный аккаунт (storage.admin) и генерирует для него статические ключи.

📦 Remote State: Локальный файл состояния не используется. terraform.tfstate безопасно хранится в удаленном зашифрованном S3-бакете (Yandex Object Storage).

🤖 СI/CD Pipeline: Настроен пайплайн в GitHub Actions. При пуше в ветку main сервер автоматически проверяет форматирование, строит план и применяет изменения (terraform apply).

⚙️ Dynamic Content: Использование функции templatefile() для генерации HTML "на лету" (внедрение URL созданного бакета прямо в код сайта) и кодирование через content_base64.

DRY (Don't Repeat Yourself): Использование цикла for_each и функции fileset() для массовой загрузки изображений и ассетов сайта из локальной директории в облако без дублирования кода.

🔑 Secrets Management: Никаких захардкоженных паролей или ID. Все чувствительные данные передаются через GitHub Secrets и переменные окружения (TF_VAR_).

📁 Структура проекта
code
Text
download
content_copy
expand_less
├── .github/workflows/
│   └── terraform.yml      # CI/CD пайплайн для GitHub Actions
├── site/
│   ├── image/             # Ассеты сайта (картинки)
│   └── index.html.tpl     # Шаблон HTML-страницы сайта
├── default.tf             # Настройка Yandex Provider и Remote Backend (S3)
├── main.tf                # Основная логика: IAM, ключи, Bucket, загрузка объектов
├── variables.tf           # Декларация входных переменных
└── README.md
🚀 Как запустить проект (Local Run)
1. Подготовка "Фундамента" (Backend)

Поскольку Terraform должен где-то хранить свое состояние, перед первым запуском необходимо вручную создать в консоли Yandex Cloud:

Сервисный аккаунт с правами admin на каталог и выпустить для него статические ключи (access_key и secret_key) + файл key.json.

Пустой приватный бакет для хранения стейта (например, my-tfstate-bucket).

Вписать имя этого бакета и статические ключи в блок backend "s3" в файле default.tf.

2. Настройка переменных

Создайте файл terraform.tfvars (он добавлен в .gitignore для безопасности) и заполните его:

code
Hcl
download
content_copy
expand_less
cloud_id         = "ваш_cloud_id"
folder_id        = "ваш_folder_id"
3. Развертывание

Выполните команды в терминале:

code
Bash
download
content_copy
expand_less
terraform init          # Инициализация провайдера и подключение к удаленному S3 Backend
terraform fmt -check    # Проверка форматирования кода
terraform plan          # Просмотр планируемых изменений
terraform apply         # Развертывание инфраструктуры

В конце выполнения Terraform выведет в консоль готовую публичную ссылку на развернутый сайт (output orleantum_site).

🔄 Настройка CI/CD (GitHub Actions)

Для автоматического деплоя при git push необходимо добавить следующие секреты в настройки репозитория (Settings -> Secrets and variables -> Actions):

Имя секрета	Описание
YC_ACCESS_KEY	Статический ключ доступа супер-аккаунта (для доступа к Backend S3)
YC_SECRET_KEY	Секретный ключ супер-аккаунта
YC_CLOUD_ID	ID вашего облака в Yandex Cloud
YC_FOLDER_ID	ID вашего каталога
YC_KEY_JSON	Полное содержимое файла авторизации key.json (создается на лету в runner'е)

Имя бакета для сайта передается открытым текстом в блоке env: файла terraform.yml как переменная TF_VAR_site_bucket_name.

🛠️ Планы по развитию (Roadmap)

Вынос логики создания S3-бакета и IAM-ролей в переиспользуемый Terraform Module.

Привязка кастомного доменного имени (Yandex Cloud DNS).

Настройка HTTPS с автоматическим выпуском сертификата Let's Encrypt (Yandex Certificate Manager).

Интеграция статического анализатора кода (tfsec / checkov) в пайплайн GitHub Actions.