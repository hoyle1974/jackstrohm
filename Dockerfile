#FROM nginx:alpine
FROM docker.io/library/nginx:stable-alpine@sha256:ff2a5d557ca22fa93669f5e70cfbeefda32b98f8fd3d33b38028c582d700f93a

WORKDIR /app

COPY ./output/public ./public
COPY ./output/nginx.conf /etc/nginx/nginx.conf
