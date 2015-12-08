#!/bin/bash

# Auto install astercc commercial and related packages
# By Solo #### solo@astercc.org last modify 2012-04-17
# By Solo #### solo@astercc.org last modify 2013-02-06 for asterCC 1.2-beta
# By Solo #### solo@astercc.org last modify 2013-05-20, 修正了asterisk总是使用asterccuser asterccsecret作为AMI用户的bug
# By Solo #### solo@astercc.org last modify 2014-02-07, 禁用了netjet dahdi驱动
# By Bob  #### 改为UCServer UI，更新自2015年9月8日

# uname -r, 如果包含-pve, 需要到/usr/src执行
# ln -s kernels/2.6.18-308.4.1.el5-x86_64/ linux 

function newRepo_install(){
	cd /usr/src
	version=`cat /etc/issue|grep -o 'release [0-9]\+'`
	arch=i386
  bit=`getconf LONG_BIT`
  if [ $bit == 64 ]; then
		arch=x86_64
	fi;
	if [ "$version" == "release 6" ]; then
		rpm -ivh  http://mirrors.aliyun.com/epel/epel-release-latest-6.noarch.rpm
		rpm -ivh  http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
		mv /etc/yum.repos.d/remi.repo /etc/yum.repos.d/remi.repo.bak
	#	cd /etc/yum.repos.d
		wget -O /etc/yum.repos.d/remi.repo $downloadmirror/remi.repo
		rpm -ivh http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
		yum-config-manager --disable mysql55-community
		yum-config-manager --enable mysql56-community
		yum-config-manager --disable mysql57-community-dmr
	else
		echo "Sorry,the UCServer-CC must be installed the Centos 6x"
		exit 0
	fi

#	sed -i "s/mirrorlist/#mirrorlist/" /etc/yum.repos.d/ius.repo
#	sed -i "s/#baseurl/baseurl/" /etc/yum.repos.d/ius.repo
}

function yum_install(){
	#yum -y upgrade
	yum -y remove php* 
	yum -y remove asterisk*
	yum -y install bash openssl openssh-server openssh-clients tcpdump wget mlocate openvpn ghostscript mailx cpan crontabs mysql-community-server glibc gcc-c++ libtermcap-devel newt newt-devel ncurses ncurses-devel libtool libxml2-devel kernel-devel kernel-PAE-devel subversion flex libstdc++-devel libstdc++  unzip sharutils openssl-devel make kernel-header zlib-devel
	chkconfig mysqld on
	chkconfig crond on
	service crond start
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
	if [ -e /etc/php.ini.rpmnew -a ! -e /etc/php.ini ]; then
		cp /etc/php.ini.rpmnew /etc/php.ini
	fi
	INIFILE=/opt/remi/php55/root/etc/php.ini
	WWWFILE=/opt/remi/php55/root/etc/php-fpm.d/www.conf
	yum -y install php55-php-fpm php55-php-cli pcre-devel php55-php-mysqlnd sox php55-php-gd php55-php-mbstring php55-php-ioncube-loader php55-php-pecl-redis
	sed -i "s/short_open_tag = Off/short_open_tag = On/" $INIFILE 
	sed -i "s/memory_limit = 16M /memory_limit = 128M /" $INIFILE
	sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 40M /" $INIFILE
	sed -i "s/post_max_size = 8M/post_max_size = 40M/" $INIFILE
	sed -i '/^error_reporting/c error_reporting = E_ALL & ~E_DEPRECATED' $INIFILE
	sed -i "s/user = apache/user = asterisk/" $WWWFILE
	sed -i "s/group = apache/group = asterisk/" $WWWFILE
	chkconfig php55-php-fpm on
	echo -e "\e[32mPHP-Fpm Install OK!\e[m"
}
function redis_install(){
	yum -y install redis
	/etc/init.d/redis start
	chkconfig --level 2345 redis on
	echo -e "\e[32Redis server Install OK\e[m"
}
function fax_install(){
	echo -e "\e[32mStarting Install FAX\e[m"
  version=`cat /etc/issue|grep -o 'release [0-9]\+'`
	cd /usr/src
	#yum -y install hylafax
	yum -y install libtiff libtiff-devel

  bit=`getconf LONG_BIT`
  if [ $bit == 32 ]; then
    if [ "$version" == "release 6" ]; then
  		if [ ! -e ./hylafax-client-6.0.6-1rhel6.i686.rpm ]; then
        wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-client-6.0.6-1rhel6.i686.rpm
  		fi
	  	if [ ! -e ./hylafax-server-6.0.6-1rhel6.i686.rpm ]; then
        wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-server-6.0.6-1rhel6.i686.rpm
  		fi
    else
      if [ ! -e ./hylafax-client-6.0.6-1rhel5.i386.rpm ]; then
        wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-client-6.0.6-1rhel5.i386.rpm
      fi
      if [ ! -e ./hylafax-server-6.0.6-1rhel5.i386.rpm ]; then
        wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-server-6.0.6-1rhel5.i386.rpm
      fi
    fi
	else
    if [ "$version" == "release 6" ]; then
      if [ ! -e ./hylafax-server-6.0.6-1rhel6.x86_64.rpm ]; then
        wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-server-6.0.6-1rhel6.x86_64.rpm
      fi
      if [ ! -e ./hylafax-client-6.0.6-1rhel6.x86_64.rpm ]; then
        wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-client-6.0.6-1rhel6.x86_64.rpm
      fi
    else
  		if [ ! -e ./hylafax-server-6.0.6-1rhel5.x86_64.rpm ]; then
	  		wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-server-6.0.6-1rhel5.x86_64.rpm
  		fi
	  	if [ ! -e ./hylafax-client-6.0.6-1rhel5.x86_64.rpm ]; then
		  	wget ftp://ftp.hylafax.org/binary/linux/redhat/6.0.6/hylafax-client-6.0.6-1rhel5.x86_64.rpm
  		fi
    fi
	fi

	rpm -ivh hylafax-*

	if [ ! -e ./iaxmodem-1.2.0.tar.gz ]; then
		wget http://sourceforge.net/projects/iaxmodem/files/latest/download?source=files -O iaxmodem-1.2.0.tar.gz
	fi
	tar zxf iaxmodem-1.2.0.tar.gz
	cd iaxmodem-1.2.0
	./configure
	make
	cp ./iaxmodem /usr/sbin/
  chmod 777 /var/spool/hylafax/bin
  chmod 777 /var/spool/hylafax/etc/
  chmod 777 /var/spool/hylafax/docq/
  chmod 777 /var/spool/hylafax/doneq/
  mkdir /etc/iaxmodem/
  chown asterisk.asterisk /etc/iaxmodem/
  mkdir /var/log/iaxmodem/
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
		wget http://downcc.ucserver.org:8082/Files/dahdi-linux-complete-$dahdiver.tar.gz
		if [ ! -e ./dahdi-linux-complete-$dahdiver.tar.gz ]; then
			wget http://downcc.ucserver.org:8082/dahdi-linux-complete-$dahdiver.tar.gz
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

function nginx_install(){
	echo -e "\e[32mStarting install nginx\e[m"
	service httpd stop
	chkconfig httpd off
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
		wget $downloadmirror/asterisk-$asteriskver.tar.gz
	fi
	tar zxf asterisk-$asteriskver.tar.gz
	if [ $? != 0 ]; then
		echo "fatal: dont have valid asterisk tar package"
		exit 1
	fi

	cd asterisk-$asteriskver
	./configure '-disable-xmldoc'
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

	sed -i 's/;enable=yes/enable=no/' /etc/asterisk/cdr.conf

	# set AMI user
cat > /etc/asterisk/manager.conf << EOF
[general]
enabled = yes
port = 5038
bindaddr = 0.0.0.0
displayconnects=no

[asterccuser]
secret = asterccsecret
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read = system,call,agent
write = all
EOF

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
worker_rlimit_nofile 655350;

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

    #keepalive_timeout  0;
    keepalive_timeout  65;

    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;

	push_stream_store_messages on;
	push_stream_shared_memory_size  256M;
	push_stream_message_ttl  15m;

    #gzip  on;
    server
    {
        listen       80 default;
        client_max_body_size 20M;
        index index.html index.htm index.php;
        root  /var/www/html/asterCC/app/webroot;

        location / {
          index index.php;

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

sysctl -p

service nginx restart
}

function astercc_install() {
	/etc/init.d/asterisk restart
	echo -e "\e[32mStarting Install AsterCC\e[m"
	cd /usr/src
	if [ ! -e ./astercc-$asterccver.tar.gz ]; then
		wget $downloadmirror/astercc-$asterccver.tar.gz -t 5
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
bindaddr = 0.0.0.0
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
	service mysqld start
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
	wget http://downcc.ucserver.org:8082/Files/UCS-UI.tar.gz
	wget http://downcc.ucserver.org:8082/Files/update.sh
	bash /usr/src/UI/update.sh
	rm -rf /usr/src/UI
}
function MYSQL(){
	/etc/init.d/mysqld stop
	sleep 15
	rm -rf /etc/my.cnf
	cd /etc/
	wget http://downcc.ucserver.org:8082/Files/my.cnf
	/etc/init.d/mysql start
}

function CHANGE_DNS(){
	echo "nameserver 114.114.114.114">/etc/resolv.conf
}
function ADD_COUNTS(){
	echo "Add counts information"
	cd /var/www/html
	wget http://downcc.ucserver.org:8082/Files/count.php
	wget http://downcc.ucserver.org:8082/Files/clean.php
	echo "0 * * * * php /var/www/html/count.php >/dev/null 2>&1" >> /var/spool/cron/root
	echo "0 5 * * * php /var/www/html/clean.php >/dev/null 2>&1" >> /var/spool/cron/root
}
function run() {
	CHANGE_DNS
	downloadmirror=http://downcc.ucserver.org:8082
	echo "please select the mirror you want to download from:"
	echo "1: Shanghai Huaqiao IDC "
	read downloadserver;
	if [ "$downloadserver" == "1"  ]; then
		downloadmirror=http://downcc.ucserver.org:8082/Files;
	fi

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
	echo "asterisk ALL = NOPASSWD :/etc/init.d/asterisk" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /usr/bin/reboot" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /sbin/shutdown" >> /etc/sudoers
	/bin/rm -rf /tmp/.mysql_root_pw.$$
	ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3
	/etc/init.d/php55-php-fpm start
	/etc/init.d/iptables stop
	#MYSQL
	/etc/init.d/asterccd restart
	chkconfig --del iptables
	echo -e "\e[32mUCServer-CC installation finish!\e[m";
	echo -e "\e[32mPlease email to xuke@ucserver.cc to get the license!\e[m";
}
run
