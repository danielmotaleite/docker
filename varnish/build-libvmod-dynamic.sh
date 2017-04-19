#/bin/bash
set -x
export LC_ALL=C.UTF-8
cd /usr/src/ || exit
apt-get install pkg-config automake libtool python-docutils debhelper
apt-get install varnish varnish-dev

test -d libvmod-dynamic || git clone https://github.com/nigoroll/libvmod-dynamic.git
cd libvmod-dynamic
git pull
if fgrep -q www.localhost /etc/hosts ; then
	echo hosts ok
else
	cat <<EOF >> /etc/hosts
127.0.0.1 www.localhost img.localhost
EOF
/etc/init.d/dnsmasq restart
fi

gpg --recv-key 335B21B2
# fix version and dependency name for new varnish versions
sed -i 's/4\.1\.1/5.1.1/g ; s/libvarnishapi-dev/varnish-dev/g' debian/control

./autogen.sh
dpkg-buildpackage && echo done
dpkg -i /usr/src/libvmod-dynamic_0.2_amd64.deb

echo "all done"

