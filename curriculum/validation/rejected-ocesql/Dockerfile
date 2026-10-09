FROM debian:13-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f
ARG OCESQL_COMMIT=e116b6ad12d73f8849667fd1f98da62eda2153db
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnucobol3 gcc make autoconf automake libtool bison flex \
    libpq-dev pkg-config git ca-certificates postgresql-client && \
    rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/opensourcecobol/Open-COBOL-ESQL.git /tmp/ocesql && \
    cd /tmp/ocesql && git checkout "$OCESQL_COMMIT" && \
    autoreconf -fi && CPPFLAGS=-I/usr/include/postgresql ./configure && \
    make -j2 && make install && ldconfig && rm -rf /tmp/ocesql
WORKDIR /work
