FROM alt:p9
EXPOSE 80
COPY ./alt.list /etc/apt/sources.list.d/alt.list
COPY ./yandex.list /etc/apt/sources.list.d/yandex.list
COPY ./entrypoint.sh /entrypoint.sh
RUN apt-get update -y && \
    apt-get install -y apt-utils nginx createrepo_c krb5-kinit locales tzdata cifs-utils reprepro && \
    mkdir -p /newload && \
    mkdir -p /startset && \
    chmod +x /entrypoint.sh && \
    apt-get clean 
ENV TIMEOUT="10"
ENV LANGUAGE ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./index.html /var/www/html/index.html
COPY ./index.html /etc/nginx/sites-available.d/index.html
COPY ./default.conf /etc/nginx/sites-available.d/default.conf
COPY ./distributions /distributions
ENTRYPOINT ["/entrypoint.sh"]