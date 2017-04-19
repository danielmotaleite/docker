# based in https://raw.githubusercontent.com/tutumcloud/varnish/master/4.0/Dockerfile
FROM debian:jessie-backports
MAINTAINER  daniel.leite@jumia.com
WORKDIR /srv

RUN	apt-get update && \
	apt-get -y dist-upgrade && \
	apt-get install -y curl supervisor libedit2 libjemalloc1 gcc libc6-dev && \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/*

RUN curl -sS https://repo.varnish-cache.org/GPG-key.txt | apt-key add - && \
	echo "deb http://repo.varnish-cache.org/debian/ jessie varnish-4.1" >> /etc/apt/sources.list.d/varnish-cache.list && \
	apt-get update && \
	apt-get -y install varnish && \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/*

COPY libvmod-dynamic_0.2_amd64.deb /tmp
RUN dpkg -i /tmp/libvmod-dynamic_0.2_amd64.deb && \
	rm /tmp/libvmod-dynamic_0.2_amd64.deb

#RUN curl -s http://repo.varnish-cache.org/pkg/5.0.0/varnish_5.0.0-1_amd64.deb > /tmp/varnish_5.0.0-1_amd64.deb && \
#	dpkg -i /tmp/varnish_5.0.0-1_amd64.deb && \
#	rm /tmp/varnish_5.0.0-1_amd64.deb


#ENV CONTENT -b backend:$BACKEND_PORT
# Or, if you want to use a VCL file, use the following:
#ENV CONTENT -f /etc/varnish/default.vcl
# Or, if you want to use a VCL file by passing the contents, use the following:
#ENV CONTENT_VCL <CONTENTS_OF_VCL_FILE>

# Varnish memory cache storage and size
ENV CACHE=malloc,1g \
	PORT=80 \
	VARNISHD_PARAMS="-p thread_pool_min=1000 -p thread_queue_limit=200 -p send_timeout=60"

EXPOSE $PORT

# add configs
COPY supervisord.conf  /etc/
COPY varnish/*         /etc/varnish/

CMD [ "supervisord", "-c", "/etc/supervisord.conf"]

ENV TERM="xterm"

