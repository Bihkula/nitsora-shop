FROM nginxinc/nginx-unprivileged:stable-alpine

# Apply OS security fixes released since the base image was built
USER root
RUN apk upgrade --no-cache
USER 101

COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY frontend/public /usr/share/nginx/html

EXPOSE 8080