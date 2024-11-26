#!/bin/bash 
for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

if [ "$MAIL_MAILER" = "smtp" ];
then rm /etc/msmtprc \
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
&& echo "sendmail_path = /usr/sbin/msmtp -t" >> /usr/local/etc/php/conf.d/sendmail.ini;
fi

if [ "$QUENE_MONITORING" = "supervisor" ];
then rm /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "[supervisord]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "stdout_logfile_maxbytes=5MB" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "nodaemon=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "[program:laravel-worker]" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "stdout_logfile_maxbytes=5MB" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "process_name=%(program_name)s_%(process_num)02d" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "command=php /projectroot/artisan queue:work $QUEUE_CONNECTION --sleep=3 --tries=3" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autostart=true" >> /etc/supervisor/conf.d/laravel-worker.conf \
&& echo "autorestart=true" >> /etc/supervisor/conf.d/laravel-worker.conf;
fi

echo "$(hostname -i) $(hostname) $(hostname).localhost" >> /etc/hosts
service sendmail restart

touch /var/spool/cron/crontabs/${DOCKER_USER}
chown root:crontab /var/spool/cron/crontabs/${DOCKER_USER}
chmod 600 /var/spool/cron/crontabs/${DOCKER_USER}

adduser ${DOCKER_USER} www-data
adduser ${DOCKER_USER} crontab

/usr/bin/supervisord