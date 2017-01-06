FROM ubuntu:14.04

RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 327574EE02A818DD
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list


RUN apt-get update && apt-get install -y \
  wget

RUN wget 'https://archive.cloudera.com/cdh5/ubuntu/trusty/amd64/cdh/cloudera.list' \
  -O /etc/apt/sources.list.d/cloudera.list

RUN wget https://archive.cloudera.com/cdh5/ubuntu/trusty/amd64/cdh/archive.key -O archive.key
RUN apt-key add archive.key

RUN apt-get update && apt-get install -y \
  hadoop-hdfs-datanode \
  hadoop-hdfs-namenode \
  hive-metastore \
  impala \
  impala-catalog \
  impala-server \
  impala-shell \
  impala-state-store \
  libpostgresql-jdbc-java \
  postgresql-9.3 \
  postgresql-client-9.3

RUN echo "listen_addresses = '*'" >> /etc/postgresql/9.3/main/postgresql.conf
RUN echo "standard_conforming_strings = off" >> /etc/postgresql/9.3/main/postgresql.conf

ADD postgresql-init.sql postgresql-init.sql 
USER postgres

RUN /etc/init.d/postgresql start && \
  psql -f postgresql-init.sql

ADD hive-site.xml /etc/hive/conf/hive-site.xml
ADD hive-site.xml /etc/impala/conf/hive-site.xml

ENV PGPASSWORD=mypassword
RUN /etc/init.d/postgresql start && \
  psql -h localhost -U hiveuser -d metastore -c 'select 1;'


USER root

RUN ln -s /usr/share/java/postgresql-jdbc4.jar /usr/lib/hive/lib/postgresql-jdbc4.jar

RUN mkdir -p /var/lib/hadoop-hdfs/cache/hdfs/dfs/name
RUN mkdir -p /var/lib/hadoop-hdfs/cache/hdfs/dfs/data
RUN chown -R hdfs:hdfs /var/lib/hadoop-hdfs/cache/hdfs/dfs/name
RUN chown -R hdfs:hdfs /var/lib/hadoop-hdfs/cache/hdfs/dfs/data

ADD hdfs-site.xml /etc/impala/conf/hdfs-site.xml
ADD core-site.xml /etc/impala/conf/core-site.xml

ADD hdfs-site.xml /etc/hadoop/conf/hdfs-site.xml
ADD core-site.xml /etc/hadoop/conf/core-site.xml

ADD hadoop-env.sh /etc/hadoop/conf/hadoop-env.sh

USER hdfs

RUN hdfs namenode -format

USER root

RUN mkdir -p /var/run/hdfs-sockets
RUN chown -R hdfs:hdfs /var/run/hdfs-sockets

RUN groupadd supergroup
RUN usermod -a -G supergroup root
RUN usermod -a -G supergroup impala

CMD service postgresql start &&  \
  service hive-metastore start && \
  service hadoop-hdfs-namenode start && \
  service hadoop-hdfs-datanode start && \
  service impala-state-store start && \
  service impala-catalog start && \
  service impala-server start && \
  sleep infinity
