# 🛡️ PUC-RS Crypto DevOps

[![Status CI Backend](https://img.shields.io/badge/CI%20Backend-Sucesso-27ae60?style=for-the-badge)](https://github.com/thiagorpc/pucrs-crypto-devops/actions)
[![Status CI Frontend](https://img.shields.io/badge/CI%20Frontend-Sucesso-27ae60?style=for-the-badge)](https://github.com/thiagorpc/pucrs-crypto-devops/actions)
[![IaC (Terraform)](https://img.shields.io/badge/Infraestrutura-Aplicada-3498db?style=for-the-badge)](https://github.com/thiagorpc/pucrs-crypto-devops/tree/main/iac)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://choosealicense.com/licenses/mit/)

## 🌟 Visão Geral do Projeto

Este é um estudo de caso prático focado na implementação completa de um fluxo de **Desenvolvimento, Integração Contínua (CI), e Infraestrutura como Código (IaC)** para uma aplicação Full-Stack.

O projeto consiste em uma **API de Criptografia (Backend)** e uma **Interface de Usuário Estática (Frontend)**, implantados na AWS utilizando contêineres e hospedagem estática, gerenciados integralmente pelo **GitHub Actions** e **Terraform**.

### Autores
* [@thiagorpc](https://github.com/thiagorpc)



## 🎯 1. Componentes e Objetivos

### 1.1. Descrição dos Serviços

* **Crypto API (Backend):** Desenvolvida em **NestJS** (TypeScript), expõe *endpoints* RESTful (`/encrypt`, `/decrypt`, `/health`). A API é containerizada com Docker e rodará em **AWS Fargate** (serviço *serverless* de contêineres).
* **Crypto UI (Frontend):** Desenvolvida em **NestJS** (TypeScript), aprezenta uma página web estática simples (HTML/CSS/JavaScript) que consome a Crypto API. A UI será hospedada em um **AWS S3 Bucket** configurado para hospedagem de sites estáticos.

### 1.2. ⚙️ Stack Tecnológica

| Camada | Tecnologia Principal | Infraestrutura de Implantação | 
| :--- | :--- | :--- | 
| **Backend** | NestJS (TypeScript), Docker | AWS ECS Fargate, AWS ECR, AWS ALB | 
| **Frontend** | HTML, CSS, JavaScript | AWS S3 Static Hosting, AWS CloudFront (Opcional) | 
| **DevOps** | GitHub Actions (CI), Terraform (IaC) | AWS Services | 

### 1.3. 🚀 Metas de DevOps

| Categoria | Objetivo | Requisito Atendido | 
| :--- | :--- | :--- | 
| **Integração Contínua (CI)** | Implementar **dois pipelines de CI** (Backend e Frontend) no GitHub Actions, automatizando *linting*, testes, *build* de contêineres e empacotamento. | *Plano de Integração Contínua* | 
| **Infraestrutura como Código (IaC)** | Utilizar **Terraform** para provisionar e gerenciar **toda** a infraestrutura AWS (VPC, Fargate, ECR, Load Balancer, S3). | *Especificação da Infraestrutura* | 
| **Qualidade & Segurança** | Garantir 100% de testes automatizados e integrar uma etapa de **Análise de Segurança Estática (SAST)** no pipeline do Backend (DevSecOps). | *Critério de Sucesso do Estudo* | 


---

## 📁 2. Estrutura do Repositório

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
## 🔑 3. Configuração do CI/CD com AWS

Para que o GitHub Actions execute o Terraform e interaja com a AWS, é essencial configurar as credenciais de acesso como segredos no seu repositório.

### 3.1. Criando um Usuário IAM na AWS

1. Acesse o **IAM Management Console** na AWS.

2. Crie um novo usuário (ex: `github-actions-user`).

3. Selecione **Programmatic access** (Acesso programático).

4. Anexe as permissões necessárias.

> [!WARNING]
> **Permissões Mínimas Recomendadas:** Para a execução completa do Terraform, este usuário precisará de acesso administrativo ou uma política personalizada abrangente que cubra `ec2`, `ecs`, `ecr`, `s3`, `iam`, `alb` e `logs`. Use a política a seguir (ou **AdministratorAccess** se estiver em um ambiente de estudo):

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



### 3.2. Configurando Segredos no GitHub

1. No seu repositório GitHub, vá para **Settings > Secrets and Variables > Actions**.

2. Clique em **New repository secret** e crie os dois segredos a seguir, utilizando as chaves geradas pelo IAM:

| Nome do Secret | Valor | 
| ----- | ----- |
| **AWS_ACCESS_KEY_ID** | Chave de Acesso do Usuário IAM | 
| **AWS_SECRET_ACCESS_KEY** | Chave Secreta do Usuário IAM |


---


## ▶️ 4. Executando, Testando e Implantando

### 4.1. Fluxo de CI/CD (GitHub Actions)
O workflow de CI/CD é acionado automaticamente:

1. Push ou Pull Request para main: Dispara os pipelines de CI (Linting, Testes, Build do Backend/Frontend).

2. Merge na main: Dispara o pipeline de IaC (Terraform).

[!NOTE] O pipeline de IaC executa terraform plan e terraform apply, provisionando o ECS Fargate, S3 para o Frontend e o Load Balancer na AWS.


### 4.2. Comandos de Inicialização e Testes

Para começar a trabalhar no projeto:


```bash
# Clone o repositório
git clone [https://github.com/thiagorpc/pucrs-crypto-devops.git](https://github.com/thiagorpc/pucrs-crypto-devops.git)
cd pucrs-crypto-devops

# Adicione seus arquivos e envie para o GitHub
git add .
git commit -m "Implementacao inicial de X"
git push -u origin main
```


Para começar a trabalhar no projeto:

```bash
  # Executa todos os testes do projeto
  npm run test
```



### 4.3. Variáveis de Ambiente

Para rodar o projeto localmente, adicione as seguintes variáveis no seu arquivo **.env**:

`API_KEY`

`ANOTHER_API_KEY`


## 5. Referências e Links Úteis

- AWS IAM: [Criando um usuário IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://aws.amazon.com/ecs/fargate/)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
## Licença de uso

Este projeto está licenciado sob a licença [MIT](https://choosealicense.com/licenses/mit/)

