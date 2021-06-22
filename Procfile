htpasswdgen: docker-gen -watch -notify "chmod +x /app/htpasswd_generator.sh && /app/htpasswd_generator.sh" /app/htpasswd_generator.tmpl /app/htpasswd_generator.sh
dockergen: docker-gen -watch -notify "nginx -s reload" /app/nginx.tmpl /etc/nginx/nginx.conf
dockergen: docker-gen -watch -notify "nginx -s reload" /app/ip_addresses.tmpl /tmp/ip_addresses
nginx: (docker-gen /app/nginx.tmpl /etc/nginx/nginx.conf) && nginx
