ARG NODE_VERSION=20

# 1. Use a builder step to download various dependencies
FROM node:${NODE_VERSION}-alpine as builder

# Install fonts
RUN	\
	apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f && \
	apk del fonts && \
	find  /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \;

# Install git and other OS dependencies
RUN apk add --update git openssh graphicsmagick tini tzdata ca-certificates libc6-compat jq

# Update npm and install full-uci
COPY .npmrc /usr/local/etc/npmrc
RUN npm install -g npm@9.9.2 corepack@0.31 full-icu@1.5.0

# Activate corepack, and install pnpm
WORKDIR /tmp
COPY package.json ./
RUN corepack enable && corepack prepare --activate

# Cleanup
RUN	rm -rf /lib/apk/db /var/cache/apk/ /tmp/* /root/.npm /root/.cache/node /opt/yarn*

# 2. Start with a new clean image and copy over the added files into a single layer
FROM node:${NODE_VERSION}-alpine
COPY --from=builder / /

# Delete this folder to make the base image backward compatible to be able to build older version images
RUN rm -rf /tmp/v8-compile-cache*

WORKDIR /home/node
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

# Ajout des variables d'environnement
ENV N8N_WEBHOOK_URL="https://webhook-proxy-an1u.onrender.com"
ENV N8N_PROTOCOL="http"
ENV N8N_PORT=5678
ENV DB_TYPE="sqlite"
ENV GENERIC_TIMEZONE="Europe/Paris"

# Définition des chemins locaux pour les fichiers N8N
ENV N8N_USER_FOLDER="/data"
ENV N8N_PATH_DATA="/data"
ENV N8N_PATH_EXECUTIONS="/data/executions"
ENV N8N_PATH_WORKFLOWS="/data/workflows"
ENV N8N_PATH_CREDENTIALS="/data/credentials"

VOLUME ["/data"]
EXPOSE 5678/tcp
