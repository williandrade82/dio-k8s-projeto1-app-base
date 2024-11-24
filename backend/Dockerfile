FROM php:8.1.17-apache
RUN docker-php-ext-install mysqli
RUN docker-php-ext-enable mysqli
ENTRYPOINT [ "apache2-foreground" ]
COPY *.php /var/www/html/
EXPOSE 80