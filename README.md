iiplc
=====

Plack/Perl web client for ii network

# Reqs

* SQL::Abstract;
* DBD::SQlite;
* Plack;
* HTML::Template;
* LWP; 

**Only GNU/Linux is supported**

# Install

Create dirrectories:
	mkdir {echo,msg}

Install packages.
On Debian based systems:
	
	apt-get install libplack-perl libhtml-template-perl libsql-abstract-perl \
	libdbd-sqlite3-perl libconfig-tiny-perl
