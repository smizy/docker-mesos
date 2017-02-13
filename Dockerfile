FROM alpine:3.4
MAINTAINER smizy

ENV MESOS_VERSION   1.1.0
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
	wget -q -O - "http://www.apache.org/dyn/closer.cgi/?as_json=1" \
	| grep "preferred" \
	| sed -n 's#.*"\(http://*[^"]*\)".*#\1#p' \
    ) \ 
    && wget -q -O - ${mirror_url}maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
        | tar -xzf - -C /tmp \
    && mv /tmp/apache-maven-${MAVEN_VERSION} /usr/lib/maven \
    && ln -s /usr/lib/maven/bin/mvn /usr/bin/mvn \
    ## 
    && apk --no-cache add \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        glog \
    && apk --no-cache add --virtual .builddeps.edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        glog-dev \
    && apk --no-cache add \
        apr-util \
        boost \
        curl \
        cyrus-sasl-crammd5 \
        fts \
        libstdc++ \
        openjdk8-jre \
        patch \
        protobuf \
        python \
        subversion \
        zlib \
    ## builddeps
    && apk --no-cache add --virtual .builddeps \
        apr-util-dev \       
        autoconf \
        automake \
        boost-dev \        
        build-base \
        curl-dev \
        fts-dev \
        git \
        libtool \
        linux-headers \
        openjdk8 \
        protobuf-dev \
        python-dev \
        subversion-dev \
        zlib-dev \
    # && cd /tmp/ \
    # && git clone https://github.com/apache/mesos.git  \  
    # && cd /tmp/mesos \
    # && ./bootstrap \
    && wget -q -O - ${mirror_url}mesos/${MESOS_VERSION}/mesos-${MESOS_VERSION}.tar.gz \
        | tar -xzf - -C /tmp  \
    && mv /tmp/mesos-${MESOS_VERSION} /tmp/mesos \
    && cd /tmp/mesos \    
    && mkdir build \
    && cd build \
    && ../configure \
        --disable-java \
        --disable-optimize \
        --disable-python \
        --with-boost=/usr \ 
        --with-glog=/usr \
        --with-protobuf=/usr \
    #    --without-included-zookeeper \
    && CPUCOUNT=$(cat /proc/cpuinfo | grep '^processor.*:' | wc -l)  \
    && make -j ${CPUCOUNT} \
    && make install \
    && apk del  \
        .builddeps \  
        .builddeps.edge \
    ## user/dir/permmsion
    && adduser -D  -g '' -s /sbin/nologin -u 1000 docker \
    && adduser -D  -g '' -s /sbin/nologin mesos \
    # && mkdir -p \
    #     ${MESOS_LOG_DIR} 
    # && chown -R mesos:mesos \
    #     ${MESOS_LOG_DIR} \
    && rm -rf /tmp/mesos 

COPY entrypoint.sh  /usr/local/bin/
    
ENTRYPOINT ["entrypoint.sh"]