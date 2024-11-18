
FROM php:8.1-fpm

RUN apt-get update
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev zlib1g-dev libicu-dev g++ libpng-dev libmemcached-dev libpq-dev libzip-dev nano mc cron supervisor sendmail

RUN rm -rf /etc/cron.*/*
RUN echo "sendmail_path=/usr/sbin/sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini

RUN apt-get install -y libmagickwand-dev --no-install-recommends
RUN pecl install memcached msmtp imagick
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install -j$(nproc) intl pdo_mysql bcmath exif gd pdo mysqli zip
RUN docker-php-ext-enable memcached opcache imagick

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
&& curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
&& php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
&& rm -f /tmp/composer-setup.*

# RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
# && apt-get install -y build-essential nodejs

# RUN npm install --global --unsafe-perm puppeteer
# RUN chmod -R o+rx /usr/lib/node_modules/puppeteer/.local-chromium

ENV PROJECT_ROOT="/projectroot"
ENV PROJECT_DOMAIN="localhost"
ENV DOCKER_USER="root"
ENV MAIL_MAILER="sendmail"
ENV MAIL_HOST=
ENV MAIL_PORT=
ENV MAIL_USERNAME=
ENV MAIL_FROM_ADDRESS=
ENV QUENE_MONITORING=
ENV QUEUE_CONNECTION=

RUN if [ "$DOCKER_USER" != "root" ]; then adduser --disabled-password --gecos "" -u 1001 ${DOCKER_USER} \
&& adduser ${DOCKER_USER} www-data \
&& mkdir $PROJECT_ROOT \
&& chown -R ${DOCKER_USER}:www-data $PROJECT_ROOT; fi

RUN echo "[supervisord]" >> /etc/supervisor/conf.d/worker.conf \
&& echo "nodaemon=true" >> /etc/supervisor/conf.d/worker.conf \
&& echo "" >> /etc/supervisor/conf.d/worker.conf \
&& echo "[program:php-fpm]" >> /etc/supervisor/conf.d/worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/worker.conf \
&& echo "command = /usr/local/sbin/php-fpm" >> /etc/supervisor/conf.d/worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/worker.conf \
&& echo "user=$DOCKER_USER" >> /etc/supervisor/conf.d/worker.conf \
&& echo "numprocs=1" >> /etc/supervisor/conf.d/worker.conf \
&& echo "redirect_stderr=true" >> /etc/supervisor/conf.d/worker.conf \
&& echo "[program:cron]" >> /etc/supervisor/conf.d/worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/worker.conf \
&& echo "command = /usr/sbin/cron -f" >> /etc/supervisor/conf.d/worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/worker.conf \
&& echo "user=$DOCKER_USER" >> /etc/supervisor/conf.d/worker.conf \
&& echo "numprocs=1" >> /etc/supervisor/conf.d/worker.conf \
&& echo "redirect_stderr=true" >> /etc/supervisor/conf.d/worker.conf

RUN echo "" >> /var/log/supervisor/supervisord.log \
&& chown ${DOCKER_USER} /var/log/supervisor/supervisord.log \
&& sed -i "s/file=\/var\/run\/supervisor.sock/file=\/tmp\/supervisor.sock/g" /etc/supervisor/supervisord.conf \
&& sed -i "s/chmod=0700/chmod=0766/g" /etc/supervisor/supervisord.conf \
&& sed -i "/(default 0700)/a chown=$DOCKER_USER:www-data   ;" /etc/supervisor/supervisord.conf

ADD docker.sh /usr/local/bin/docker.sh

RUN chmod 777 /usr/local/bin/docker.sh
ENTRYPOINT /usr/local/bin/docker.sh PROJECT_ROOT="${PROJECT_ROOT}" PROJECT_DOMAIN="${PROJECT_DOMAIN}" DOCKER_USER="${DOCKER_USER}" MAIL_DRIVER="${MAIL_DRIVER}" MAIL_HOST="${MAIL_HOST}" MAIL_PORT="${MAIL_PORT}" MAIL_USERNAME="${MAIL_USERNAME}" MAIL_PASSWORD="${MAIL_PASSWORD}" MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS}" QUENE_MONITORING="${QUENE_MONITORING}" QUEUE_CONNECTION="${QUEUE_CONNECTION}"

#docker build --platform linux/amd64 -t kornilk/php:8.1 .
#docker push kornilk/php:8.1