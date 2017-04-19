FROM debian:jessie-backports

RUN echo 'Yes, do as I say!' | apt-get purge -y --force-yes  login acl bash bsdutils debconf-i18n e2fslibs:amd64 \
 gcc-4.8-base:amd64 inetutils-ping insserv iproute2 libblkid1:amd64 libcomerr2:amd64 libdebconfclient0:amd64 \
 libgcrypt20:amd64 libgpg-error0:amd64 libkmod2:amd64 liblocale-gettext-perl libmount1:amd64 libncurses5:amd64 \
 libncursesw5:amd64 libprocps3:amd64 libslang2:amd64 libsmartcols1:amd64 libss2:amd64 libsystemd0:amd64 \
 libtext-charwidth-perl libtext-iconv-perl libtext-wrapi18n-perl libudev1:amd64 libuuid1:amd64 lsb-base mount \
 ncurses-base ncurses-bin netbase startpar systemd systemd-sysv sysv-rc sysvinit-utils tzdata cpio \
 libpng12-0 libpam-modules+ debconf+  perl-base+ && \
 echo "APT::Install-Recommends "0" ;APT::Install-Suggests "0" ;" >>  /etc/apt/apt.conf

RUN apt-get update && \
 apt-get upgrade -y && \
 apt-get clean -y && \
 apt-get autoclean -y && \
 apt-get autoremove -y && \
 rm -rf /usr/share/locale/* && \
 rm -rf /usr/share/man/* && \
 rm -rf /var/cache/debconf/*-old && \
 rm -rf /var/lib/apt/lists/* && \
 rm -rf /usr/share/doc/*

CMD /bin/dash
