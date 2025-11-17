# 🛡️ PUC-RS Crypto DevOps
[![IaC (Terraform)](https://img.shields.io/badge/Infraestrutura-Aplicada-3498db?style=for-the-badge)](https://github.com/thiagorpc/pucrs-crypto-devops/tree/main/iac)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://choosealicense.com/licenses/mit/)


## Operação
[![000. Setup Terraform AWS](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/000_setup_terraform_aws.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/000_setup_terraform_aws.yml)
[![001. Setup Infra AWS](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/001_setup_infra_aws.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/001_setup_infra_aws.yml)'
[![002. Check Infra AWS](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/002_check_infra_aws.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/002_check_infra_aws.yml)
[![003. Backend CI - Build and Push Image](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/003_backend-ci.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/003_backend-ci.yml)
[![004. Backend CD - Deploy](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/004_backend-cd.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/004_backend-cd.yml)
[![005. Frontend CI - Build UI](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/005_frontend-ci.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/005_frontend-ci.yml)
[![006. Frontend CD - Deploy UI](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/006_frontend-cd.yml/badge.svg)](https://github.com/thiagorpc/pucrs-crypto-devops/actions/workflows/006_frontend-cd.yml)


## Visão Geral do Projeto

Este é um estudo de caso prático focado na implementação completa de um fluxo de **Desenvolvimento, Integração Contínua (CI), e Infraestrutura como Código (IaC)** para uma aplicação Full-Stack.

O projeto consiste em uma **API de Criptografia (Backend)** e uma **Interface de Usuário Estática (Frontend)**, implantados na AWS utilizando contêineres e hospedagem estática, gerenciados integralmente pelo **GitHub Actions** e **Terraform**.

### Autores
* [@thiagorpc](https://github.com/thiagorpc)

---

## 1. Componentes e Objetivos

### 1.1. Descrição dos Serviços

* **Crypto API (Backend):** Desenvolvida em **NestJS** (TypeScript), expõe *endpoints* RESTful (`/encrypt`, `/decrypt`, `/health`). A API é containerizada com Docker e rodará em **AWS Fargate** (serviço *serverless* de contêineres).

* **Crypto UI (Frontend):** Desenvolvida em **React + Vite (TypeScript)**, apresenta uma página web estática que consome a Crypto API. A UI é hospedada em um **AWS S3 Bucket**, distribuída via **Amazon CloudFront** para acesso global.


### 1.2. Stack Tecnológica

| Camada | Tecnologia Principal | Infraestrutura de Implantação | 
| :--- | :--- | :--- | 
| **Backend** | NestJS (TypeScript), Docker | AWS ECS Fargate, AWS ECR, AWS NLB | 
| **Frontend** | React + Vite para gerar HTML, CSS, JavaScript | AWS S3 Static Hosting | 
| **DevOps** | GitHub Actions (CI), Terraform (IaC) | AWS Services | 

### 1.3. Metas de DevOps

| Categoria | Objetivo | Requisito Atendido | 
| :--- | :--- | :--- | 
| **Integração Contínua (CI)** | Implementar **dois pipelines de CI** (Backend e Frontend) no GitHub Actions, automatizando *linting*, testes, *build* de contêineres e empacotamento. | *Plano de Integração Contínua* | 
| **Infraestrutura como Código (IaC)** | Utilizar **Terraform** para provisionar e gerenciar **toda** a infraestrutura AWS (VPC, Fargate, ECR, Load Balancer, S3). | *Especificação da Infraestrutura* | 
| **Qualidade & Segurança** | Garantir a execução de testes automatizados e integrar uma etapa futura de **Análise de Segurança Estática (SAST)** no pipeline do Backend (DevSecOps). | *Define o critério de sucesso para esse caso prático de estudo* | 

---

## 2. Estrutura do Repositório

O projeto segue as melhores práticas de separação de código de aplicação e infraestrutura:

```
pucrs-crypto-devops\
    ├─ .github/workflows   # Arquivos YAML do GitHub Actions (CI) \
    ├─ crypto-api          # Código-fonte do Backend (NestJS)\
    ├─ crypto-ui           # Código-fonte do Frontend (Estático)\
    └─ iac                 # Scripts de Infraestrutura como Código (Terraform)
```

**Link do Repositório:** <https://github.com/thiagorpc/pucrs-crypto-devops>


---

## 3. Configuração do CI/CD com AWS

Para que o GitHub Actions execute o Terraform e interaja com a AWS, é essencial configurar as credenciais de acesso como segredos no seu repositório.

### 3.1. Criando um Usuário IAM na AWS

1. Acesse o **IAM Management Console** na AWS.

2. Crie um novo usuário (ex: `github-actions-user`).

3. Selecione **Programmatic access** (Acesso programático).

4. Anexe as permissões necessárias.

> [!WARNING]
> **Permissões Mínimas Recomendadas:** Para a execução completa do Terraform, este usuário precisará de acesso administrativo ou uma política personalizada abrangente que cubra `ec2`, `ecs`, `ecr`, `s3`, `iam`, `nlb` e `logs`. Use a política a seguir (ou **AdministratorAccess** se estiver em um ambiente de estudo):

**Permissões Mínimas Recomendadas:** Para que o Terraform provisione todos os recursos (ECS, ECR, S3, IAM, etc.), utilize a política abaixo.


```javascript
{
  "Version": "2025-11-09",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*", "ecs:*", "ecr:*", "s3:*", "iam:*", 
        "cloudwatch:*", "logs:*", "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
```

> [!IMPORTANT]
> Após a criação, guarde o **Access Key ID** e o **Secret Access Key**. Eles serão usados no próximo passo.



### 3.2. Configurando Credenciais da AWS

## 3.2.1. Uso Atual — GitHub Secrets (Acesso via Access Keys)

Atualmente, o pipeline do projeto utiliza credenciais programáticas da AWS armazenadas como segredos no GitHub Actions.

Essas credenciais permitem que o Terraform, Docker e demais ações (aws-actions/configure-aws-credentials@v4) interajam com a conta AWS para:

- Provisionar e destruir infraestrutura (Terraform)
- Fazer login no ECR e publicar imagens
- Executar comandos S3, ECS, CloudFront e API Gateway
- Essas chaves são criadas no IAM Console da AWS e armazenadas como segredos:

Nome do Secret	Descrição
- *AWS_ACCESS_KEY_ID*	Identificador público da credencial do usuário IAM
- *AWS_SECRET_ACCESS_KEY*	Chave privada da credencial do usuário IAM


1. Configure esse secgredo no seu repositório GitHub através do menu **Settings > Secrets and Variables > Actions**.

2. Clique em **New repository secret** e crie os dois segredos a seguir, utilizando as chaves geradas pelo IAM:

| Nome do Secret | Valor | 
| ----- | ----- |
| **AWS_ACCESS_KEY_ID** | Chave de Acesso do Usuário IAM | 
| **AWS_SECRET_ACCESS_KEY** | Chave Secreta do Usuário IAM |


## 3.2.2. Boas Práticas de Segurança

🔒 Nunca exponha chaves em logs ou variáveis de ambiente públicas.

♻️ Rotacione periodicamente as Access Keys (recomenda-se a cada 90 dias).

🧩 Use um usuário IAM exclusivo para o GitHub Actions (ex: github-actions-user) com permissões mínimas.

🧱 Armazene a política mínima necessária — o README já inclui o JSON com escopo limitado a ec2, ecs, ecr, s3, iam, cloudwatch, logs e elasticloadbalancing.


## 3.2.3. Futuro — Acesso sem Chaves via IAM Roles (OIDC Federation)

Como evolução natural de segurança, o projeto planeja migrar do uso de Access Keys fixas para IAM Roles temporárias, utilizando OpenID Connect (OIDC) entre o GitHub Actions e a AWS.

Esse modelo elimina completamente o uso de chaves estáticas.

| Método                         | Descrição                                        | Benefício                                               |
| ------------------------------ | ------------------------------------------------ | ------------------------------------------------------- |
| **Access Keys (atual)**        | Chaves armazenadas nos Secrets do GitHub         | Simples, mas requer rotação manual                      |
| **IAM Role via OIDC (futuro)** | GitHub assume um papel IAM temporário autorizado | Zero exposição de chaves, autenticação de curta duração |


🔄 Migração planejada

- Criar um IAM Role na AWS confiando no provedor OIDC do GitHub (token.actions.githubusercontent.com)

- Atribuir políticas necessárias (ex: ECR, ECS, S3, CloudFront)

- Atualizar os workflows para usar o bloco:

```yaml
    - name: 🔐 Configurar Credenciais AWS via OIDC
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRole
        aws-region: us-east-1
```

Dessa forma:
- O GitHub autentica diretamente com a AWS sem segredos.
- As permissões são temporárias e válidas apenas durante o job.
- A auditoria é centralizada no IAM Role e no OpenID Provider


## 3.2.4. Referência Oficial AWS
- [📘 Use IAM Roles to Connect GitHub Actions to AWS (OIDC)](https://chatgpt.com/c/691a1d41-fbcc-832d-b12a-2584604e277b#:~:text=3.2.4.%20Refer%C3%AAncia%20Oficial,credentials%40v4%20%E2%80%94%20Documenta%C3%A7%C3%A3o)

- [🧰 aws-actions/configure-aws-credentials@v4 — Documentação](https://github.com/aws-actions/configure-aws-credentials)

---

## 4. Executando, Testando e Implantando

### 4.1. Fluxo de CI/CD (GitHub Actions)
O workflow de CI/CD é acionado automaticamente:

1. Push ou Pull Request para main: Dispara os pipelines de CI (Linting, Testes, Build do Backend/Frontend).

2. Merge na main: Dispara o pipeline de IaC (Terraform).

[!NOTE] O pipeline de IaC executa terraform plan e terraform apply, provisionando o ECS Fargate (para o backend) e o S3 + CloudFront (para o frontend) na AWS.


### 4.2. Comandos de Inicialização e Testes

Para começar a trabalhar no projeto:


```bash
# Clone o repositório
git clone https://github.com/thiagorpc/pucrs-crypto-devops.git
cd pucrs-crypto-devops

# Adicione seus arquivos e envie para o GitHub
git add .
git commit -m "Implementacao inicial do projeto pucrs-crypto-devops"
git push -u origin main
```


Para começar a trabalhar no projeto:

```bash
  # Executa todos os testes do projeto crypto-api
  cd  .\crypto-api\
  npm run test

  # Executa todos os testes do projeto crypto-ui
  cd  .\crypto-ui\
  npm run test
```

### 4.3. Variáveis de Ambiente

Para rodar o projeto localmente, adicione as seguintes variáveis no seu arquivo **.env**:

```bash

    NODE_ENV="production" || "development"
    PORT=3000
    HOST="0.0.0.0"
    TZ="America/Sao_Paulo"

    # Chave usada na criptografia (Superior a 32 caracteres)
    ENCRYPTION_KEY="MinhaChaveUltraSecreta1234567890"
```

### 4.4. Workflows de Automação Disponíveis

| Workflow | Descrição |
|-----------|------------|
| `000_setup_terraform_aws.yml` | Configura o backend remoto (S3 e DynamoDB) |
| `001_setup_infra_aws.yml` | Provisiona infraestrutura AWS |
| `002_check_infra_aws.yml` | Valida integridade da infraestrutura |
| `003_backend-ci.yml` | Build, teste e push da imagem Docker do backend |
| `004_backend-cd.yml` | Deploy automatizado do backend via Terraform |
| `005_frontend-ci.yml` | Build e teste do frontend React (Vite) |
| `006_frontend-cd.yml` | Deploy do frontend em S3 e invalidação CloudFront |
| `009_destroy.yml` | Destrói e limpa todos os recursos AWS |


---

## 5. Referências e Links uteis

### 5.1. Ferramentas
- [Editor README.md](https://readme.so/editor)

### 5.2. AWS
- AWS IAM: [Criando um usuário IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://aws.amazon.com/ecs/fargate/)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Use IAM roles to connect GitHub Actions to actions in AWS](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/)

---

## 6. Licença de uso

Este projeto está licenciado sob a licença [MIT](https://choosealicense.com/licenses/mit/)

