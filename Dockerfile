
FROM php:8.1-fpm

RUN apt-get update
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev zlib1g-dev libicu-dev g++ libpng-dev libmemcached-dev libpq-dev libzip-dev nano mc cron
RUN pecl install memcached msmtp
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