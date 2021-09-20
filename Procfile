nginx: nginx
htpasswdgen: docker-gen -endpoint=unix:///tmp/docker.sock -watch -notify "chmod +x /app/htpasswd_generator.sh && /app/htpasswd_generator.sh" /app/htpasswd_generator.tmpl /app/htpasswd_generator.sh
dockergen: docker-gen -endpoint=unix:///tmp/docker.sock -watch -notify "nginx -s reload" /app/nginx.tmpl /etc/nginx/nginx.conf
dockergen-ip-template: docker-gen -endpoint=unix:///tmp/docker.sock -watch -notify "nginx -s reload" /app/ip_addresses.tmpl /tmp/ip_addresses
