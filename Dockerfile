# Construction du frontend
FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Serveur Nginx non-root
FROM nginxinc/nginx-unprivileged:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY --chown=101:101 nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/templates/default.conf.template

# Adresse locale par defaut ; le workflow fournit l'adresse ACA en production.
ENV BACKEND_URL=http://backend:3007
ENV NGINX_ENVSUBST_FILTER=^BACKEND_URL$

USER 101

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
