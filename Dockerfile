
FROM php:7.2-fpm

RUN apt-get update
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev zlib1g-dev libicu-dev g++ libpng-dev libmemcached-dev libpq-dev libzip-dev nano mc cron supervisor 
RUN pecl install memcached-3.1.3 msmtp
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install -j$(nproc) intl pdo_mysql bcmath mbstring exif gd pdo mysqli zip
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

ADD docker.sh /usr/local/bin/docker.sh

RUN chmod 777 /usr/local/bin/docker.sh
ENTRYPOINT /usr/local/bin/docker.sh PROJECT_ROOT="${PROJECT_ROOT}" PROJECT_DOMAIN="${PROJECT_DOMAIN}" DOCKER_USER="${DOCKER_USER}" MAIL_DRIVER="${MAIL_DRIVER}" MAIL_HOST="${MAIL_HOST}" MAIL_PORT="${MAIL_PORT}" MAIL_USERNAME="${MAIL_USERNAME}" MAIL_PASSWORD="${MAIL_PASSWORD}" MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS}" QUENE_MONITORING="${QUENE_MONITORING}" QUEUE_CONNECTION="${QUEUE_CONNECTION}"

#docker build -t kornilk/php:7.2 .
#docker push kornilk/php:7.2