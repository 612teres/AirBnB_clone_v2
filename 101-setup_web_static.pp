# Define nginx class
class { 'nginx':
  manage_repo => true,
  package_ensure => 'latest',
  service_ensure => 'running',
  service_enable => true,
}

# Define nginx server configuration
file { '/etc/nginx/sites-available/default':
  ensure  => file,
  content => @("CONFIG"),
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_name _;
	index index.html index.htm;
	error_page 404 /404.html;
	add_header X-Served-By $hostname;

	location / {
		root /var/www/html/;
		try_files $uri $uri/ =404;
	}

	location /hbnb_static/ {
		alias /data/web_static/current/;
		try_files $uri $uri/ =404;
	}

	if ($request_filename ~ redirect_me) {
		rewrite ^ https://sketchfab.com/bluepeno/models permanent;
	}

	location = /404.html {
		root /var/www/error/;
		internal;
	}
}
CONFIG
}

# Define home page content
file { '/var/www/html/index.html':
  ensure  => file,
  content => 'Hello World!',
}

# Define 404 page content
file { '/var/www/error/404.html':
  ensure  => file,
  content => "Ceci n'est pas une page",
}

# Create web_static directories and set permissions
file { ['/data/web_static/releases/test', '/data/web_static/shared']:
  ensure => directory,
}

# Define home page content for test release
file { '/data/web_static/releases/test/index.html':
  ensure  => file,
  content => "<!DOCTYPE html><html lang='en-US'><head><title>Home - AirBnB Clone</title></head><body><h1>Welcome to AirBnB!</h1></body></html>",
}

# Create symbolic link for current release
file { '/data/web_static/current':
  ensure  => link,
  target  => '/data/web_static/releases/test/',
  require => File['/data/web_static/releases/test/index.html'],
}

# Set ownership for web_static directory
file { '/data':
  owner   => 'ubuntu',
  group   => 'ubuntu',
  recurse => true,
}

# Notify nginx service to reload configuration
service { 'nginx':
  ensure  => running,
  require => [
    File['/var/www/html/index.html'],
    File['/var/www/error/404.html'],
    File['/data/web_static/releases/test/index.html'],
    File['/data/web_static/current'],
    File['/etc/nginx/sites-available/default'],
  ],
  subscribe => File['/etc/nginx/sites-available/default'],
}
