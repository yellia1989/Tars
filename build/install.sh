#!/bin/bash

PWD_DIR=`pwd`
MachineIp=
MachineName=
MysqlIncludePath=
MysqlLibPath=


##��װglibc-devel

yum install -y glibc-devel

##��װflex��bison

yum install -y flex bison

##��װcmake

tar zxvf cmake-2.8.8.tar.gz
cd cmake-2.8.8
./bootstrap
make
make install
cd -

## ��װmysql
yum install -y ncurses-devel
yum install -y zlib-devel

if [   ! -n "$MysqlIncludePath"  ] 
  then
	tar zxvf mysql-5.6.26.tar.gz
	cd mysql-5.6.26
	cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql-5.6.26 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DMYSQL_USER=mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci
	make
	make install
	ln -s /usr/local/mysql-5.6.26 /usr/local/mysql
	cd -
  else
  	## ����mysql ��·�� ���� ����framework/CMakeLists.txt tarscpp/CMakeList.txt
  	sed -i "s@/usr/local/mysql/include@${MysqlIncludePath}@g" ../framework/CMakeLists.txt
  	sed -i "s@/usr/local/mysql/lib@${MysqlLibPath}@g" ../framework/CMakeLists.txt
  	sed -i "s@/usr/local/mysql/include@${MysqlIncludePath}@g" ../framework/tarscpp/CMakeLists.txt
  	sed -i "s@/usr/local/mysql/lib@${MysqlLibPath}@g" ../framework/tarscpp/CMakeLists.txt

fi


yum install -y perl
cd /usr/local/mysql
useradd mysql
rm -rf /usr/local/mysql/data
mkdir -p /data/mysql-data
ln -s /data/mysql-data /usr/local/mysql/data
chown -R mysql:mysql /data/mysql-data /usr/local/mysql/data
cp support-files/mysql.server /etc/init.d/mysql

yum install -y perl-Module-Install.noarch
perl scripts/mysql_install_db --user=mysql
cd -

sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./conf/*`
cp ./conf/my.cnf /usr/local/mysql/

##����mysql
service mysql start
chkconfig mysql on

##���mysql��bin·��
echo "PATH=\$PATH:/usr/local/mysql/bin" >> /etc/profile
echo "export PATH" >> /etc/profile
source /etc/profile

##�޸�mysql root����
cd /usr/local/mysql/
./bin/mysqladmin -u root password 'root@appinside'
./bin/mysqladmin -u root -h ${MachineName} password 'root@appinside'
cd -

##���mysql�Ŀ�·��
echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf
ldconfig

##����C++����������
yum install -y git
cd ../
git submodule update --init --recursive framework
cd -

##��װc++���Կ��
cd ../framework/build/
chmod u+x build.sh
./build.sh all
./build.sh install
cd -

##Tars���ݿ⻷����ʼ��
mysql -uroot -proot@appinside -e "grant all on *.* to 'tars'@'%' identified by 'tars2015' with grant option;"
mysql -uroot -proot@appinside -e "grant all on *.* to 'tars'@'localhost' identified by 'tars2015' with grant option;"
mysql -uroot -proot@appinside -e "grant all on *.* to 'tars'@'${MachineName}' identified by 'tars2015' with grant option;"
mysql -uroot -proot@appinside -e "flush privileges;"

cd ../framework/sql/
sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./*`
chmod u+x exec-sql.sh
./exec-sql.sh
cd -

##�����ܻ�������
cd ../framework/build/
make framework-tar

make tarsstat-tar
make tarsnotify-tar
make tarsproperty-tar
make tarslog-tar
make tarsquerystat-tar
make tarsqueryproperty-tar
cd -

##��װ���Ļ�������
mkdir -p /usr/local/app/tars/
cd ../framework/build/
cp framework.tgz /usr/local/app/tars/
cd /usr/local/app/tars
tar xzfv framework.tgz

sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./*`
sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`

chmod u+x tars_install.sh
./tars_install.sh

./tarspatch/util/init.sh

##��װnodejs����
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
source ~/.bashrc
nvm install v8.11.3

##��װweb����ϵͳ
cd ../
git submodule update --init --recursive web
cd web/
npm install -g pm2 --registry=https://registry.npm.taobao.org
sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry1.tars.com -rl ./config/*`
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./config/*`
npm install --registry=https://registry.npm.taobao.org
npm run prd

cd -

mkdir -p /data/log/tars/

