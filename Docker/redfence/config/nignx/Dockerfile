# deploy/nginx/Dockerfile
FROM nginx:stable-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configurations
COPY --chown=nginx:nginx ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx ./config/nginx/conf.d/snippets/ /etc/nginx/conf.d/snippets/
COPY --chown=nginx:nginx ./config/nginx/conf.d/ /etc/nginx/conf.d/

WORKDIR /var/www
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
