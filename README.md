## Introduction
This is a Dockerfile to build a container image for nginx and php-fpm. The container can use environment variables to configure your web application using the templating detailed in the special features section.
### Git reposiory
The source files for this project can be found here: [https://github.com/kingcody/docker-php](https://github.com/kingcody/docker-php)

If you have any improvements please submit a pull request.
### Docker hub repository
The Docker hub build can be found here: [https://registry.hub.docker.com/u/kingcody/php/](https://registry.hub.docker.com/u/kingcody/php/)

### Nginx Version: 1.9.5

## Installation
Pull the image from the docker index rather than downloading the git repo. This prevents you having to build the image on every docker host.

```
docker pull kingcody/php:nginx
```

## Running
To simply run the container:

```
sudo docker run --name php-nginx -p 8080:80 -d kingcody/php:nginx
```
You can then browse to http://\<docker_host\>:8080 to view the default install files.
### Volumes
If you want to link to your web site directory on the docker host to the container run:

```
sudo docker run --name php-nginx -p 8080:80 -v /your_code_directory:/usr/share/nginx/html -d kingcody/php:nginx
```
### Linking
Linking to containers also exposes the linked container environment variables which is useful for templating and configuring web apps.

Run MySQL container with some extra details:

```
sudo docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=yayMySQL -e MYSQL_DATABASE=wordpress -e MYSQL_USER=wordpress_user -e MYSQL_PASSWORD=wordpress_password -d mysql
```

This exposes the following environment variables to the container when linked:

```
MYSQL_ENV_MYSQL_DATABASE=wordpress
MYSQL_ENV_MYSQL_ROOT_PASSWORD=yayMySQL
MYSQL_PORT_3306_TCP_PORT=3306
MYSQL_PORT_3306_TCP=tcp://172.17.0.236:3306
MYSQL_ENV_MYSQL_USER=wordpress_user
MYSQL_ENV_MYSQL_PASSWORD=wordpress_password
MYSQL_ENV_MYSQL_VERSION=5.6.22
MYSQL_NAME=/sick_mccarthy/mysql
MYSQL_PORT_3306_TCP_PROTO=tcp
MYSQL_PORT_3306_TCP_ADDR=172.17.0.236
MYSQL_ENV_MYSQL_MAJOR=5.6
MYSQL_PORT=tcp://172.17.0.236:3306

```

To link the container launch like this:

```
sudo docker run -p 8080:80 --link some-mysql:mysql -d kingcody/php:nginx
```
### Enabling SSL or Special Nginx Configs
As with all docker containers its possible to link resources from the host OS to the guest. This makes it really easy to link in custom nginx default config files or extra virtual hosts and SSL enabled sites. For SSL sites first create a directory somewhere such as */opt/deployname/ssl/*. In this directory drop you SSL cert and Key in. Next create a directory for your custom hosts such as  */opt/deployname/sites-enabled*. In here load your custom default.conf file which references your SSL cert and keys at the location, for example:  */etc/nginx/ssl/xxxx.key*

Then start your container and connect these volumes like so:

```
sudo docker run -v /opt/deployname/ssl:/etc/nginx/ssl -v /opt/deployname/sites-enabled:/etc/nginx/sites-enabled -p 8080:80 --link some-mysql:mysql -d kingcody/php:nginx
```

## Special Features

### Templating
This container will automatically configure your web application if you template your code. For example if you are linking to MySQL like above, and you have a config.php file where you need to set the MySQL details include $$_MYSQL_ENV_MYSQL_DATABASE_$$ style template tags.

Example:

```
<?php
database_name = $$_MYSQL_ENV_MYSQL_DATABASE_$$;
database_host = $$_MYSQL_PORT_3306_TCP_ADDR_$$;
...
?>
```

### Using environment variables
If you want to link to an external MySQL DB and not using linking you can pass variables directly to the container that will be automatically configured by the container.

Example:

```
sudo docker run -e 'MYSQL_HOST=host.x.y.z' -e 'MYSQL_USER=username' -e 'MYSQL_PASS=password' -p 8080:80 -d kingcody/php:nginx
```

This will expose the following variables that can be used to template your code.

```
MYSQL_HOST=host.x.y.z
MYSQL_USER=username
MYSQL_PASS=password
```
To use these variables in a template you'd do the following in your file:

```
<?php
database_host = $$_MYSQL_HOST_$$;
database_user = $$_MYSQL_USER_$$;
database_pass = $$_MYSQL_PASS_$$
...
?>
```
### Skip Templating
In order to speed up install time if templating is not required and you have a lot of files in your web root that you don't wish to be scanned, simply include the flag below:

```-e TEMPLATE_NGINX_HTML=0```

### Template anything
Yes ***ANYTHING***, any variable exposed by a linked container or the **-e** flag lets you template your config files. This means you can add redis, mariaDB, memcache or anything you want to your application very easily.

