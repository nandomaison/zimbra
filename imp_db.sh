#!/bin/bash
source /opt/zimbra/bin/zmshutil
zmsetvars

function geraLog(){
	sudo  echo "$(date +%d/%m/%Y)-$(date +%k:%M:%S) - INFO - $1" >> /var/log/sync.log
}

# LIMPEZA DE BASE DE DADOS
geraLog "Limpeza de database iniciada."
geraLog "Mysql iniciado para import."
mysql.server start
for db in $(cat /tmp/dump/*.sql |awk -F "." '{print $1}');do
    mysql -u root --password=$mysql_root_password -e "drop database $db"
done
mysql.server stop
rm -rf /opt/zimbra/db/data/ib*
geraLog "Limpeza de database terminada."

# IMPORT DE DADOS
mysql.server start
geraLog "Import de database iniciado."
for db in $(ls /tmp/dump/*.sql);do
	mysql -e "create database $db character set utf8";
	mysql --user=root --password=$mysql_root_password < /tmp/dump/$db.sql
done
mysql.server stop
geraLog "Mysql parado depois de import."
geraLog "Import de database terminado."
