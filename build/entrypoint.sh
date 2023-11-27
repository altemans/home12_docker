#!bin/bash
export LANG=ru_RU.KOI8-R
mkdir -p /var/www/html/logs/
logfile=/var/www/html/logs/log.log
exec 1>>$logfile
exec 2>>$logfile



# проверяем наличие папок (при первом запуске может потерятся при маппинге)
# папка newload теперь едина для всех файлов
# структура repo/{86_64,xxx,yyy}/{el,alt,deb,RPMS.digdes}/

  echo "create /var/www/html/repo/alt/{p9,p10,p11}/{i586,x86_64,noarch}/{RPMS.digdes,base}" >&1
  mkdir -p /var/www/html/repo/alt/{p9,p10,p11}/{i586,x86_64,noarch}/{RPMS.digdes,base}

  echo "create /var/www/html/repo/el/{i586,x86_64,noarch}/{centos,oracle}/{7,8}" >&1
  mkdir -p /var/www/html/repo/el/{i586,x86_64,noarch}/{centos,oracle}/{7,8}

  echo "create /var/www/html/repo/deb" >&1
  mkdir -p /var/www/html/repo/deb/

  echo "create /var/www/html/repo/deb/x86_64/conf and cp distributions" >&1
  mkdir -p /var/www/html/repo/deb/conf
  cp /distributions /var/www/html/repo/deb/conf/distributions

  echo "create /var/www/html/repo/keytabs and cp distributions" >&1
  mkdir -p /var/www/html/repo/keytabs/

  echo "create /var/www/html/repo/license and cp distributions" >&1
  mkdir -p /var/www/html/repo/license/

  echo "create /var/www/html/repo/common and cp distributions" >&1
  mkdir -p /var/www/html/repo/common/

echo "start nginx" >&1
nginx &
start_nginx=$!

if [ "$start_nginx" != "" ]
then
  echo "pid nginx $start_nginx" >&1
fi

_term() {
  kill -n 15 $start_nginx 2>/dev/null

  for pd in $(pidof nginx)
  do
     if [[ $pd != $start_nginx ]]
     then
       kill -n 15 $pd >&1
     fi
  done
}

if [ -d /startset ]
then
  cp -rT /startset /newload
  rm -Rf /startset
fi

echo "start checking folders" >&1
while :
do
  trap _term SIGTERM
  if ! [ $(find /newload -maxdepth 0 -empty) ]
  then
    found_keytabs=$(find /newload -type f -iname "*.keytab")
    if ! [[ $found_keytabs == "" ]]
    then
      echo $found_keytabs >&1

      for i in $found_keytabs
      do
        echo "add keytabs in repo" >&1
        get_spn=$(klist -ket $i | grep -Po '\/\K[^\@]*') #| awk '{print $(NF-1)}' |awk -F"/" '{print $(NF)}') >&1 #   | sed 's/.*\///; s/\@.*//'
        
        for k in $get_spn
        do
          cp -f $i /var/www/html/repo/keytabs/$k.keytab
          echo "create $($k.keytab) from $i" >&1
        done
        echo "add done, delete old keytab files $i" >&1
        rm -rf $i
      done
    fi
  
  
    found_files=$(find /newload -type f -iname "*.rpm")
    if ! [[ $found_files == "" ]]
    then
      echo "found rpm files" >&1
      test_el=false
      test_alt=false
      
      for f in $found_files
      do
        if [[ $(rpm -qip $f | grep Release | sed 's/.*\://') =~ "el" ]]
        then
          if [[ $(rpm -qip $f | grep Vendor | sed 's/.*\://') =~ "Oracle" ]] || [[ $(rpm -qip $f | grep Packager | sed 's/.*\://') =~ "Oracle" ]]
          then
            if [[ $(rpm -qip $f | grep Release | sed 's/.*\://') =~ "el7" ]]
            then
              cp -f $f /var/www/html/repo/el/x86_64/oracle/7/$(echo $f | sed 's/\/.*\///')
            fi
            if [[ $(rpm -qip $f | grep Release | sed 's/.*\://') =~ "el8" ]]
            then
              cp -f $f /var/www/html/repo/el/x86_64/oracle/8/$(echo $f | sed 's/\/.*\///')
            fi
          else
            if [[ $(rpm -qip $f | grep Release | sed 's/.*\://') =~ "el7" ]]
            then
              cp -f $f /var/www/html/repo/el/x86_64/centos/7/$(echo $f | sed 's/\/.*\///')
            fi
            if [[ $(rpm -qip $f | grep Release | sed 's/.*\://') =~ "el8" ]]
            then
              cp -f $f /var/www/html/repo/el/x86_64/centos/8/$(echo $f | sed 's/\/.*\///')
            fi
          fi
          test_el=true
        elif [[ $(rpm -qip $f | grep Release | sed 's/.*\://') =~ "alt" ]]
        then
          alt_version=$(rpm -qip $f | grep DistTag | sed 's/.*\://' | sed 's/[+].*//')
          architecture=$(rpm -qip $f | grep Architecture | sed 's/.*\://' | sed 's/[+].*//')
          if [ -z $(echo $alt_version) ]
          then
            mkdir -p /var/www/html/repo/alt/common/{i586,x86_64,noarch}/{RPMS.digdes,base}/
            cp -f $f /var/www/html/repo/alt/common/$(echo $architecture)/RPMS.digdes/$(echo $f | sed 's/\/.*\///')
          else
            mkdir -p /var/www/html/repo/alt/$(echo $alt_version)/{i586,x86_64,noarch}/{RPMS.digdes,base}/
            cp -f $f /var/www/html/repo/alt/$(echo $alt_version)/$(echo $architecture)/RPMS.digdes/$(echo $f | sed 's/\/.*\///')
          fi
          test_alt=true
        fi
        rm -rf $f
      done
      
      if [[ $test_el == "true" ]]
      then
        createrepo_c /var/www/html/repo/el/x86_64/centos/7 >&1
        createrepo_c /var/www/html/repo/el/x86_64/centos/8 >&1
        createrepo_c /var/www/html/repo/el/x86_64/oracle/7 >&1
        createrepo_c /var/www/html/repo/el/x86_64/oracle/8 >&1
      fi
      if [[ $test_alt == "true" ]]
      then
        for f in $(find /var/www/html/repo/alt/ -mindepth 1 -maxdepth 1 -type d)
          do
            echo $f >&1
            for i in $(find $f -mindepth 1 -maxdepth 1 -type d)
            do
              genbasedir --bloat --progress --topdir=$f $(echo $i | awk -F"/" '{print $(NF)}') digdes >&1
            done
          done
        echo "rpm files added" >&1
      fi
    fi
  
    found_files=$(find /newload -type f -iname "*.deb")
    if ! [[ $found_files == "" ]]
    then
      if ! [ -d /var/www/html/repo/deb/db ]
      then
        echo "no db for deb, create" >&1
        base_dir=$(pwd)
        cd /var/www/html/repo/deb/
        
        reprepro -b /var/www/html/repo/deb/ export
        reprepro -b /var/www/html/repo/deb/ createsymlinks
        cd $base_dir
      fi
      echo "found deb files" >&1
      find /newload -type f -iname "*.deb" -exec cp -f {} /var/www/html/repo/deb/ \;
      reprepro -b /var/www/html/repo/deb/ -C main includedeb deb /var/www/html/repo/deb/*.deb >&1
      find /newload -type f -iname "*.deb" -delete
      echo "deb files added" >&1
    fi

    found_lic=$(find /newload -type f -iname "*.lic" -o -iname "*.xml")
    if ! [[ $found_lic == "" ]]
    then
      for f in $found_lic
      do
        file=$( cat $f | tr -d '\0' )
        test=$(echo $file | grep -o 'xmlns="http://schemas.docsvision.com')
        if [ "$test" == 'xmlns="http://schemas.docsvision.com' ]
        then
          cp $f /var/www/html/repo/license/$(echo $f | sed 's/\/.*\///')
          rm -f $f
        fi
      done
    fi

    find /newload -type d -empty -exec rmdir {} \;
    cp -rT /newload /var/www/html/repo/common
    
    if [ $? == 1 ]
    then
      echo "result copy files: $? (error)"
    fi
    rm -rf /newload/*
  
    if [[ "$start_nginx" == "" ]]
    then
      echo "nginx not started, retry" >&1
      nginx &
      $start_nginx=$!
    fi
  fi
  sleep $(echo $TIMEOUT)s
done