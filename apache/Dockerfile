FROM ubuntu:24.04

# Install Apache2, the same package you installed on your Ubuntu VM
RUN apt-get update && \
    apt-get install -y apache2 && \
    rm -rf /var/lib/apt/lists/*

# YOUR TURN: Enable the two Apache modules that allow it to forward
RUN a2enmod proxy proxy_http
# requests to another service (Flask).
# The command is a2enmod, and the two modules are: proxy and proxy_http
# Syntax: RUN a2enmod <module1> <module2>

# RUN a2enmod ___________ ___________

# Copy our virtual host config into Apache's sites-available directory,
# then enable it and disable the default placeholder site.
COPY flask-app.conf /etc/apache2/sites-available/flask-app.conf
RUN a2ensite flask-app && a2dissite 000-default

# Copy the frontend dashboard into Apache's document root.
# Apache will serve this as a static file when a browser hits port 80.
COPY index.html /var/www/html/index.html

EXPOSE 80

# YOUR TURN: Start Apache so Docker can manage it.
# Normally Apache runs quietly in the background (daemonized).
# In Docker, the container stops the moment its main process exits
# so Apache must stay in the foreground. The flag for that is: -D FOREGROUND
# The command to start Apache is: apache2ctl
# Syntax: CMD ["command", "flag-name", "flag-value"]

# CMD ["___________", "___________", "___________"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
