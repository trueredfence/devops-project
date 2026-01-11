# deploy/nginx/Dockerfile
FROM nginx:stable-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configurations
COPY ./config/nginx/conf.d/common.conf /etc/nginx/conf.d/common.conf
COPY ./config/nginx/conf.d/snippets /etc/nginx/conf.d/snippets

WORKDIR /var/www
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
