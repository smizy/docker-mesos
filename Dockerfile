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
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        glog-dev \
    && apk --no-cache add \
        apr-util-dev \
        boost-dev \
        curl-dev \
        cyrus-sasl-crammd5 \
        fts-dev \
        libstdc++ \
        openjdk8-jre \
        patch \
        protobuf-dev \
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
    && git clone https://github.com/apache/mesos.git  \  
    && cd /tmp/mesos \
    && ./bootstrap \
    && mkdir build \
    && cd build \
    && ../configure \
        --disable-java \
        --disable-optimize \
        --disable-python \
        --with-boost=/usr \ 
        --with-glog=/usr \
        --with-protobuf=/usr \
        --without-included-zookeeper \
    && make \
    && make install \
    && apk del .builddeps \  
    ## user/dir/permmsion
    && adduser -D  -g '' -s /sbin/nologin -u 1000 docker \
    && adduser -D  -g '' -s /sbin/nologin mesos \
    # && mkdir -p \
    #     ${MESOS_LOG_DIR} 
    # && chown -R mesos:mesos \
    #     ${MESOS_LOG_DIR} \
    && rm -rf /tmp/mesos 

COPY entrypoint.sh  /usr/local/bin/
    
# ENV PYTHONPATH=${PYTHONPATH}:/usr/local/lib/python2.7/site-packages

ENTRYPOINT ["entrypoint.sh"]