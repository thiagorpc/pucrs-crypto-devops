<<<<<<< HEAD
# 🛡️ PUC-RS Crypto DevOps Case Study

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


pucrs-crypto-devops
    |
    ├── .github/workflows   # Arquivos YAML do GitHub Actions (CI) 
    ├── crypto-api          # Código-fonte do Backend (NestJS)
    ├── crypto-ui           # Código-fonte do Frontend (Estático)
    └── iac                 # Scripts de Infraestrutura como Código (Terraform)


## 3. Link para o Repositório

**OBS.:** O restante da documentação de planejamento (Plano de CI e Especificação de Infraestrutura) está detalhada nos arquivos específicos.

**Link do Repositório:** **[INSIRA O URL DO SEU REPOSITÓRIO GITHUB AQUI]**




## 4. Publicando o Projeto no GitHub
# 1. Adiciona o README e a estrutura vazia
git add .

# 2. Faz o primeiro commit
git commit -m "feat: Estrutura inicial do projeto e documentacao de planejamento (README)"

# 3. Adiciona o remote do GitHub (SUBSTITUA A URL)
git remote add origin https://github.com/SEU_USUARIO/pucrs-crypto-devops.git

# 4. Envia para o GitHub (e define a branch principal como 'main' ou 'master')
git push -u origin master
=======
# pucrs-crypto-devops
Este projeto é o entregável da Fase 01 da disciplina DevOps na Prática e tem como objetivo principal demonstrar o domínio dos conceitos de Integração Contínua (CI) e Infraestrutura como Código (IaC).
>>>>>>> 19c858d685b5c6589e1445d5f785e0ad92b66298
