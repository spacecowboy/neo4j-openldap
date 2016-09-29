FROM java:openjdk-8-jre-alpine

RUN apk add --no-cache --quiet \
    bash \
    curl

COPY neo4j-enterprise-3.1.0-M10-unix.tar.gz /tmp/neo4j.tar.gz

RUN tar --extract --file /tmp/neo4j.tar.gz --directory /var/lib  \
    && mv /var/lib/neo4j-* /var/lib/neo4j

WORKDIR /var/lib/neo4j

RUN mv data /data \
    && ln -s /data

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 7474 7473 7687

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["neo4j"]
