#!/bin/bash

# By Bob  #### 改为UCServer UI，更新自2015年9月8日

# uname -r, 如果包含-pve, 需要到/usr/src执行
# ln -s kernels/2.6.18-308.4.1.el5-x86_64/ linux 

CentOS_UPDATE(){
	yum -y update
	ln -s /usr/src/kernel/2.6.32-573.26.1.el6.x86_64  /usr/src/kernel/2.6.32-573.el6.x86_64
	echo -e "\e[32mCentOS Update OK!\e[m"
#
}

function newRepo_install(){
	cd /usr/src
	version=`cat /etc/issue|grep -o 'release [0-9]\+'`
	arch=i386
  bit=`getconf LONG_BIT`
  if [ $bit == 64 ]; then
		arch=x86_64
	fi;
	if [ "$version" == "release 6" ]; then
		if [ ! -e ./epel-release-$epelver6.noarch.rpm ]; then
			rpm -ivh $cdnmirror/epel-release-6-5.noarch.rpm 
		fi;

		if [ ! -e ./ius-release-$iusver6.ius.el6.noarch.rpm ]; then
			rpm -ivh  $cdnmirror/ius-release-1.0-14.ius.el6.noarch.rpm
		fi;

		if [ ! -e ./percona-release-0.1-3.noarch.rpm ]; then
			rpm -ivh $cdnmirror/percona-release-0.1-3.noarch.rpm
		fi;
	fi

	sed -i "s/mirrorlist/#mirrorlist/" /etc/yum.repos.d/ius.repo
	sed -i "s/#baseurl/baseurl/" /etc/yum.repos.d/ius.repo
}

function yum_install(){
	#yum -y upgrade
	yum -y remove php* 
	yum -y remove asterisk*
	yum -y install libpcap-devel libaio bash iftop openssl openssh-server openssh-clients tcpdump wget mlocate openvpn ghostscript mailx cpan crontabs glibc gcc-c++ libtermcap-devel newt newt-devel ncurses ncurses-devel libtool libxml2-devel kernel-devel  subversion flex libstdc++-devel libstdc++  unzip sharutils openssl-devel make kernel-header
	yum -y install numactl perl perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version nscd
	yum -y install sqlite-devel libuuid-devel pciutils samba cifs-utils
	yum -y install speex-tools flac htop
	yum -y install hwloc ftp libmicrohttpd gnutls
	yum -y install MySQL-python
	yum -y install memcached
	service ntpd restart
	chkconfig ntpd on
	cd /usr/src
	rm -rf Percona*.rpm*
        wget  $cdnmirror/percona/Percona-Server-client-57-5.7.12-5.1.el6.x86_64.rpm
        wget  $cdnmirror/percona/Percona-Server-server-57-5.7.12-5.1.el6.x86_64.rpm
        wget  $cdnmirror/percona/Percona-Server-shared-57-5.7.12-5.1.el6.x86_64.rpm
	rpm -ivh Percona*.rpm
	wget $downloadmirror/percona/my1.cnf -O /etc/my.cnf
#	chkconfig --level 2345 mysql on
#	chkconfig --level 2345 crond on
	chkconfig mysql on
	chkconfig crond on
	service crond start
	service mysql start
	mysql -uroot -e "update user set authentication_string=password('') where User='root' and Host='localhost'" mysql
	mysql -uroot -e "flush privileges"
	wget $downloadmirror/percona/my2.cnf -O /etc/my.cnf
	service mysql restart
	mysql --connect-expired-password -uroot -e "set password = password('')"
	wget $downloadmirror/percona/mysql.init.d -O /etc/init.d/mysql
	chmod +x /etc/init.d/mysql
	service mysql restart
	service crond restart
	service nscd start
	chkconfig nscd on

}

function ioncube_install(){
	echo -e "\e[32mStarting Install ioncube\e[m"
	cd /usr/src
        bit=`getconf LONG_BIT`
        if [ $bit == 32 ]; then
		if [ ! -e ./ioncube_loaders_lin_x86.tar.gz ]; then
			wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz
		fi
		tar zxf ioncube_loaders_lin_x86.tar.gz
	else
		if [ ! -e ./ioncube_loaders_lin_x86-64.tar.gz ]; then
			wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
		fi
		tar zxf ioncube_loaders_lin_x86-64.tar.gz
	fi
	mv /usr/src/ioncube /usr/local/
	sed -i "/ioncube/d"  /etc/php.ini
	echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.3.so" >> /etc/php.ini
	/etc/init.d/php-fpm start
	echo -e "\e[32mIoncube Install OK!\e[m"
}

function php_install(){
	echo -e "\e[32mStarting Install PHP-Fpm\e[m"
	useradd -u 500 -c "Asterisk PBX" -d /var/lib/asterisk asterisk
	if [ -e /etc/php.ini.rpmnew -a ! -e /etc/php.ini ]; then
		cp /etc/php.ini.rpmnew /etc/php.ini
	fi
	yum -y install libmemcached10 sox libvpx-devel libXpm-devel t1lib-devel MySQL-python libxslt libxslt-devel unzip mod_dav_svn GeoIP GeoIP-GeoLite-data GeoIP-GeoLite-data-extra libmcrypt 
	cd /usr/src
	rm -rf php56u.zip
	rm -rf php56u*.rpm
	wget $cdnmirror/php/php56u.zip?v=20171123 -O php56u.zip
	unzip php56u.zip
	rpm -ivh php56u*.rpm
	yum -y install php-getid3
	sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php.ini 
	sed -i "s/memory_limit = 16M /memory_limit = 128M /" /etc/php.ini 
	sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 40M /" /etc/php.ini 
	sed -i "s/post_max_size = 8M/post_max_size = 40M/" /etc/php.ini
	sed -i '/^error_reporting/c error_reporting = E_ALL & ~E_DEPRECATED' /etc/php.ini
	sed -i "s/user = php-fpm/user = asterisk/" /etc/php-fpm.d/www.conf
	sed -i "s/group = php-fpm/group = asterisk/" /etc/php-fpm.d/www.conf
	wget $cdnmirror/php/20-soap-php5.6.ini -O /etc/php.d/20-soap.ini
#	wget $cdnmirror/php/soap-php5.6.so -O /usr/lib64/php/soap.so (do not dowload it)
	mkdir -p /var/lib/php/session
	chown asterisk.asterisk /var/lib/php/session
	chkconfig php-fpm on
	echo -e "\e[32mPHP-Fpm Install OK!\e[m"
}
function redis_install(){
	yum -y install jemalloc
	rpm -ivh $downloadmirror/redis30u-3.0.6-1.ius.el6.x86_64.rpm
	chkconfig --level 2345 redis on
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo 511 > /proc/sys/net/core/somaxconn
	sysctl -w vm.overcommit_memory=1  >/dev/null 2>&1
	/etc/init.d/redis start
	wget $downloadmirror/redis.init -O /etc/init.d/redis
	chmod +x /etc/init.d/redis
	/etc/init.d/redis restart
	echo -e "\e[32Redis server Install OK\e[m"
}
function fax_install(){
	echo -e "\e[32mStarting Install FAX\e[m"
  version=`cat /etc/issue|grep -o 'release [0-9]\+'`
	cd /usr/src
	#yum -y install hylafax
	yum -y install libtiff libtiff-devel

  bit=`getconf LONG_BIT`
    if [ "$version" == "release 6" ]; then
      if [ ! -e ./hylafax-server-6.0.6-1rhel6.x86_64.rpm ]; then
        wget $downloadmirror/hylafax-server-6.0.6-1rhel6.x86_64.rpm
      fi
      if [ ! -e ./hylafax-client-6.0.6-1rhel6.x86_64.rpm ]; then
        wget $downloadmirror/hylafax-client-6.0.6-1rhel6.x86_64.rpm
      fi
    fi

	rpm -ivh hylafax-*
	if [ ! -e ./iaxmodem-1.3.0.tar.gz ]; then
		wget $downloadmirror/iaxmodem-1.3.0.tar.gz
	fi
	tar -xvzf iaxmodem-1.3.0.tar.gz
	cd iaxmodem-1.3.0
	./configure
	make
	cp ./iaxmodem /usr/sbin/
  useradd -u 500 -c "Asterisk PBX" -d /var/lib/asterisk asterisk
  mkdir -p /var/spool/hylafax/bin
  mkdir -p /var/spool/hylafax/etc/
  mkdir -p /var/spool/hylafax/docq/
  chmod 777 /var/spool/hylafax/bin
  chmod 777 /var/spool/hylafax/etc/
  chmod 777 /var/spool/hylafax/docq/
  chmod 777 /var/spool/hylafax/doneq/
  mkdir -p /etc/iaxmodem/
  chown asterisk.asterisk /etc/iaxmodem/
  mkdir -p /var/log/iaxmodem/
  chown asterisk.asterisk /var/log/iaxmodem/
cat >  /var/spool/hylafax/etc/setup.cache << EOF
# Warning, this file was automatically generated by faxsetup
# on Thu Jun 28 13:48:41 CST 2012 for root
AWK='/usr/bin/gawk'
BASE64ENCODE='/usr/bin/uuencode -m ==== | /bin/grep -v ===='
BIN='/usr/bin'
CAT='/bin/cat'
CHGRP='/bin/chgrp'
CHMOD='/bin/chmod'
CHOWN='/bin/chown'
CP='/bin/cp'
DPSRIP='/var/spool/hylafax/bin/ps2fax'
ECHO='/bin/echo'
ENCODING='base64'
FAXQ_SERVER='yes'
FONTPATH='/usr/share/ghostscript/8.70/Resource/Init:/usr/share/ghostscript/8.70/lib:/usr/share/ghostscript/8.70/Resource/Font:/usr/share/ghostscript/fonts:/usr/share/fonts/default/ghostscript:/usr/share/fonts/default/Type1:/usr/share/fonts/default/amspsfnt/pfb:/usr/share/fonts/default/cmpsfont/pfb:/usr/share/fonts/japanese:/etc/ghostscript'
FUSER='/sbin/fuser'
GREP='/bin/grep'
GSRIP='/usr/bin/gs'
HFAXD_OLD_PROTOCOL='no'
HFAXD_SERVER='yes'
HFAXD_SNPP_SERVER='no'
IMPRIP=''
LIBDATA='/etc/hylafax'
LIBEXEC='/usr/sbin'
LN='/bin/ln'
MANDIR='/usr/share/man'
MIMENCODE='mimencode'
MKFIFO='/usr/bin/mkfifo'
MV='/bin/mv'
PATHEGETTY='/bin/egetty'
PATHGETTY='/sbin/mgetty'
PATH='/usr/sbin:/bin:/usr/bin:/etc:/usr/local/bin'
PATHVGETTY='/sbin/vgetty'
PSPACKAGE='gs'
QPENCODE='qp-encode'
RM='/bin/rm'
SBIN='/usr/sbin'
SCRIPT_SH='/bin/bash'
SED='/bin/sed'
SENDMAIL='/usr/sbin/sendmail'
SPOOL='/var/spool/hylafax'
SYSVINIT=''
TARGET='i686-pc-linux-gnu'
TIFF2PDF='/usr/bin/tiff2pdf'
TIFFBIN='/usr/bin'
TTYCMD='/usr/bin/tty'
UUCP_LOCKDIR='/var/lock'
UUCP_LOCKTYPE='ascii'
UUENCODE='/usr/bin/uuencode'
EOF
	echo -e "\e[32mFAX Install OK!\e[m"
}

function mpg123_install(){
	echo -e "\e[32mStarting Install MPG123\e[m"
	cd /usr/src
	if [ ! -e ./mpg123-$mpg123ver.tar.bz2 ]; then
		wget $downloadmirror/mpg123-$mpg123ver.tar.bz2 -O mpg123-$mpg123ver.tar.bz2
	fi
	tar jxf mpg123-$mpg123ver.tar.bz2
	cd mpg123-$mpg123ver
	./configure
	make
	make install
	echo -e "\e[32mMPG123 Install OK!\e[m"

}

function dahdi_install() {
	echo -e "\e[32mStarting Install DAHDI\e[m"
	cd /usr/src
	if [ ! -e ./dahdi-linux-complete-$dahdiver.tar.gz ]; then
		wget $cdnmirror/Files/dahdi-linux-complete-$dahdiver.tar.gz
		if [ ! -e ./dahdi-linux-complete-$dahdiver.tar.gz ]; then
			wget $cdnmirror/Files/dahdi-linux-complete-$dahdiver.tar.gz
		fi
	fi
	tar zxf dahdi-linux-complete-$dahdiver.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid dahdi tar package\n"
		exit 1
	fi

	cd dahdi-linux-complete-$dahdiver
	make
	if [ $? != 0 ]; then
		yum -y update kernel
		echo -e "\e[32mplease reboot your server and run this script again\e[m\n"
		exit 1;
	fi
	make install
	make config
  echo "blacklist netjet" >> /etc/modprobe.d/dahdi.blacklist.conf
	/etc/init.d/dahdi start
	/usr/sbin/dahdi_genconf
	echo -e "\e[32mDAHDI Install OK!\e[m"
}

function memcached(){
	sed -i "s/OPTIONS=\""\/OPTIONS="\"-l 127.0.0.1"/ /etc/sysconfig/memcached
	/etc/init.d/memcached start
	chkconfig memcached on
}
function nginx_install(){
	echo -e "\e[32mStarting install nginx\e[m"
	service httpd stop
	chkconfig httpd off
	yum -y install pcre-devel
	cd /usr/src
	if [ ! -e ./nginx-$nginxver.tar.gz ]; then
		wget $downloadmirror/nginx-$nginxver.tar.gz
	fi
	tar zxf nginx-$nginxver.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid nginx tar package\n"
		exit 1
	fi

	if [ ! -e ./nginx-push-stream-module-master-20130206.tar.gz ]; then
		wget $downloadmirror/nginx-push-stream-module-master-20130206.tar.gz
	fi
	
	tar zxf nginx-push-stream-module-master-20130206.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid nginx push tar package\n"
		exit 1
	fi

	cd nginx-$nginxver
	./configure --add-module=/usr/src/nginx-push-stream-module-master --with-http_ssl_module  --user=asterisk --group=asterisk
	make
	make install
	wget $downloadmirror/nginx.zip
	unzip ./nginx.zip
	mv ./nginx /etc/init.d/
	chmod +x /etc/init.d/nginx
	chkconfig nginx on

	echo -e "\e[32mNginx Install OK!\e[m"
}

function asterisk_install() {
	yum  install speex speex-devel -y
	echo -e "\e[32mStarting Install Asterisk\e[m"
	useradd -u 500 -c "Asterisk PBX" -d /var/lib/asterisk asterisk
	#Define a user called asterisk.
	mkdir /var/run/asterisk /var/log/asterisk /var/spool/asterisk /var/lib/asterisk
	chown -R asterisk:asterisk /var/run/asterisk /var/log/asterisk /var/lib/php /var/lib/asterisk /var/spool/asterisk/
	#Change the owner of this file to asterisk.
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 
	setenforce 0
	#shutdown selinux
	cd /usr/src
	if [ ! -e ./asterisk-$asteriskver.tar.gz ]; then
		wget $cdnmirror/asterisk-$asteriskver.tar.gz
	fi
	tar zxf asterisk-$asteriskver.tar.gz
	if [ $? != 0 ]; then
		echo "fatal: dont have valid asterisk tar package"
		exit 1
	fi

	cd asterisk-$asteriskver
	./configure '-disable-xmldoc'
	./contrib/scripts/get_mp3_source.sh
	make menuconfig
	make
	make install
	make samples
	#This command will  install the default configuration files.
	#make progdocs
	#This command will create documentation using the doxygen software from comments placed within the source code by the developers. 
	make config
	#This command will install the startup scripts and configure the system (through the use of the chkconfig command) to execute Asterisk automatically at startup.
	sed -i "s/#AST_USER/AST_USER/" /etc/init.d/asterisk
	sed -i "s/#AST_GROUP/AST_GROUP/" /etc/init.d/asterisk
	sed -i "s/;runuser = asterisk/runuser = asterisk/" /etc/asterisk/asterisk.conf
	sed -i "s/;rungroup = asterisk/rungroup = asterisk/" /etc/asterisk/asterisk.conf

	sed -i 's/;enable=yes/enable=no/' /etc/asterisk/cdr.conf
	sed -i '/net.ipv4.ip_forward/ s/\(.*= \).*/\11/' /etc/sysctl.conf
	/sbin/sysctl -p
	# set AMI user
cat > /etc/asterisk/manager.conf << EOF
[general]
enabled = yes
port = 5038
bindaddr = 127.0.0.1
displayconnects=no

[asterccuser]
secret = asterccsecret
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read = system,call,agent
write = all
EOF
#	wget $downloadmirror/format_mp3.so -O /usr/lib/asterisk/modules/format_mp3.so
	chmod +x /usr/lib/asterisk/modules/format_mp3.so
	sed -i 's/bindaddr = 0.0.0.0/bindaddr = 127.0.0.1/' /etc/asterisk/manager.conf
	/etc/init.d/asterisk restart
	chkconfig asterisk on
	echo -e "\e[32mAsterisk Install OK!\e[m"
}


function lame_install(){
	echo -e "\e[32mStarting Install Lame for mp3 monitor\e[m"
	cd /usr/src
	if [ ! -e ./lame-3.99.5.tar.gz ]; then
    	wget $downloadmirror/lame-3.99.5.tar.gz -O lame-3.99.5.tar.gz
	fi
	tar zxf lame-3.99.5.tar.gz
	if [ $? != 0 ]; then
		echo -e "\e[32mdont have valid lame tar package, you may lose the feature to check recordings on line\e[m\n"
		return 1
	fi

	cd lame-3.99.5
	./configure && make && make install
	if [ $? != 0 ]; then
		echo -e "\e[32mfailed to install lame, you may lose the feature to check recordings on line\e[m\n"
		return 1
	fi
	ln -s /usr/local/bin/lame /usr/bin/
	echo -e "\e[32mLame install OK!\e[m"
	return 0;
}

function libpri_install() {
	echo -e "\e[32mStarting Install LibPRI\e[m"
	cd /usr/src
	if [ ! -e ./libpri-$libpriver.tar.gz ]; then
		wget $downloadmirror/libpri-$libpriver.tar.gz
	fi
	tar zxf libpri-$libpriver.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid libpri tar package\n"
		exit 1
	fi

	cd libpri-$libpriver
	make
	make install
	echo -e "\e[32mLibPRI Install OK!\e[m"
}

function nginx_conf_install(){
	mkdir /var/www/html/asterCC/http-log -p
cat >  /usr/local/nginx/conf/nginx.conf << EOF
#user  nobody;
worker_processes  auto;
worker_rlimit_nofile 65535;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

pid        /var/run/nginx.pid;


events {
    use epoll;
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;
    access_log   off;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;

	push_stream_store_messages on;
	push_stream_shared_memory_size  256M;
	push_stream_message_ttl  15m;

    gzip  on;
    gzip_min_length 1k;
    gzip_buffers 16 64k;
    gzip_http_version 1.1;
    gzip_comp_level 6;
    gzip_types text/plain application/x-javascript text/css application/xml;
    gzip_vary on;
    server
    {
        listen       80 default;
        client_max_body_size 20M;
        index index.html index.htm index.php;
        root  /var/www/html/asterCC/app/webroot;
	access_log   off;

        location / {
          index index.php;
	  access_log   off;

          if (-f \$request_filename) {
            break;
          }
          if (!-f \$request_filename) {
            rewrite ^/(.+)\$ /index.php?url=\$1 last;
            break;
          }
		  location  /agentindesks/pushagent {
			push_stream_publisher admin;
			set \$push_stream_channel_id \$arg_channel;
		  }

		  location ~ /agentindesks/agentpull/(.*) {
			push_stream_subscriber      long-polling;
			set \$push_stream_channels_path    \$1;
			push_stream_message_template                 ~text~;
			push_stream_longpolling_connection_ttl        60s;	
		  }

		  location  /publicapi/pushagent {
			push_stream_publisher admin;
			set \$push_stream_channel_id             \$arg_channel;
		  }

		  location ~ /publicapi/agentpull/(.*) {
			push_stream_subscriber      long-polling;
			set \$push_stream_channels_path    \$1;
			push_stream_message_template         "{\\"text\\":\\"~text~\\",\\"tag\\":~tag~,\\"time\\":\\"~time~\\"}";
			push_stream_longpolling_connection_ttl        60s;
			push_stream_last_received_message_tag       \$arg_etag;
			push_stream_last_received_message_time      \$arg_since;
		  }
		
		  location  /systemevents/pushagent {
			push_stream_publisher admin;
			set \$push_stream_channel_id             \$arg_channel;
		  }

		  location ~ /systemevents/agentpull/(.*) {
			push_stream_subscriber      long-polling;
			set \$push_stream_channels_path    \$1;
			push_stream_message_template                 ~text~;
			push_stream_longpolling_connection_ttl        60s;
		  }
        }

        location ~ /\.ht {
          deny all;
        }
        location ~ .*\.(php|php5)?\$
        {
          fastcgi_pass  127.0.0.1:9000;
          fastcgi_index index.php;
          include fastcgi_params;
          fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		  fastcgi_connect_timeout 60;
		  fastcgi_send_timeout 180;
		  fastcgi_read_timeout 180;
		  fastcgi_buffer_size 128k;
		  fastcgi_buffers 4 256k;
		  fastcgi_busy_buffers_size 256k;
		  fastcgi_temp_file_write_size 256k;
		  fastcgi_intercept_errors on;
        }

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|wav)$
        {
          access_log   off;
          expires 15d;
        }
        location ~ .*\.(js|css)?$
        {
	  access_log   off;
          expires 1d;
        }

#        access_log /var/www/html/asterCC/http-log/access.log main;
    }
}
EOF

echo -ne "
* soft nofile 655360
* hard nofile 655360
" >> /etc/security/limits.conf

echo "fs.file-max = 1572775" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 1024 65000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 45" >> /etc/sysctl.conf
echo "vm.dirty_ratio=10" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
echo "vm.overcommit_memory = 1" >>/etc/sysctl.conf
echo "net.core.somaxconn= 1024" >>/etc/sysctl.conf
echo "net.core.rmem_max= 26214400" >>/etc/sysctl.conf
echo "net.core.netdev_max_backlog=2000" >>/etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=102400" >>/etc/sysctl.conf
echo "net.core.somaxconn=4096" >>/etc/sysctl.conf
echo "net.core.wmem_max = 6553600" >>/etc/sysctl.conf
echo "net.core.wmem_default = 6553600" >>/etc/sysctl.conf
echo "net.core.rmem_max = 6553600" >>/etc/sysctl.conf
echo "net.core.rmem_default = 6553600" >>/etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 200000" >>/etc/sysctl.conf

sysctl -p

service nginx restart
}

function astercc_install() {
	/etc/init.d/asterisk restart
	echo -e "\e[32mStarting Install AsterCC\e[m"
	cd /usr/src
	if [ ! -e ./astercc-$asterccver.tar.gz ]; then
		wget $cdnmirror/astercc-$asterccver.tar.gz?v=20180413 -O astercc-$asterccver.tar.gz -t 5
	fi
	tar zxf astercc-$asterccver.tar.gz
	if [ $? != 0 ]; then
		echo "dont have valid astercc tar package, try run this script again or download astercc-$asterccver.tar.gz to /usr/src manually then run this script again"
		exit 1
	fi

	cd astercc-$asterccver
	chmod +x install.sh
	. /tmp/.mysql_root_pw.$$

	./install.sh -dbu=root -dbpw=$mysql_root_pw -amiu=$amiu -amipw=$amipw -allbydefault
	
#	cd /usr/src
#	rm -rf /usr/src/phoneareas.sql
#	wget $cdnmirror/phoneareas.sql?v=20170613
#	mysql -uroot -p$mysql_root_pw astercc10</usr/src/phoneareas.sql
	echo -e "\e[32mAsterCC Commercial Install OK!\e[m"
}


function set_ami(){
	while true;do
		echo -e "\e[32mplease give an AMI user\e[m";
		read amiu;
		if [ "X${amiu}" != "X" ]; then
			break;
		fi
	done

	while true;do
		echo -e "\e[32mplease give an AMI secret\e[m";
		read amipw;
		if [ "X${amipw}" != "X" ]; then
			break;
		fi
	done
cat > /etc/asterisk/manager.conf << EOF
[general]
enabled = yes
port = 5038
bindaddr = 127.0.0.1
displayconnects=no

[$amiu]
secret = $amipw
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read = system,call,agent
write = all
EOF

	asterisk -rx "manager reload"

	echo amiu=$amiu >> /tmp/.mysql_root_pw.$$
	echo amipw=$amipw >> /tmp/.mysql_root_pw.$$

}

function get_mysql_passwd(){
	mkdir -p /var/run/mysqld
	service mysql start
	while true;do
		echo -e "\e[32mplease enter your mysql root passwd\e[m";
		read mysql_passwd;
		# make sure it's not a empty passwd
		if [ "X${mysql_passwd}" != "X" ]; then
			mysqladmin -uroot -p$mysql_passwd password $mysql_passwd	# try empty passwd
			if [ $? == 0  ]; then
				break;
			fi

			mysqladmin password "$mysql_passwd" 
			if [ $? == 0  ]; then
				break;
			fi

			echo -e "\e[32minvalid password,please try again\e[m"
		fi
	done
	echo mysql_root_pw=$mysql_passwd > /tmp/.mysql_root_pw.$$
	mysql -uroot -p$mysql_passwd -e "grant all on *.* to root@'127.0.0.1' identified by '$mysql_passwd'"
}

function iptables_config(){
	echo "start setting firewall"
	iptables -I INPUT -p tcp --dport 80 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 5060 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 5036 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 4569 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 10000:20000 -j ACCEPT
	iptables-save > /etc/sysconfig/iptables
	service iptables restart
}

function UI() {
	mkdir -p /usr/src/UI
	cd /usr/src/UI
	echo "Start setting UCServer UI"
	wget http://downcc.ucserver.org:8083/Files/UCS-UI.tar.gz
	wget http://downcc.ucserver.org:8083/Files/update.sh
	bash /usr/src/UI/update.sh
	rm -rf /usr/src/UI
}
function MYSQL(){
	/etc/init.d/mysql stop
	sleep 15
	rm -rf /etc/my.cnf
	cd /etc/
	wget http://downcc.ucserver.org:8083/Files/my.cnf.percona -O /etc/my.cnf
	/etc/init.d/mysql restart
}

function CHANGE_DNS(){
	echo "nameserver 223.5.5.5">>/etc/resolv.conf
	echo "nameserver 223.6.6.6">>/etc/resolv.conf
}
function ADD_COUNTS(){
	echo "Add counts information"
	cd /var/www/html
	wget http://downcc.ucserver.org:8083/Files/count.php
	wget http://downcc.ucserver.org:8083/Files/clean.php
	echo "0 5 * * * php /var/www/html/clean.php >/dev/null 2>&1" >> /var/spool/cron/root
	echo "0 1 * * * php /var/www/html/createindex.php >/dev/null 2>&1" >> /var/spool/cron/root
	echo "0 3 * * * chown asterisk.asterisk /var/spool/asterisk/monitor >/dev/null 2>&1" >> /var/spool/cron/root
}
function mysql_check_boot(){
	PASSWD=`cat /etc/astercc.conf |grep password|awk '{print $3}'|awk 'NR==1'`
	echo "/usr/bin/mysqlcheck -uroot -p$PASSWD -r astercc10" >>/etc/rc.local
}
function PHP_FPM_permisson(){
	cat > /etc/php-fpm.d/www.conf << EOF
[www]
user = asterisk
group = asterisk
listen = 127.0.0.1:9000
listen.backlog = 65535
listen.allowed_clients = 127.0.0.1
pm = dynamic
pm.max_children =  100
pm.start_servers = 40
pm.min_spare_servers = 20
pm.max_spare_servers = 60
pm.process_idle_timeout = 360s
pm.max_requests = 4096
pm.status_path = /php-status
slowlog = /var/log/php-fpm/www-slow.log
rlimit_files = 65536
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php-fpm/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php-fpm/wsdlcache
EOF
	chown asterisk.asterisk /var/lib/php-fpm/session -R
	chown asterisk.asterisk /var/lib/php-fpm/wsdlcache -R
	}
function run() {
	CHANGE_DNS
	downloadmirror=http://downcc.ucserver.org:8083
	cdnmirror=http://qiniucdn.ucserver.org
	echo "please select the mirror you want to download from:"
	echo "1: Shanghai Huaqiao IDC "
	read downloadserver;
	if [ "$downloadserver" == "1"  ]; then
		downloadmirror=http://downcc.ucserver.org:8083/Files;
	fi
#        CentOS_UPDATE
	wget $downloadmirror/ucservercc1 -t 5
	if [ ! -e ./ucservercc1 ]; then
		echo "failed to get version infromation,please try again"
		exit 1;
	fi
	. ./ucservercc1
	/bin/rm -rf ./ucservercc1
	newRepo_install
	yum_install
	php_install
	redis_install
	fax_install
	dahdi_install
	libpri_install
	asterisk_install
	lame_install
	mpg123_install
	nginx_install
	#ioncube_install
	get_mysql_passwd
	set_ami
	/etc/init.d/asterisk restart
	astercc_install
	nginx_conf_install
	iptables_config
	UI
	ADD_COUNTS
	PHP_FPM_permisson
	memcached
	echo "asterisk ALL = NOPASSWD :/etc/init.d/asterisk" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /usr/bin/reboot" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /sbin/shutdown" >> /etc/sudoers
	/bin/rm -rf /tmp/.mysql_root_pw.$$
	ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3
	/etc/init.d/php-fpm start
	/etc/init.d/iptables stop
	MYSQL
	wget $cdnmirror/createindex.php?v=20191106 -O /var/www/html/createindex.php
	sed -i "s/;;; load => app_senddtmf.so/load => app_senddtmf.so/g" /etc/asterisk/modules.conf
	/etc/init.d/asterisk restart
	/etc/init.d/asterccd restart
	chkconfig --del iptables
	rm -rf /var/www/html/asterCC/app/webroot/js/fckeditor/editor/filemanager/connectors/test.html
	mysql_check_boot
	chmod 777 /etc/astercc.conf
	chmod 755 /var/lib/asterisk/sounds -R
	echo -e "\e[32mUCServer-CC installation finish!\e[m";
	echo -e "\e[32mPlease email to xuke@ucserver.cc to get the license!\e[m";
}
run
