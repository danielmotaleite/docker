# based in https://github.com/ktwe/docker-backuppc
FROM debian:jessie-backports

MAINTAINER daniel.leite@jumia.com

VOLUME ["/var/lib/backuppc"]

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y supervisor debconf-utils msmtp netcat && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections && \
    echo "backuppc backuppc/configuration-note note" | debconf-set-selections && \
    echo "backuppc backuppc/restart-webserver boolean true" | debconf-set-selections && \
    echo "backuppc backuppc/reconfigure-webserver multiselect apache2" | debconf-set-selections

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y backuppc apache2-utils && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisord.conf
COPY msmtprc /var/lib/backuppc/.msmtprc.dist
COPY run.sh /usr/local/sbin/run.sh

RUN sed -i 's/\/usr\/sbin\/sendmail/\/usr\/bin\/msmtp/g' /etc/backuppc/config.pl && \
    chmod 0755 /usr/local/sbin/run.sh

ENV MAILHOST aspmx.l.google.com.
ENV FROM sysadmin@domain

EXPOSE 80
VOLUME ["/etc/backuppc"]

CMD ["/usr/local/sbin/run.sh"]

