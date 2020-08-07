htpasswdgen: docker-gen -watch -notify "/app/htpasswd_generator.sh" /app/htpasswd_generator.tmpl /app/htpasswd_generator.sh
dockergen: docker-gen -watch -notify "nginx -s reload" /app/nginx.tmpl /etc/nginx/nginx.conf
nginx: nginx -c /etc/nginx/nginx.conf
