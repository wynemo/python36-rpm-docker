FROM centos:6.9

RUN yum groupinstall -y 'development tools'
RUN yum -y install ruby-devel gcc curl libyaml-devel rpm-build
RUN gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -L get.rvm.io | bash -s stable
RUN bash -c "source /etc/profile.d/rvm.sh;rvm requirements"
RUN bash -c "source /etc/profile.d/rvm.sh;rvm install 2.3.0"
RUN bash -c "source /etc/profile.d/rvm.sh;rvm use 2.3.0 --default"
#RUN bash -c "source /etc/profile.d/rvm.sh;rvm rubygems current"
RUN bash -c "source /etc/profile.d/rvm.sh;gem install fpm -N --version 1.11.0"
RUN yum -y install openssl-devel readline-devel\
    bzip2-devel sqlite-devel zlib-devel ncurses-devel\
    db4-devel expat-devel gdbm-devel
ENV BUILD_VER=3.6.10
ENV DLURL=http://python.org/ftp/python/${BUILD_VER}/Python-${BUILD_VER}.tgz
RUN mkdir -p /build; cd /build\
    && curl -L ${DLURL} | tar xz
RUN cd /build/Python-${BUILD_VER}\
    && ./configure --prefix=/usr/local\
          --enable-optimizations --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"  \
    && make -j2 && make install DESTDIR=/tmp/installdir
RUN echo 'echo /usr/local/lib > /etc/ld.so.conf.d/usr-local-lib.conf' > /tmp/installdir/run-ldconfig.sh
RUN echo '/sbin/ldconfig' >> /tmp/installdir/run-ldconfig.sh
RUN bash -c "find /usr/local/lib/python3.6/ -type d -name __pycache__ -exec rmdir {} \;"
RUN bash -c "find /usr/local/lib/python3.6/ -name "*.pyc" -exec rm -f {} \;"
RUN bash -c "source /etc/profile.d/rvm.sh;\
    fpm -s dir -t rpm -n python36 -v ${BUILD_VER} -C /tmp/installdir \
    --after-install /tmp/installdir/run-ldconfig.sh \
    -d 'openssl' \
    -d 'bzip2' \
    -d 'zlib' \
    -d 'expat' \
    -d 'sqlite' \
    -d 'ncurses' \
    -d 'readline' \
    -d 'gdbm' \
    --directories=/usr/local/lib/python3.6/ \
    --directories=/usr/local/include/python3.6m/ \
    usr/local"
