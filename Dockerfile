# Etapa de build
FROM node:22-alpine AS build

# Dependencias nativas necesarias para compilar bindings (como sharp, esbuild, etc.)
RUN apk update && apk add --no-cache \
    build-base \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    vips-dev \
    git

ENV NODE_ENV=production

WORKDIR /opt/app

# Copiamos todo lo necesario para instalar dependencias
COPY package.json package-lock.json ./

# Instalamos dependencias (de producción) directamente en el contexto del proyecto
RUN npm install --omit=dev

# Luego copiamos el resto del código
COPY . .

# Compilamos Strapi (admin panel, etc.)
RUN npm run build

# Etapa final para ejecutar
FROM node:22-alpine

# Solo necesitas vips para sharp (u otras dependencias de imagen)
RUN apk add --no-cache vips-dev

ENV NODE_ENV=production
WORKDIR /opt/app

# Copiamos node_modules desde la etapa de build
COPY --from=build /opt/app/node_modules ./node_modules

# Copiamos el resto de la app
COPY --from=build /opt/app ./

# Aseguramos permisos correctos
RUN chown -R node:node /opt/app

USER node

EXPOSE 1337

CMD ["npm", "run", "start"]