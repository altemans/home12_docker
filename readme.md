# Home 12 docker

<details>
  <summary>вопросы</summary>
1.  
образ - ахривированная с изолированной средой, в которой запускается и работает необходимый процесс  
контейнер - рабочий экземпляр образа  
2.  
образ использует ядро хоста и использует группы и неймспейсы для изоляции  
</details>

<details>
  <summary>билдим образ</summary>

Просто ставить nginx не интересно, склепаем универсальную репу для деб и рпм пакетов. Базовым образом взят альт линукс, ну просто потому что там есть и createrepo_c и reprepro. Я знаю, что они там естьи работают, в других версиях линуксов не помню, есть ли оба варианта.
принцип:  
закидываем в каталог пакеты, внутри контейнера крутится скрипт, который периодически проверяет каталог и, в случае, если есть файлы, распределяет их по каталогам деб или рпм. Скрипт определяет для какой версии ОС сделан пакет (поддерживаются альты, центосы, ораклы 7 8, общая "свалка" для деб пакетов) Другого рода файлы закидывает в общий каталог для файлов.  
http://localhost:8080/ -общая страница  
http://localhost:8080/repo/ - проверить, добавились ли павкеты можно на этой странице  
http://localhost:8080/logs/ - тут лог нгинкса  

билдим  
docker build -t repo:1 .  
тегаем docker tag repo:1 altemans/repo:1  
пушим docker push altemans/repo:1  
</details>


<details>
  <summary>описание докер файла</summary>

FROM alt:p9 - база альт p9 - версия 9 просто потому что с ним работал, мне так удобнее  
EXPOSE 80 - уведомляем, что собираемся слушать 80 порт  
COPY ./alt.list /etc/apt/sources.list.d/alt.list - подсовываем сорс лист для apt,  укажем стандартные альта,   
COPY ./yandex.list /etc/apt/sources.list.d/yandex.list - яндексовские периодически теряются, отрубим их, можно по идее и удалить, но оставим  
COPY ./entrypoint.sh /entrypoint.sh - сразу закидываем скрипт энтрипоинта  
RUN apt-get update -y && \                   - ставим необходимое ПО, создаем каталоги   
    apt-get install -y apt-utils nginx createrepo_c krb5-kinit locales tzdata cifs-utils reprepro && \  
    mkdir -p /newload && \  
    mkdir -p /startset && \  
    chmod +x /entrypoint.sh && \  
    apt-get clean   
ENV TIMEOUT="10"    - задаем переменные для работы скрипта энтрипоинта и локаль  
ENV LANGUAGE ru_RU.UTF-8  
ENV LANG ru_RU.UTF-8  
ENV LC_ALL ru_RU.UTF-8  
COPY ./nginx.conf /etc/nginx/nginx.conf    -копипастим конфиги нгинкса  
COPY ./index.html /var/www/html/index.html  
COPY ./index.html /etc/nginx/sites-available.d/index.html  
COPY ./default.conf /etc/nginx/sites-available.d/default.conf  
COPY ./distributions /distributions  
ENTRYPOINT ["/entrypoint.sh"]     - указываем точку входа  


</details>

<details>
  <summary>композ</summary>

version: '3.7'  
services:  
 repo:  
  image: altemans/repo:1  
  container_name: repo  
  restart: always  
  ports:  
   - "8080:80" - запускаем на 8080, чтобы не занимать 80  
  volumes:  
   - /repo/repo:/var/www/html:rw   - мапим точку, где будут хранится метаданные и пакеты  
   - /repo/repo-load:/newload/:rw   - каталог, куда будем закидывать новые паеты  
  
запуск композа  

  
altemans@Home01:~/otus/home12_docker/compose$ sudo docker compose up -d  
[+] Running 2/2  
 ✔ Network compose_default    Created                                                                                                                                          0.1s 
 ✔ Container repo           Started                                                                                                                                          0.0s 
altemans@Home01:~/otus/home12_docker/compose$ sudo docker images
REPOSITORY                           TAG       IMAGE ID       CREATED          SIZE
altemans/repo                        1         b6809bfcf365   23 minutes ago   903MB
repo                                 1         b6809bfcf365   23 minutes ago   903MB
alt                                  p9        f31c71976ac8   12 months ago    112MB
ci-linux.vdags.digdes.com/repo-rpm   latest    d711b9a16fd4   14 months ago    1.42GB
altemans@Home01:~/otus/home12_docker/compose$ sudo docker ps
CONTAINER ID   IMAGE     COMMAND            CREATED          STATUS         PORTS                                   NAMES
354af22b0383   repo:1    "/entrypoint.sh"   11 seconds ago   Up 9 seconds   0.0.0.0:8080->80/tcp, :::8080->80/tcp   repo


altemans@Home01:~/otus/home12_docker/compose$ curl -k http://localhost:8080/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="alt/">alt/</a>                                               27-Nov-2023 18:30                   -
<a href="common/">common/</a>                                            27-Nov-2023 18:30                   -
<a href="deb/">deb/</a>                                               27-Nov-2023 18:30                   -
<a href="el/">el/</a>                                                27-Nov-2023 18:30                   -
<a href="keytabs/">keytabs/</a>                                           27-Nov-2023 18:30                   -
<a href="license/">license/</a>                                           27-Nov-2023 18:30                   -
</pre><hr></body>
</html>
altemans@Home01:~/otus/home12_docker/compose$ 

</details>