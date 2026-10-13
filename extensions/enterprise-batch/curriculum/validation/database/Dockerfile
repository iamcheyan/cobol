FROM debian:13-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f
ARG GIXSQL_COMMIT=69e26719ecaca2c31bdf91d7add270b1c0ce2286
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnucobol3 g++ make autoconf automake libtool bison flex \
    libpq-dev libfmt-dev libspdlog-dev pkg-config git ca-certificates \
    postgresql-client && rm -rf /var/lib/apt/lists/*
COPY gixsql-*.patch /tmp/
RUN git clone https://github.com/mridoni/gixsql.git /tmp/gixsql && \
    cd /tmp/gixsql && git checkout "$GIXSQL_COMMIT" && \
    git apply /tmp/gixsql-cursor-null.patch /tmp/gixsql-closed-cursor.patch && bash prepdist.sh && bash prepbuild.sh && autoreconf -fi && CXXFLAGS="-O2 -include cstdint" ./configure --disable-mysql --disable-odbc \
      --disable-sqlite --disable-oracle --with-default-driver=pgsql && \
    make -j2 && make install && ldconfig && rm -rf /tmp/gixsql
WORKDIR /work
