FROM nginx:alpine

WORKDIR /app

COPY ./output/public ./public
COPY ./output/nginx.conf /etc/nginx/nginx.conf
