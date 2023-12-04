ARG SPARK_VERSION="3.4.1"
ARG HADOOP_VERSION="3.3.4"
ARG SCALA_VERSION="2.12"
ARG JAVA_VERSION="8"

# Python version doesn't matter much for Zeppelin, so we just default to the latest 3.9
FROM dsaidgovsg/spark-k8s-addons:v5_${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}_python-3.9
USER root

ENV ZEPPELIN_HOME "/zeppelin"

WORKDIR /zeppelin
ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

# Install required apt packages
RUN set -euo pipefail && \
    apt-get update && apt-get install -y --no-install-recommends \
        fuse \
        gosu \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/*; \
    :

# Install Zeppelin binary
ARG ZEPPELIN_VERSION="0.11.0-SNAPSHOT"
RUN set -euo pipefail && \
    wget https://github.com/guangie88/zeppelin/releases/download/reload4j-variant-release/zeppelin-0.11.0-SNAPSHOT.tar.gz; \
    tar xvf zeppelin-${ZEPPELIN_VERSION}.tar.gz --strip-components=1; \
    rm zeppelin-${ZEPPELIN_VERSION}.tar.gz; \
    :

# Install GitHub Release Assets FUSE mount CLI (requires fuse install)
ARG GHAFS_VERSION="v0.1.3"
RUN set -euo pipefail && \
    wget https://github.com/guangie88/ghafs/releases/download/${GHAFS_VERSION}/ghafs-${GHAFS_VERSION}-linux-amd64.tar.gz; \
    tar xvf ghafs-${GHAFS_VERSION}-linux-amd64.tar.gz; \
    rm ghafs-${GHAFS_VERSION}-linux-amd64.tar.gz; \
    mv ./ghafs /usr/local/bin/; \
    ghafs --version; \
    :

RUN set -euo pipefail && \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.4.1/tera-cli-v0.4.1-x86_64-unknown-linux-musl.tar.gz; \
    tar xvf tera-cli-v0.4.1-x86_64-unknown-linux-musl.tar.gz; \
    mv tera-cli-v0.4.1-x86_64-unknown-linux-musl/tera /usr/local/bin/tera; \
    rm -rf tera-cli-v0.4.1-x86_64-unknown-linux-musl*; \
    :

COPY docker ${ZEPPELIN_HOME}

RUN set -euo pipefail && \
    adduser --disabled-password --gecos "" zeppelin; \
    chown -R zeppelin:zeppelin "${ZEPPELIN_HOME}"; \
    :

USER zeppelin

# Entrypoint-ish env vars to apply config templates
ENV ZEPPELIN_APPLY_INTERPRETER_JSON "true"
ENV ZEPPELIN_APPLY_ZEPPELIN_SITE "true"
ENV ZEPPELIN_APPLY_SHIRO "false"

# Env var not expanded without Dockerfile, so need to go through sh
CMD ["bash", "-c", "${ZEPPELIN_HOME}/run-zeppelin.sh"]
