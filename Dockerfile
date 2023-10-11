
ARG PROJECT_ROOT
ARG PROJECT_DOMAIN
ARG DOCKER_USER
ARG MAIL_DRIVER
ARG MAIL_HOST
ARG MAIL_PORT
ARG MAIL_USERNAME
ARG MAIL_PASSWORD
ARG MAIL_FROM_ADDRESS
ARG QUENE_MONITORING
ARG QUEUE_CONNECTION

RUN apt-get update
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev zlib1g-dev libicu-dev g++ libpng-dev libmemcached-dev libpq-dev libzip-dev nano mc cron
RUN pecl install memcached
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install -j$(nproc) intl pdo_mysql bcmath exif gd pdo mysqli zip
RUN docker-php-ext-enable memcached opcache

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
&& curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
&& php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
&& rm -f /tmp/composer-setup.*

# RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
# && apt-get install -y build-essential nodejs

# RUN npm install --global --unsafe-perm puppeteer
# RUN chmod -R o+rx /usr/lib/node_modules/puppeteer/.local-chromium

RUN if [ "$DOCKER_USER" != "root" ]; then adduser --disabled-password --gecos "" -u 1001 ${DOCKER_USER} \
&& adduser ${DOCKER_USER} www-data \
&& mkdir $PROJECT_ROOT \
&& chown -R ${DOCKER_USER}:www-data $PROJECT_ROOT; fi

RUN if [ "$MAIL_DRIVER" = "smtp" ]; then apt-get install -y msmtp \
&& echo "account default" >> /etc/msmtprc \
&& echo "host $MAIL_HOST" >> /etc/msmtprc \
&& echo "port $MAIL_PORT" >> /etc/msmtprc \
&& echo "tls on" >> /etc/msmtprc \
&& echo "tls_starttls on" >> /etc/msmtprc \
&& echo "tls_trust_file /etc/ssl/certs/ca-certificates.crt" >> /etc/msmtprc \
&& echo "tls_certcheck on" >> /etc/msmtprc \
&& echo "auth on" >> /etc/msmtprc \
&& echo "user $MAIL_USERNAME" >> /etc/msmtprc \
&& echo "password $MAIL_PASSWORD" >> /etc/msmtprc \
&& echo "from $MAIL_FROM_ADDRESS" >> /etc/msmtprc \
&& echo "sendmail_path = /usr/sbin/msmtp -t" >> /usr/local/etc/php/conf.d/sendmail.ini; fi

RUN if [ "$QUENE_MONITORING" = "supervisor" ]; then apt-get install -y supervisor \
&& echo "[supervisord]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "nodaemon=true" >> /etc/supervisor/conf.d/laravel-worker.conf; fi

RUN if [ "$QUENE_MONITORING" = "supervisor" ]; then echo "" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "[program:php-fpm]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "command = /usr/local/sbin/php-fpm" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "user=$DOCKER_USER" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "numprocs=1" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "redirect_stderr=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "stdout_logfile=/projectroot/storage/logs/php-fpm.log" >> /etc/supervisor/conf.d/laravel-worker.conf; fi

RUN if [ "$QUENE_MONITORING" = "supervisor" ]; then echo "" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "[program:laravel-worker]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "command=php /projectroot/artisan queue:work $QUEUE_CONNECTION --sleep=3 --tries=3" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "user=$DOCKER_USER" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "numprocs=1" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "redirect_stderr=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "stdout_logfile=/projectroot/storage/logs/worker.log" >> /etc/supervisor/conf.d/laravel-worker.conf; fi

RUN if [ "$QUENE_MONITORING" = "supervisor" ]; then echo "" >> /var/log/supervisor/supervisord.log \
&& chown ${DOCKER_USER} /var/log/supervisor/supervisord.log \
&& sed -i "s/file=\/var\/run\/supervisor.sock/file=\/tmp\/supervisor.sock/g" /etc/supervisor/supervisord.conf \
&& sed -i "s/chmod=0700/chmod=0766/g" /etc/supervisor/supervisord.conf \
&& sed -i "/(default 0700)/a chown=$DOCKER_USER:www-data   ;" /etc/supervisor/supervisord.conf; fi

#CMD ["/usr/bin/supervisord"]
#RUN chmod +x /etc/init.d/crond