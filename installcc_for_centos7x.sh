#!/bin/bash

# By Bob  #### 改为UCServer UI，更新自2018年8月06日
# 为了应对centos 6x即将退市，centos 7x上市，拥抱centos 7吧！
function newRepo_install(){
	cd /usr/src
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
	wget -O /etc/yum.repos.d/CentOS-Base.repo $cdnmirror/Centos-7.repo
#	mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
	yum -y install epel-release
	rpm -Uvh https://rhel7.iuscommunity.org/ius-release.rpm
	useradd -u 500 -c "Asterisk PBX" -d /var/lib/asterisk asterisk
}

function mariaDB_install(){
	yum -y install https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
	yum install -y mysql-community-server
	systemctl start mysqld
	systemctl enable mysqld
	systemctl stop mysqld
	wget $downloadmirror/percona/my1.cnf -O /etc/my.cnf
	systemctl  enable crond
	systemctl  restart mysqld
	mysql -uroot -e "update user set authentication_string=password('') where User='root' and Host='localhost'" mysql
	mysql -uroot -e "flush privileges"
	wget $downloadmirror/percona/my2.cnf -O /etc/my.cnf
	systemctl restart mysqld
	mysql --connect-expired-password -uroot -e "set password = password('')"
}

function yum_install(){
	yum -y remove php* 
	yum -y remove asterisk*
	yum -y install libpcap-devel libaio bash openssl openssh-server openssh-clients tcpdump wget mlocate openvpn ghostscript mailx cpan crontabs glibc gcc-c++ libtermcap-devel newt newt-devel ncurses ncurses-devel libtool libxml2-devel kernel-devel  subversion flex libstdc++-devel libstdc++  unzip sharutils openssl-devel make kernel-headers
	yum -y install numactl perl perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version nscd iptables-services htop
	yum -y install sqlite-devel libuuid-devel pciutils samba cifs-utils
	yum -y install speex-tools flac
	yum -y install hwloc ftp libmicrohttpd gnutls bzip2
	yum -y install ntp
	yum -y install sox
	systemctl restart ntpd
	systemctl enable ntpd
	systemctl restart crond
	systemctl restart nscd
	systemctl enable nscd
}

function php_install(){
	echo -e "\e[32mStarting Install PHP-Fpm\e[m"
	yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	yum install -y yum-utils
	yum-config-manager --enable remi-php56
	yum install -y libtomcrypt
	yum install -y php56-php-xml php56-php-pecl-jsonc php56-php-pecl-redis php56-php-gd php56-php-opcache php56-php-cli php-getid3 php56-php-pecl-igbinary php56-php-pecl-geoip php56-php-ioncube-loader php56-php-soap php56-php-common php56-php-pdo php-pecl-pthreads php56-php-mbstring php56-php-process php56-php-pear php56-php-pecl-uuid php56-php-smbclient php56-php-mysqlnd php56-php-fpm php56-php-xmlrpc php56-php-pecl-crypto php56-php-mcrypt php56-php-pecl-zip 
	mkdir -p /opt/remi/php56/root/var/lib/php/session
	chown asterisk.asterisk /opt/remi/php56/root/var/lib/php/session
	chown asterisk.asterisk /opt/remi/php56/root/var/lib/php/wsdlcache
	sed -i "s/short_open_tag = Off/short_open_tag = On/" /opt/remi/php56/root/etc/php.ini
	sed -i "s/memory_limit = 16M /memory_limit = 128M /" /opt/remi/php56/root/etc/php.ini
	sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 40M /" /opt/remi/php56/root/etc/php.ini
	sed -i "s/post_max_size = 8M/post_max_size = 40M/" /opt/remi/php56/root/etc/php.ini
	sed -i '/^error_reporting/c error_reporting = E_ALL & ~E_DEPRECATED' /opt/remi/php56/root/etc/php.ini
	sed -i "s/user = apache/user = asterisk/" /opt/remi/php56/root/etc/php-fpm.d/www.conf
	sed -i "s/group = apache/group = asterisk/" /opt/remi/php56/root/etc/php-fpm.d/www.conf
	rm -rf /usr/bin/php
	ln -s /opt/remi/php56/root/bin/php /usr/bin/php
	systemctl start php56-php-fpm
	systemctl enable php56-php-fpm
	echo -e "\e[32mPHP-Fpm Install OK!\e[m"
}

function redis_install(){
	yum -y install redis
	systemctl start redis
	systemctl enable redis
	echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >>/etc/rc.local
	echo -e "\e[32mRedis server Install OK\e[m"
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
		wget $cdnmirror/Files/dahdi-linux-complete-$dahdiver.tar.gz?v=1 -O dahdi-linux-complete-$dahdiver.tar.gz
		if [ ! -e ./dahdi-linux-complete-$dahdiver.tar.gz ]; then
		wget $cdnmirror/Files/dahdi-linux-complete-$dahdiver.tar.gz?v=1 -O dahdi-linux-complete-$dahdiver.tar.gz
		fi
	fi
	tar zxvf dahdi-linux-complete-$dahdiver.tar.gz
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
	ldconfig
	/usr/sbin/dahdi_genconf
	wget $downloadmirror/dahdi -O /etc/init.d/dahdi
	chmod +x /etc/init.d/dahdi
	/etc/init.d/dahdi start
	/sbin/chkconfig dahdi on
	systemctl daemon-reload
	echo -e "\e[32mDAHDI Install OK!\e[m"
}

function nginx_install(){
	echo -e "\e[32mStarting install nginx\e[m"
	systemctl stop httpd
	systemctl disable httpd
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
	cat > /lib/systemd/system/nginx.service << EOF
	[Unit]
Description=nginx
After=network.target
  
[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true
  
[Install]
WantedBy=multi-user.target
EOF
	systemctl start nginx.service
	systemctl enable nginx.service
	echo -e "\e[32mNginx Install OK!\e[m"
}

function asterisk_install() {
	echo -e "\e[32mStarting Install Asterisk\e[m"
	yum -y install subversion
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
	sed -i 's/bindaddr = 0.0.0.0/bindaddr = 127.0.0.1/' /etc/asterisk/manager.conf
	/etc/init.d/asterisk restart
	systemctl enable asterisk
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
echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
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
}

function ifconfig_change() {
	echo -e "\e[32mInstall ifconfig command from centos 6\e[m"
	mv /sbin/ifconfig /sbin/ifconfig.bak
	wget http://qiniucdn.ucserver.org/sbin/ifconfig -O /sbin/ifconfig
	chmod +x /sbin/ifconfig
	echo -e "\e[32mInstall ifconfig command OK\e[m"
}

function astercc_install() {
	/etc/init.d/asterisk restart
	echo -e "\e[32mStarting Install UCServer-CC\e[m"
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


function MYSQL(){
	systemctl stop mysqld
	sleep 15
	rm -rf /etc/my.cnf
	wget http://downcc.ucserver.org:8085/Files/my.cnf.percona -O /etc/my.cnf
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

function UI() {
	mkdir -p /usr/src/UI
	cd /usr/src/UI
	echo "Start setting UCServer UI"
	wget http://downcc.ucserver.org:8085/Files/UCS-UI.tar.gz
	wget http://downcc.ucserver.org:8085/Files/update.sh
	bash /usr/src/UI/update.sh
	rm -rf /usr/src/UI
}

function CHANGE_DNS(){
#	echo "nameserver 223.5.5.5">>/etc/resolv.conf
#	echo "nameserver 223.6.6.6">>/etc/resolv.conf
	echo "change_dns"
}
function ADD_COUNTS(){
	echo "Add counts information"
	cd /var/www/html
	wget http://downcc.ucserver.org:8085/Files/count.php
	wget http://downcc.ucserver.org:8085/Files/clean.php
	echo "0 * * * * php /var/www/html/count.php >/dev/null 2>&1" >> /var/spool/cron/root
	echo "0 5 * * * php /var/www/html/clean.php >/dev/null 2>&1" >> /var/spool/cron/root
	echo "0 1 * * * php /var/www/html/createindex.php >/dev/null 2>&1" >> /var/spool/cron/root
	echo "0 3 * * * chown asterisk.asterisk /var/spool/asterisk/monitor >/dev/null 2>&1" >> /var/spool/cron/root
}
function mysql_check_boot(){
	PASSWD=`cat /etc/astercc.conf |grep password|awk '{print $3}'|awk 'NR==1'`
	echo "/usr/bin/mysqlcheck -uroot -p$PASSWD -r astercc10" >>/etc/rc.local
}
function PHP_FPM_permisson(){
	cat > /opt/remi/php56/root/etc/php-fpm.d/www.conf << EOF
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
pm.status_path = /php-status
slowlog = /opt/remi/php56/root/var/log/php-fpm/www-slow.log
rlimit_files = 65536
php_admin_value[error_log] = /opt/remi/php56/root/var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /opt/remi/php56/root/var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /opt/remi/php56/root/var/lib/php/wsdlcache
EOF
	}
function get_sngrep {
	wget $downloadmirror/Files/sngrep -O /usr/local/bin/sngrep
	chmod +x /usr/local/bin/sngrep
	}
function run() {
	CHANGE_DNS
	downloadmirror=http://downcc.ucserver.org:8085
	cdnmirror=http://qiniucdn.ucserver.org
	echo "please select the mirror you want to download from:"
	echo "1: Shanghai Huaqiao IDC "
	read downloadserver;
	if [ "$downloadserver" == "1"  ]; then
		downloadmirror=http://downcc.ucserver.org:8085/Files;
	fi
#        CentOS_UPDATE
	wget $downloadmirror/ucserver_centos7_1 -t 5
	if [ ! -e ./ucserver_centos7_1 ]; then
		echo "failed to get version infromation,please try again"
		exit 1;
	fi
	. ./ucserver_centos7_1
	/bin/rm -rf ./ucserver_centos7_1
	newRepo_install
	yum_install
	mariaDB_install
	php_install
	redis_install
	dahdi_install
	libpri_install
	asterisk_install
	lame_install
	mpg123_install
	nginx_install
	get_mysql_passwd
	set_ami
	/etc/init.d/asterisk restart
	ifconfig_change
	ln -s /opt/remi/php56/root/var/log/php-fpm/ /var/log/php-fpm
	astercc_install
	nginx_conf_install
	iptables_config
	UI
	ADD_COUNTS
	PHP_FPM_permisson
	mysql_check_boot
	echo "asterisk ALL = NOPASSWD: /etc/init.d/asterisk" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /usr/bin/reboot" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /sbin/shutdown" >> /etc/sudoers
	/bin/rm -rf /tmp/.mysql_root_pw.$$
	ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3
	systemctl restart php56-php-fpm.service
	wget $cdnmirror/createindex.php?v=20170613 -O /var/www/html/createindex.php
	sed -i '/^pid_file/c pid_file = /var/run/asterccc.pid' /etc/astercc.conf
	MYSQL
	systemctl restart mysqld
	sed -i "s/;;; load => app_senddtmf.so/load => app_senddtmf.so/g" /etc/asterisk/modules.conf
	systemctl daemon-reload
	/etc/init.d/asterisk restart
	systemctl restart asterccd
	rm -rf /var/www/html/asterCC/app/webroot/js/fckeditor/editor/filemanager/connectors/test.html
	chmod 777 /etc/astercc.conf
	chmod 755 /var/lib/asterisk/sounds -R
	systemctl enable asterccd
	systemctl restart nginx.service
	systemctl restart php56-php-fpm.service
	get_sngrep
	echo -e "\e[32mUCServer-CC installation finish!\e[m";
	echo -e "\e[32mPlease email to xuke@ucserver.cc to get the license!\e[m";
}
run
