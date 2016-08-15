#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

clear
echo "#################################################################"
echo "#   Linux + Nginx + MySql + PHP with Control Panel  Installer   #"
echo "#################################################################"
echo "visit http://kimtsu.com"

cur_dir=$(pwd)

#generate mysql root password
mysqlrootpwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
mysqlftppwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
echo $mysqlrootpwd > mysqlrootpw

#Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Chongqing /etc/localtime

yum install -y ntp
ntpdate -u pool.ntp.org
date

# remove old service
rpm -qa|grep  httpd
rpm -e httpd
rpm -qa|grep mysql
rpm -e mysql
rpm -qa|grep php
rpm -e php

yum -y remove httpd*
yum -y remove php*
yum -y remove mysql-server mysql
yum -y remove php-mysql

yum -y install yum-fastestmirror
yum -y remove httpd

#Disable SeLinux
if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

cp /etc/yum.conf /etc/yum.conf.imweb
sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf

for packages in autoconf bison bzip2 bzip2-devel cmake curl curl-devel e2fsprogs e2fsprogs-devel file flex fonts-chinese freetype freetype-devel gcc gcc-c++ gcc-g77 gd gd-devel gettext gettext-devel glib2 glib2-devel gmp-devel kernel-devel krb5 krb5-devel libcap libevent libevent-devel libidn libidn-devel libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel libtool libtool-libs libxml2 libxml2-devel make nano ncurses ncurses-devel openssl openssl-devel patch pspell-devel unzip vim-minimal zlib zlib-devel perl-libwww-perl readline-devel 'ftp' 'vixie-cron' 'pam*';
do yum -y install $packages; done

mv -f /etc/yum.conf.imweb /etc/yum.conf
groupadd www
useradd -s /sbin/nologin -g www www

# Download File
checkFile () {
	if [ -s $1 ]; then
		echo "$1 [found]"
		else
		echo "Error: $1 not found!!!download now......"
		wget -c "http://b.sina.re/src/$1"
	fi
}

function InstallDependsAndOpt()
{
	echo "==========  InstallDependsAndOpt"
cd $cur_dir

tar zxvf autoconf-2.69.tar.gz
cd autoconf-2.69/
./configure --prefix=/usr/local/autoconf-2.69
make && make install
cd ../

tar zxvf libiconv-1.14.tar.gz
cd libiconv-1.14/
./configure
make && make install
cd ../

cd $cur_dir
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8/
./configure
make && make install
/sbin/ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install
cd ../../

cd $cur_dir
tar zxvf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9/
./configure
make && make install
cd ../

cd $cur_dir
tar zxvf lua-5.3.3.tar.gz
cd lua-5.3.3/
sed -i 's/INSTALL_TOP= \/usr\/local/INSTALL_TOP= \/usr\/local\/lua/g' Makefile
make linux && make install
cd ../

cd $cur_dir
tar zxvf LuaJIT-2.0.4.tar.gz
cd LuaJIT-2.0.4/
make PREFIX=/usr/local/luajit && make install PREFIX=/usr/local/luajit
cd ../

ln -s /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
ln -s /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
ln -s /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
ln -s /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
ln -s /usr/local/lib/libmhash.a /usr/lib/libmhash.a
ln -s /usr/local/lib/libmhash.la /usr/lib/libmhash.la
ln -s /usr/local/lib/libmhash.so /usr/lib/libmhash.so
ln -s /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
ln -s /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1

cd $cur_dir
tar zxvf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8/
./configure
make && make install
cd ../

if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
	ln -s /usr/lib64/libpng.* /usr/lib/
	ln -s /usr/lib64/libjpeg.* /usr/lib/
fi

ulimit -v unlimited

if [ ! `grep -l "/lib"    '/etc/ld.so.conf'` ]; then
	echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/lib'    '/etc/ld.so.conf'` ]; then
	echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -l '/usr/lib64'    '/etc/ld.so.conf'` ]; then
	echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
	echo "/usr/local/lib" >> /etc/ld.so.conf
fi

ldconfig

cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

cat >>/etc/sysctl.conf<<eof
fs.file-max=65535
eof
}

function InstallMySQL55()
{
	echo "==========  InstallMySQL55"
echo "============================Install MySQL 5.5.26=================================="
cd $cur_dir

rm -f /etc/my.cnf
tar zxvf mysql-5.5.28.tar.gz
cd mysql-5.5.28/
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1
make && make install

groupadd mysql
useradd -s /sbin/nologin -M -g mysql mysql

cp support-files/my-medium.cnf /etc/my.cnf
sed '/skip-external-locking/i\datadir = /usr/local/mysql/var' -i /etc/my.cnf
if [ $installinnodb = "y" ]; then
sed -i 's:#innodb:innodb:g' /etc/my.cnf
sed -i 's:/usr/local/mysql/data:/usr/local/mysql/var:g' /etc/my.cnf
else
sed '/skip-external-locking/i\default-storage-engine=MyISAM\nloose-skip-innodb' -i /etc/my.cnf
fi

/usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/usr/local/mysql/var --user=mysql
chown -R mysql /usr/local/mysql/var
chgrp -R mysql /usr/local/mysql/.
cp support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql

cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
ldconfig

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql
if [ -d "/proc/vz" ];then
ulimit -s unlimited
fi
/etc/init.d/mysql start

ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/usr/local/mysql/bin/mysqladmin -u root password $mysqlrootpwd

cat > /tmp/mysql_sec_script<<EOF
use mysql;
update user set password=password('$mysqlrootpwd') where user='root';
delete from user where not (user='root') ;
delete from user where user='root' and password=''; 
drop database test;
DROP USER ''@'%';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script

rm -f /tmp/mysql_sec_script

/etc/init.d/mysql restart
/etc/init.d/mysql stop
echo "============================MySQL 5.5.26 install completed========================="
}

function InstallPHP53()
{
	echo "==========  InstallPHP53"
echo "============================Install PHP 5.3.29================================"
cd $cur_dir
export PHP_AUTOCONF=/usr/local/autoconf-2.69/bin/autoconf
export PHP_AUTOHEADER=/usr/local/autoconf-2.69/bin/autoheader
tar zxvf php-5.3.29.tar.gz
\cp -fr php-5.3.29 php-iwsv
cd php-5.3.29/
./configure --prefix=/usr/local/php53 --with-config-file-path=/usr/local/php53/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext --disable-fileinfo

make ZEND_EXTRA_LIBS='-liconv'
make install

rm -f /usr/bin/php
ln -s /usr/local/php53/bin/php /usr/bin/php
ln -s /usr/local/php53/bin/phpize /usr/bin/phpize
ln -s /usr/local/php53/sbin/php-fpm /usr/bin/php-fpm

echo "Copy new php configure file."
mkdir -p /usr/local/php53/etc
cp php.ini-production /usr/local/php53/etc/php.ini

cd $cur_dir
# php extensions
echo "Modify php.ini......"
sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /usr/local/php53/etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /usr/local/php53/etc/php.ini
sed -i 's/;date.timezone =/date.timezone = PRC/g' /usr/local/php53/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /usr/local/php53/etc/php.ini
sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php53/etc/php.ini
sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' /usr/local/php53/etc/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php53/etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/php53/etc/php.ini
sed -i 's/register_long_arrays = On/;register_long_arrays = On/g' /usr/local/php53/etc/php.ini
sed -i 's/magic_quotes_gpc = On/;magic_quotes_gpc = On/g' /usr/local/php53/etc/php.ini
sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' /usr/local/php53/etc/php.ini

echo "Install ZendGuardLoader for PHP 5.3"
if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
	tar zxvf ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
	mkdir -p /usr/local/zend53/
	cp ZendGuardLoader-php-5.3-linux-glibc23-x86_64/php-5.3.x/ZendGuardLoader.so /usr/local/zend53/
else
	tar zxvf ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
	mkdir -p /usr/local/zend53/
	cp ZendGuardLoader-php-5.3-linux-glibc23-i386/php-5.3.x/ZendGuardLoader.so /usr/local/zend53/
fi

echo "Write ZendGuardLoader to php.ini......"
cat >>/usr/local/php53/etc/php.ini<<EOF
;eaccelerator

;ionCube

[Zend Optimizer] 
zend_extension=/usr/local/zend53/ZendGuardLoader.so
EOF

echo "Creating new php-fpm configure file......"
cat >/usr/local/php53/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php53/var/run/php-fpm.pid
error_log = /usr/local/php53/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php53.sock
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
EOF

echo "Copy php-fpm init.d file......"
cp $cur_dir/php-5.3.29/sapi/fpm/init.d.php-fpm /etc/init.d/php53
chmod +x /etc/init.d/php53

echo "============================PHP 5.3.29 install completed======================"
}

function InstallPHP-iwsv()
{
	echo "==========  InstallPHP-iwsv"
echo "============================Install PHP 5.3.29================================"
cd $cur_dir
export PHP_AUTOCONF=/usr/local/autoconf-2.69/bin/autoconf
export PHP_AUTOHEADER=/usr/local/autoconf-2.69/bin/autoheader
cd php-iwsv/
./configure --prefix=/usr/local/php-iwsv --with-config-file-path=/usr/local/php-iwsv/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext --disable-fileinfo

make ZEND_EXTRA_LIBS='-liconv'
make install

echo "Copy new php configure file."
mkdir -p /usr/local/php-iwsv/etc
cp php.ini-production /usr/local/php-iwsv/etc/php.ini

cd $cur_dir
# php extensions
echo "Modify php.ini......"
sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/;date.timezone =/date.timezone = PRC/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/register_long_arrays = On/;register_long_arrays = On/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/magic_quotes_gpc = On/;magic_quotes_gpc = On/g' /usr/local/php-iwsv/etc/php.ini
sed -i 's/disable_functions =.*/disable_functions = /g' /usr/local/php-iwsv/etc/php.ini

echo "Install ZendGuardLoader for PHP 5.3"
\cp -fr /usr/local/zend53 /usr/local/zend-iwsv
echo "Write ZendGuardLoader to php.ini......"
cat >>/usr/local/php-iwsv/etc/php.ini<<EOF
;eaccelerator

;ionCube

[Zend Optimizer] 
zend_extension=/usr/local/zend-iwsv/ZendGuardLoader.so
EOF

echo "Creating new php-fpm configure file......"
cat >/usr/local/php-iwsv/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php-iwsv/var/run/php-fpm.pid
error_log = /usr/local/php-iwsv/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-iwsv.sock
listen.mode = 0666
user = root
group = root
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
EOF

echo "Copy php-fpm init.d file......"
cp $cur_dir/php-iwsv/sapi/fpm/init.d.php-fpm /etc/init.d/php-iwsv
sed -i 's/php_opts="/php_opts="-R /g' /etc/init.d/php-iwsv
chmod +x /etc/init.d/php-iwsv

echo "============================PHP 5.3.29 install completed======================"
}

function InstallNginx()
{
	echo "==========  InstallNginx"
echo "============================Install Nginx================================="
cd $cur_dir
tar zxvf pcre-8.12.tar.gz
cd pcre-8.12/
./configure
make && make install
cd ../

ldconfig

tar zxvf nginx-1.10.1.tar.gz
\cp -fr nginx-1.10.1 nginx-iwsv
cd nginx-1.10.1/
unzip $cur_dir/lua-nginx-module-master.zip 
unzip $cur_dir/ngx_http_substitutions_filter_module-master.zip
sed -i 's/Server: /Server: ImWeb-/g' src/http/ngx_http_header_filter_module.c
export LUAJIT_LIB=/usr/local/luajit/lib
export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0

./configure --user=www --group=www --prefix=/usr/local/nginx \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_gzip_static_module \
--with-ipv6 \
--add-module=lua-nginx-module-master \
--add-module=ngx_http_substitutions_filter_module-master \
--with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" 

make && make install
cd ../

ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

rm -f /usr/local/nginx/conf/nginx.conf
rm -f /usr/local/nginx/conf/fcgi.conf
unzip nginx_conf.zip -d /usr/local/nginx/conf/

mkdir /usr/local/nginx/conf/rewrite
unzip $cur_dir/rewrite.zip -d /usr/local/nginx/conf/rewrite
mkdir /usr/local/nginx/conf/protection
unzip $cur_dir/nginx-protection.zip -d /usr/local/nginx/conf/protection
cd $cur_dir


mkdir -p /home/wwwroot/default
chmod +w /home/wwwroot/default
mkdir -p /home/wwwlogs
chmod 777 /home/wwwlogs
unzip $cur_dir/webdefault.zip -d /home/wwwroot/default

chown -R www:www /home/wwwroot/default
}

function Nginx-iwsv()
{
	echo "==========  InstallNginx"
echo "============================Install Nginx================================="
cd $cur_dir

cd nginx-iwsv/
sed -i 's/Server: /Server: ImWeb-/g' src/http/ngx_http_header_filter_module.c
unzip $cur_dir/ngx_http_auth_pam_module-master.zip
./configure --user=www --group=www --prefix=/usr/local/nginx-iwsv --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-ipv6 --add-module=ngx_http_auth_pam_module-master
make && make install
cd ../

ln -s /usr/local/nginx-iwsv/sbin/nginx /usr/bin/nginx-iwsv

rm -f /usr/local/nginx-iwsv/conf/nginx.conf
rm -f /usr/local/nginx-iwsv/conf/fcgi.conf
unzip nginx-iwsv_conf.zip -d /usr/local/nginx-iwsv/conf/
mkdir /usr/local/nginx-iwsv/conf/rewrite
unzip $cur_dir/rewrite.zip -d /usr/local/nginx-iwsv/conf/rewrite

cd $cur_dir


mkdir -p /home/nginx-iwsv/
chmod +w /home/nginx-iwsv/
tar zxvf $cur_dir/nginx-iwsv.tar.gz -C /home/nginx-iwsv/
\rm -fr /home/nginx-iwsv/config/mysqlroot.php
cat >>/home/nginx-iwsv/config/mysqlroot.php<<eof
<?php \$mysqlroot = '$mysqlrootpwd';
eof

cat >>/etc/pam.d/nginx<<eof
auth    required     pam_unix.so
account required     pam_unix.so
eof

}

function CreatPHPTools()
{
	echo "==========  CreatPHPTools"
cd $cur_dir

echo "Copy PHP Prober..."
cd $cur_dir
tar zxvf p.tar.gz
cp p.php /home/wwwroot/default/p.php

echo "============================Install PHPMyAdmin================================="
tar zxf phpmyadmin-latest.tar.gz
mv phpMyAdmin-3.4.8-all-languages /home/wwwroot/default/phpmyadmin/
cp conf/config.inc.php /home/wwwroot/default/phpmyadmin/config.inc.php
sed -i 's/LNMPORG/ImWeb.cc'$RANDOM'SD/g' /home/wwwroot/default/phpmyadmin/config.inc.php
mkdir /home/wwwroot/default/phpmyadmin/upload/
mkdir /home/wwwroot/default/phpmyadmin/save/
chmod 755 -R /home/wwwroot/default/phpmyadmin/
chown www:www -R /home/wwwroot/default/phpmyadmin/
echo "============================phpMyAdmin install completed================================="


}

function AddAndStartup()
{
	echo "==========  AddAndStartup"
cd $cur_dir

echo "============================add nginx and php-fpm on startup============================"
echo "Create nginx init.d file......"
cp init.d.nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
cp init.d.nginx-iwsv /etc/init.d/nginx-iwsv
chmod +x /etc/init.d/nginx-iwsv

chkconfig --level 345 crond on
chkconfig --level 345 php53 on
chkconfig --level 345 nginx on
chkconfig --level 345 php-iwsv on
chkconfig --level 345 nginx-iwsv on
chkconfig --level 345 mysql on
chkconfig --level 345 postfix off
echo "===========================add nginx and php-fpm on startup completed===================="
echo "Starting LNMP..."
/etc/init.d/crond restart
/etc/init.d/mysql start
/etc/init.d/php53 start
/etc/init.d/nginx start
/etc/init.d/php-iwsv start
/etc/init.d/nginx-iwsv start
/etc/init.d/postfix stop

#add 80 port to iptables
if [ -s /sbin/iptables ]; then
/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
/sbin/iptables -I INPUT -p tcp --dport 2222 -j ACCEPT
/sbin/iptables-save
fi
}

function IntallFTP()
{
	echo "==========  IntallFTP"
cd $cur_dir

cp /usr/local/mysql/lib/mysql/*.* /usr/lib/
if [ -s /var/lib/mysql/mysql.sock ]; then
rm -f /var/lib/mysql/mysql.sock
fi
mkdir /var/lib/mysql
ln -s /tmp/mysql.sock /var/lib/mysql/mysql.sock

echo "Start install pure-ftpd..."
tar zxvf pure-ftpd-1.0.35.tar.gz
cd pure-ftpd-1.0.35/
./configure --prefix=/usr/local/pureftpd CFLAGS=-O2 \
--with-mysql=/usr/local/mysql \
--with-quotas \
--with-cookie \
--with-virtualhosts \
--with-virtualroot \
--with-diraliases \
--with-sysquotas \
--with-ratios \
--with-altlog \
--with-paranoidmsg \
--with-shadow \
--with-welcomemsg  \
--with-throttling \
--with-uploadscript \
--with-language=traditional-chinese

make && make install

echo "Copy configure files..."
cp configuration-file/pure-config.pl /usr/local/pureftpd/sbin/
chmod 755 /usr/local/pureftpd/sbin/pure-config.pl
unzip $cur_dir/pureftpd_conf.zip -d /usr/local/pureftpd/

echo "Modify parameters of pureftpd configures..."
sed -i 's/127.0.0.1/localhost/g' /usr/local/pureftpd/pureftpd-mysql.conf
sed -i 's/tmppasswd/'$mysqlftppwd'/g' /usr/local/pureftpd/pureftpd-mysql.conf
sed -i 's/mysqlftppwd/'$mysqlftppwd'/g' /usr/local/pureftpd/script.mysql

echo "Import pureftpd database..."
/usr/local/mysql/bin/mysql -u root -p$mysqlrootpwd -h localhost < /usr/local/pureftpd/script.mysql

cd $cur_dir

cp init.d.pureftpd /etc/init.d/pureftpd
chmod +x /etc/init.d/pureftpd
chkconfig --level 345 pureftpd on
/etc/init.d/pureftpd start
if [ -s /sbin/iptables ]; then
/sbin/iptables -I INPUT -p tcp --dport 21 -j ACCEPT
/sbin/iptables -I INPUT -p tcp --dport 20 -j ACCEPT
/sbin/iptables-save
fi

}

function IntallionCube()
{
	echo "==========  IntallionCube"
cd $cur_dir

tar zxvf ioncube_loaders_lin_x86-64.tar.gz -C /usr/local/
cd /usr/local/
sed -i '/ionCube Loader/d' /usr/local/php53/etc/php.ini
sed -i '/ionCube Loader/d' /usr/local/php-iwsv/etc/php.ini
sed -i '/ioncube_loader_lin/d' /usr/local/php53/etc/php.ini
sed -i '/ioncube_loader_lin/d' /usr/local/php-iwsv/etc/php.ini

cat >ionCube53.ini<<EOF
[ionCube Loader]
zend_extension="/usr/local/ioncube/ioncube_loader_lin_5.3.so"
EOF

sed -i '/;ionCube/ {
r ionCube53.ini
}' /usr/local/php-iwsv/etc/php.ini
sed -i '/;ionCube/ {
r ionCube53.ini
}' /usr/local/php53/etc/php.ini

echo "Restarting php-fpm......"
RestartAllPHP

rm ionCube53.ini
cd $cur_dir

}

function installXcahe53()
{
	echo "==========  installXcahe53"
cd $cur_dir

cpu_count=`cat /proc/cpuinfo |grep -c processor`

if [ -s xcache-3.2.0 ]; then
	rm -rf xcache-3.2.0/
fi
tar zxvf xcache-3.2.0.tar.gz
cd xcache-3.2.0/
/usr/local/php53/bin/phpize
./configure --enable-xcache --enable-xcache-coverager --enable-xcache-optimizer --with-php-config=/usr/local/php53/bin/php-config
make
make install
cd ../

sed -i '/;xcache/,/;xcache end/d' /usr/local/php53/etc/php.ini
cat >>/usr/local/php53/etc/php.ini<<EOF
;xcache
[xcache-common]
extension = xcache.so

;[xcache.admin]
;xcache.admin.enable_auth = On
;xcache.admin.user = "admin"
;run: echo -n "yourpassword" |md5sum |awk '{print $1}' to get md5 password
;xcache.admin.pass = "md5 password"

[xcache]
xcache.shm_scheme =        "mmap"
xcache.size  =               20M
; set to cpu count (cat /proc/cpuinfo |grep -c processor)
xcache.count =                 $cpu_count
xcache.slots =                8K
xcache.ttl   =                 0
xcache.gc_interval =           0
xcache.var_size  =            4M
xcache.var_count =             1
xcache.var_slots =            8K
xcache.var_ttl   =             0
xcache.var_maxttl   =          0
xcache.var_gc_interval =     300
xcache.readonly_protection = Off
; for *nix, xcache.mmap_path is a file path, not directory. (auto create/overwrite)
; Use something like "/tmp/xcache" instead of "/dev/*" if you want to turn on ReadonlyProtection
; different process group of php won't share the same /tmp/xcache
xcache.mmap_path =    "/dev/zero"
xcache.coredump_directory =   ""
xcache.experimental =        Off
xcache.cacher =               On
xcache.stat   =               On
xcache.optimizer =           Off

[xcache.coverager]
; enabling this feature will impact performance
; enable only if xcache.coverager == On && xcache.coveragedump_directory == "non-empty-value"
; enable coverage data collecting and xcache_coverager_start/stop/get/clean() functions
xcache.coverager =          Off
xcache.coveragedump_directory = ""
;xcache end
EOF
/etc/init.d/php53 restart
#\cp -R htdocs /home/wwwroot/default/xcache
}

function Install_PHPMemcache53()
{
	echo "==========  Install_PHPMemcache53"
    echo "Install memcache php extension..."
    cd ${cur_dir}
	if [ -s memcache-3.0.8 ]; then
		rm -rf memcache-3.0.8/
	fi
	tar zxvf memcache-3.0.8.tgz
	cd memcache-3.0.8
    /usr/local/php53/bin/phpize
    ./configure --with-php-config=/usr/local/php53/bin/php-config
    make && make install
    cd ${cur_dir}
}

function RestartAllPHP()
{
	echo "==========  RestartAllPHP"
	/etc/init.d/php53 restart
	/etc/init.d/php-iwsv restart
}

function Install_PHPMemcache()
{
	echo "==========  Install_PHPMemcache"
	cd ${cur_dir}
    sed -i '/memcache.so/d' /usr/local/php53/etc/php.ini
    sed -i '/memcached.so/d' /usr/local/php53/etc/php.ini
	sed -i "/the dl()/i\
extension = \"memcache.so\"" /usr/local/php53/etc/php.ini
    echo "Install memcached..."
	tar zxvf memcached-1.4.25.tar.gz
	cd memcached-1.4.25
	./configure --prefix=/usr/local/memcached
    make &&make install
    cd ${cur_dir}
	ln -sf /usr/local/memcached/bin/memcached /usr/bin/memcached
	\cp init.d.memcached /etc/init.d/memcached
    chmod +x /etc/init.d/memcached
    useradd -s /sbin/nologin nobody
    if [ ! -d /var/lock/subsys ]; then
      mkdir -p /var/lock/subsys
    fi
	chkconfig --add memcached
	chkconfig memcached on
	
	if [ -s /sbin/iptables ]; then
        /sbin/iptables -A INPUT -p tcp --dport 11211 -j DROP
        /sbin/iptables -A INPUT -p udp --dport 11211 -j DROP
        if [ "$PM" = "yum" ]; then
            service iptables save
        elif [ "$PM" = "apt" ]; then
            iptables-save > /etc/iptables.rules
        fi
    fi

    echo "Starting Memcached..."
    /etc/init.d/memcached start
	RestartAllPHP

}

function Install_csf()
{
	echo "==========  Install_csf"
    cd ${cur_dir}
	wget -c "http://www.configserver.com/free/csf.tgz"
	tar zxvf csf.tgz
	cd csf
	sh install.sh
	sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
	sed -i 's/TCP_IN = "/TCP_IN = "2222,/g' /etc/csf/csf.conf
	sed -i 's/TCP_OUT = "/TCP_OUT = "2222,/g' /etc/csf/csf.conf
	/usr/sbin/csf -r
    cd ${cur_dir}

}



checkFile autoconf-2.69.tar.gz
checkFile libiconv-1.14.tar.gz
checkFile libmcrypt-2.5.8.tar.gz
checkFile mcrypt-2.6.8.tar.gz
checkFile memcache-3.0.6.tgz
checkFile mhash-0.9.9.9.tar.gz
checkFile mysql-5.5.28.tar.gz
checkFile nginx-1.10.1.tar.gz
checkFile pcre-8.12.tar.gz
checkFile php-5.3.29.tar.gz
checkFile phpmyadmin-latest.tar.gz
checkFile p.tar.gz
checkFile ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
checkFile ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
checkFile nginx_conf.zip
checkFile init.d.nginx
checkFile pure-ftpd-1.0.35.tar.gz
checkFile pureftpd_conf.zip
checkFile ioncube_loaders_lin_x86-64.tar.gz
checkFile xcache-3.2.0.tar.gz
checkFile memcache-3.0.8.tgz
checkFile memcached-1.4.25.tar.gz
checkFile init.d.memcached
checkFile init.d.nginx-iwsv
checkFile nginx-iwsv_conf.zip
checkFile init.d.pureftpd
checkFile ngx_http_auth_pam_module-master.zip
checkFile nginx-iwsv.tar.gz
checkFile rewrite.zip
checkFile lua-nginx-module-master.zip
checkFile lua-5.3.3.tar.gz
checkFile LuaJIT-2.0.4.tar.gz
checkFile nginx-protection.zip
checkFile webdefault.zip
checkFile ngx_http_substitutions_filter_module-master.zip
# checkFile naxsi-master.zip

# checkFile 
InstallDependsAndOpt
InstallMySQL55
InstallPHP53
InstallPHP-iwsv
InstallNginx
Nginx-iwsv
CreatPHPTools
AddAndStartup
IntallFTP
installXcahe53
IntallionCube
RestartAllPHP
Install_PHPMemcache
Install_PHPMemcache53
Install_csf
RestartAllPHP

cd /usr/local/src/
rm -rf *
