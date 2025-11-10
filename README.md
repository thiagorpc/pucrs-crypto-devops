# 🛡️ PUC-RS Crypto DevOps

Este é um estudo de caso prático focado na implementação completa de um fluxo de **Desenvolvimento, Integração Contínua (CI), e Infraestrutura como Código (IaC)** para uma aplicação Full-Stack.

O projeto consiste em uma **API de Criptografia (Backend)** e uma **Interface de Usuário Estática (Frontend)**, implantados na AWS utilizando contêineres e hospedagem estática.

---

## 1. Documentação de Planejamento

### 1.1. Descrição do Projeto

O projeto é composto por dois serviços:

* **Crypto API (Backend):** Desenvolvida em **NestJS** (TypeScript), expõe *endpoints* RESTful para operações de criptografia (`/encrypt`, `/decrypt`, `/hash`). A API será containerizada com Docker e rodará em **AWS Fargate** (serviço *serverless* de contêineres).
* **Crypto UI (Frontend):** Uma página web estática simples (HTML/CSS/JavaScript) que consome a Crypto API, permitindo ao usuário interagir com os serviços de criptografia. A UI será hospedada em um **AWS S3 Bucket** configurado para hospedagem de sites estáticos.

### 1.2. Objetivos do Projeto

| Categoria | Objetivo | Requisito Atendido |
| :--- | :--- | :--- |
| **Integração Contínua (CI)** | Implementar **dois pipelines de CI** no GitHub Actions que automatizam o *linting*, testes, *build* de contêineres (Backend) e o empacotamento (Frontend). | *1.b) Plano de Integração Contínua* |
| **Infraestrutura como Código (IaC)** | Utilizar **Terraform** para provisionar e gerenciar **toda** a infraestrutura AWS (VPC, Fargate, ECR, Load Balancer, S3 para UI). | *1.c) Especificação da Infraestrutura* |
| **Qualidade & Segurança** | Garantir 100% de passagem nos testes automatizados e integrar uma etapa de **Análise de Segurança Estática (SAST)** no pipeline do Backend (DevSecOps). | *Critério de Sucesso do Estudo* |

### 1.3. Requisitos Técnicos

| Camada | Tecnologia Principal | Infraestrutura de Implantação |
| :--- | :--- | :--- |
| **Backend** | NestJS (TypeScript), Docker | AWS ECS Fargate, AWS ECR, AWS ALB |
| **Frontend** | HTML, CSS, JavaScript | AWS S3 Static Hosting, AWS CloudFront (Opcional) |
| **DevOps** | GitHub Actions (CI), Terraform (IaC) | AWS Services |

---

## 2. Estrutura do Repositório

O projeto está organizado em três diretórios principais, seguindo as melhores práticas de separação de código de aplicação e infraestrutura:

pucrs-crypto-devops\
    ├─ .github/workflows   # Arquivos YAML do GitHub Actions (CI) \
    ├─ crypto-api          # Código-fonte do Backend (NestJS)\
    ├─ crypto-ui           # Código-fonte do Frontend (Estático)\
    └─ iac                 # Scripts de Infraestrutura como Código (Terraform)


## 3. Link para o Repositório

**OBS.:** O restante da documentação de planejamento (Plano de CI e Especificação de Infraestrutura) está detalhada nos arquivos específicos.

**Link do Repositório:** **https://github.com/thiagorpc/pucrs-crypto-devops**

## 4. Publicando o Projeto no GitHub
### 4.1. Adiciona o README e a estrutura vazia
git add .

### 4.2. Faz o primeiro commit
git commit -m "Estrutura inicial do projeto e documentacao de planejamento (README)"

### 4.3. Adiciona o remote do GitHub
git remote add origin **https://github.com/thiagorpc/pucrs-crypto-devops.git**

### 4.4. Envia para o GitHub (e define a branch principal como 'main' ou 'master')
git push -u origin main


## 5. Configurando o GitHub Actions com AWS

Para que o GitHub Actions execute o Terraform e interaja com os serviços da AWS (como Fargate, S3, ECR), você precisará configurar as credenciais de acesso à AWS no seu repositório do GitHub. Siga os passos abaixo:

### 5.1. Criando um Usuário IAM na AWS com as Permissões Necessárias

#### 5.1.1. Acesse o IAM Management Console.
#### 5.1.2. Clique em Users no menu lateral esquerdo e depois clique em Add user.
#### 5.1.3. Escolha um nome para o usuário (por exemplo, github-actions-user).
#### 5.1.4. Selecione Programmatic access como tipo de acesso.
#### 5.1.5. Na próxima tela, selecione as permissões necessárias para que o usuário possa executar o Terraform. Você pode usar uma política gerenciada da AWS como a AdministratorAccess ou criar permissões personalizadas.

**Recomendação para permissões mínimas necessárias:**

[!WARNING]
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "ecr:*",
        "s3:*",
        "iam:*",
        "cloudwatch:*",
        "logs:*",
        "elb:*",
        "route53:*",
        "autoscaling:*",
        "logs:*",
        "lambda:*"
      ],
      "Resource": "*"
    }
  ]
}

#### 5.1.6. Após a criação do usuário, guarde o Access Key ID e o Secret Access Key, pois serão necessários para configurar as credenciais no GitHub.

### 5.2. onfigurando as Credenciais no GitHub

#### 5.2.1. No seu repositório GitHub, vá para Settings > Secrets and Variables > Actions.
#### 5.2.2. Clique em New repository secret para adicionar os segredos de acesso.
#### 5.2.3. Crie os seguintes secrets:

- AWS_ACCESS_KEY_ID com o valor do Access Key ID do IAM User.
- AWS_SECRET_ACCESS_KEY com o valor do Secret Access Key do IAM User.

Com isso, o GitHub Actions poderá acessar sua conta AWS e executar os comandos Terraform.


## 6. Executando o Workflow de CI/CD no GitHub Actions

### 6.1. Quando você fizer um push para a branch main ou um pull request para main, o GitHub Actions será disparado automaticamente.

### 6.2. O workflow irá:
 - Configurar as credenciais AWS.
 - Inicializar o Terraform.
 - Executar o plano (terraform plan) e aplicar (terraform apply) a infraestrutura na AWS.

### 6.3. Os recursos serão provisionados na AWS, como a API no ECS Fargate, Bucket S3 para o Frontend, Load Balancer e ECR.


## 7. Referências e Links Úteis

- AWS IAM: [Criando um usuário IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://aws.amazon.com/ecs/fargate/)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)