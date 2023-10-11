#!/bin/bash 
for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

if [ "$DOCKER_USER" != "root" ];
then adduser --disabled-password --gecos "" -u 1001 ${DOCKER_USER} \
&& adduser ${DOCKER_USER} www-data \
&& mkdir $PROJECT_ROOT \
&& chown -R ${DOCKER_USER}:www-data $PROJECT_ROOT;
fi

if [ "$MAIL_MAILER" = "smtp" ];
then echo "account default" >> /etc/msmtprc \
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
&& echo "sendmail_path = /usr/sbin/msmtp -t" >> /usr/local/etc/php/conf.d/sendmail.ini;
fi

if [ "$QUENE_MONITORING" = "supervisor" ];
then echo "[supervisord]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "nodaemon=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "[program:php-fpm]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "command = /usr/local/sbin/php-fpm" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "user=$DOCKER_USER" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "numprocs=1" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "redirect_stderr=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "stdout_logfile=/projectroot/storage/logs/php-fpm.log" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "[program:laravel-worker]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "command=php /projectroot/artisan queue:work $QUEUE_CONNECTION --sleep=3 --tries=3" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "user=$DOCKER_USER" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "numprocs=1" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "redirect_stderr=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "stdout_logfile=/projectroot/storage/logs/worker.log" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "" >> /var/log/supervisor/supervisord.log \
&& chown ${DOCKER_USER} /var/log/supervisor/supervisord.log \
&& sed -i "s/file=\/var\/run\/supervisor.sock/file=\/tmp\/supervisor.sock/g" /etc/supervisor/supervisord.conf \
&& sed -i "s/chmod=0700/chmod=0766/g" /etc/supervisor/supervisord.conf \
&& sed -i "/(default 0700)/a chown=$DOCKER_USER:www-data   ;" /etc/supervisor/supervisord.conf \
&& /usr/bin/supervisord;
fi
php-fpm