FROM alpine:3.10 as alpine

ARG GCC_VERSION
ENV GCC_VERSION=${GCC_VERSION}

RUN set -x \   
    && echo 'http://mirrors.ustc.edu.cn/alpine/v3.10/main' > /etc/apk/repositories \
    && echo 'http://mirrors.ustc.edu.cn/alpine/v3.10/community' >>/etc/apk/repositories \
    && apk update \
    && apk add -U tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

FROM alpine as builder

RUN apk add --quiet --no-cache \
            build-base \
            dejagnu \
            isl-dev \
            make \
            mpc1-dev \
            mpfr-dev \
            texinfo \
            zlib-dev

COPY ./gcc-7.5.0.tar.gz /gcc-7.5.0.tar.gz
# RUN wget -q https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz && \
RUN tar -xzf gcc-${GCC_VERSION}.tar.gz && \
    rm -f gcc-${GCC_VERSION}.tar.gz

WORKDIR /gcc-${GCC_VERSION}

RUN ./configure \
        --prefix=/usr/local \
        --build=$(uname -m)-alpine-linux-musl \
        --host=$(uname -m)-alpine-linux-musl \
        --target=$(uname -m)-alpine-linux-musl \
        --with-pkgversion="Alpine ${GCC_VERSION}" \
        --enable-checking=release \
        --disable-fixed-point \
        --disable-libmpx \
        --disable-libmudflap \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libstdcxx-pch \
        --disable-multilib \
        --disable-nls \
        --disable-symvers \
        --disable-werror \
        --enable-__cxa_atexit \
        --enable-default-pie \
        --enable-languages=c,c++ \
        --enable-shared \
        --enable-threads \
        --enable-tls \
        --with-linker-hash-style=gnu \
        --with-system-zlib
RUN make --silent -j $(nproc)
RUN make --silent -j $(nproc) install-strip

RUN gcc -v


FROM alpine

RUN apk add --quiet --no-cache \
            autoconf \
            automake \
            binutils \
            cmake \
            file \
            git \
            gmp \
            isl \
            libc-dev \
            libtool \
            make \
            mpc1 \
            mpfr3 \
            musl-dev \
            pkgconf \
            zlib-dev

COPY --from=builder /usr/local/ /usr/

RUN ln -s /usr/bin/gcc /usr/bin/cc

WORKDIR /src
