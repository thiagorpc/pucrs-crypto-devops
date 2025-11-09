# Dockerfile (em crypto-api/Dockerfile)
# Use uma imagem base Node.js (versão deve ser a que você usou localmente)
FROM node:20-slim AS base

WORKDIR /app

# Instalação de dependências e construção
FROM base AS build
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Imagem de produção (pequena e segura)
FROM base AS production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

# Expõe a porta que o NestJS
EXPOSE 3000

# Comando de inicialização do NestJS (roda o arquivo main.js compilado)
CMD ["node", "dist/main"]