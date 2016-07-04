FROM alpine:3.4
MAINTAINER smizy

#ENV MESOS_VERSION   1.0.0-rc1
ENV MAVEN_VERSION   3.3.9

ENV JAVA_HOME   /usr/lib/jvm/default-jvm
ENV PATH        $PATH:${JAVA_HOME}/bin

RUN set -x \
    && apk update \
    && apk --no-cache add \
        bash \
        su-exec \ 
        wget \
    ### maven
    && mirror_url=$( \
        wget -q -O - http://www.apache.org/dyn/closer.cgi/maven/ \
        | sed -n 's#.*href="\(http://ftp.[^"]*\)".*#\1#p' \
        | head -n 1 \
    ) \ 
    && wget -q -O - ${mirror_url}/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
        | tar -xzf - -C /tmp \
    && mv /tmp/apache-maven-${MAVEN_VERSION} /usr/lib/maven \
    && ln -s /usr/lib/maven/bin/mvn /usr/bin/mvn \
    && apk --no-cache add \
        apr-util-dev \
        curl-dev \
        cyrus-sasl-crammd5 \
        fts-dev \
        libstdc++ \
        openjdk8-jre \
        patch \
        python-dev \
        subversion-dev \
        zlib-dev \
    ## builddeps
    && apk --no-cache add --virtual .builddeps \
        autoconf \
        automake \
        build-base \
        git \
        libtool \
        linux-headers \
        openjdk8 \
    && cd /tmp/ \
    && git clone https://github.com/apache/mesos.git 
    
RUN set -x \    
    ## build
    && cd /tmp/mesos \
    && ./bootstrap \
    && mkdir build \
    && cd build \
    && ../configure \
    && make \
    && make install \
    && apk del .builddeps \
    && rm -rf /tmp/mesos 
    
ENV PYTHONPATH=${PYTHONPATH}:/usr/local/lib/python2.7/site-packages