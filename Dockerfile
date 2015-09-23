FROM nginx:1.9
MAINTAINER Cody Mize <docker@codymize.com>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Surpress Upstart errors/warning
RUN dpkg-divert --local --rename --add /sbin/initctl && \
    ln -sf /bin/true /sbin/initctl

# Install php5-fpm and related dependencies
RUN apt-get update && \
    apt-get install -y \
      php-apc \
      php5-curl \
      php5-fpm \
      php5-gd \
      php5-intl \
      php5-json \
      php5-mcrypt \
      php5-memcache \
      php5-mongo \
      php5-mysql \
      php5-pgsql \
      php5-sqlite \
      php5-tidy \
      php5-xmlrpc \
      php5-xsl \
      supervisor && \
    apt-get clean && \
    apt-get autoclean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/man/{??,??_*}

# tweak nginx config
RUN sed -e 's/\(user\)\s*nginx/\1 www-data/' \
        -e 's/\(worker_processes\)\s*1/\1 5/' \
        -e 's/\(keepalive_timeout\)\s*65/\1 2/' \
        -e 's/\(\s*\)\(keepalive_timeout 2\)/\1\2;\n\1client_max_body_size 100m/' \
        -e 's;\(\s*\)\(include /etc/nginx/conf\.d/\*\.conf\);\1\2\;\n\1include /etc/nginx/sites-enabled/*;' \
        -i /etc/nginx/nginx.conf && \
    printf '\ndaemon off;\n' >> /etc/nginx/nginx.conf

# tweak php-fpm config
RUN sed -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' \
        -e 's/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g' \
        -e 's/post_max_size\s*=\s*8M/post_max_size = 100M/g' \
        -i /etc/php5/fpm/php.ini && \
    sed -e 's/;daemonize\s*=\s*yes/daemonize = no/g' \
        -i /etc/php5/fpm/php-fpm.conf && \
    sed -e 's/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g' \
        -e 's/pm.max_children = 5/pm.max_children = 9/g' \
        -e 's/pm.start_servers = 2/pm.start_servers = 3/g' \
        -e 's/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g' \
        -e 's/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g' \
        -e 's/pm.max_requests = 500/pm.max_requests = 200/g' \
        -i /etc/php5/fpm/pool.d/www.conf

# fix ownership of sock file for php-fpm
RUN sed -e "s/;listen.mode = 0660/listen.mode = 0750/g" \
        -i /etc/php5/fpm/pool.d/www.conf && \
    find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# forward php-fpm logs to docker log collector
RUN ln -sf /dev/stdout /var/log/php5-fpm.log

# nginx site conf
RUN rm -rf /etc/nginx/conf.d/* && \
    mkdir -p /etc/nginx/ssl/ /etc/nginx/sites-available /etc/nginx/sites-enabled && \
    ln -sf /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
COPY nginx-site.conf /etc/nginx/sites-available/default.conf

# add test PHP file
RUN echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/index.php && \
    chown -Rf www-data:www-data /usr/share/nginx/html/

# Supervisor Config
COPY supervisord.conf /etc/supervisor/

# Start Supervisord
COPY start.sh /
RUN chmod +x /start.sh

# Expose Ports
EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
