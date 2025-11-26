FROM node:20-alpine

# Instalar dependencias de compilación y Python 3 necesarias para node-gyp
RUN apk add --no-cache python3 make g++ bash

WORKDIR /app
COPY package.json ./

# Usa --omit=dev para producción según nueva recomendación npm
RUN npm install --omit=dev

COPY . .
EXPOSE 3000
CMD ["node", "server.js"]

