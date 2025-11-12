bucket         = "pucrs-crypto-github-action-tfstate-unique"  # Onde o estado (terraform.tfstate) será salvo no S3
key            = "terraform.tfstate"                          # Nome do arquivo dentro do bucket
region         = "us-east-1"                                  # Região do bucket S3 e DynamoDB
encrypt        = true                                         # Garante criptografia no S3
dynamodb_table = "pucrs-crypto-terraform-lock"                # Controla locking (evita apply simultâneo)
