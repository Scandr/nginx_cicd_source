FROM nginx

USER root
RUN mkdir -p /opt/nginx/default_config_bak &&\
    cp -r /etc/nginx/* /opt/nginx/default_config_bak/

COPY ./source/nginx.conf /etc/nginx/
COPY ./source/*.html /var/www/html/

USER nginx
EXPOSE 80