# Docker compose file for lamp

## Config Folder

- **_initdb_** - add database we want to import during initial container creation.
- **_php_** - It contains php.ini conf file which will over ride all setting write in this file with the default file in docker container.
- **_ssl_** - save ssl cretificate format is as per vhost conf file in this folder this folder later mount on apache container if 443 port open with ssl conf enable.
- **_vhost_** - vhost host conf files that will be mount in apache container.

## log folder

**Apahce and Mysql** Logs can be views in this folder if want to change this location we can change it with .env file.

## www folder

Put main webiste here that we want to display

## .env

All environment variable that we need to create lamp containers.
Check update of nginx
