FROM bigboards/jupyterhub-__arch__

MAINTAINER bigboards <hello@bigboards.io>

RUN echo 'bb:Swh^bdl' | chpasswd

RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2-bin-hadoop2.6.tgz | tar -xz -C /opt
RUN cd /opt && ln -s ./spark-1.6.2-bin-hadoop2.6 spark

RUN mkdir /usr/local/share/jupyter/kernels/pyspark
ADD pyspark.kernel /usr/local/share/jupyter/kernels/pyspark/kernel.json

# Install Java.
RUN \
  echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-get update && \
  apt-get install -y software-properties-common && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java7-installer && \
  pip3 install jupyter-console
  
# Install libraries
RUN apt-get update \
    && apt-get install -y build-essential gfortran libatlas-base-dev python-pip python-dev pkg-config libpng-dev libjpeg8-dev libfreetype6-dev \
&& yes | pip install --upgrade pip numpy scipy pandas scikit-learn matplotlib

###############################################################################
## DOWNLOAD Hadoop, Sqoop, Pig
###############################################################################
RUN curl -s http://www.eu.apache.org/dist/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz | tar -xz -C /opt
RUN curl -s http://www.eu.apache.org/dist/pig/pig-0.15.0/pig-0.15.0.tar.gz | tar -xz -C /opt
RUN curl -s http://www.apache.org/dist/sqoop/1.4.6/sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz | tar -xz -C /opt

RUN cd /opt && \
    ln -s ./hadoop-2.6.0 hadoop && \
    ln -s ./pig-0.15.0 pig && \
    ln -s ./sqoop-1.4.6.bin__hadoop-2.0.4-alpha sqoop


###############################################################################
## PIG EXTENSION LIBS 
###############################################################################
RUN wget -O /opt/pig/lib/parquet-pig-bundle-1.8.1.jar http://search.maven.org/remotecontent?filepath=org/apache/parquet/parquet-pig-bundle/1.8.1/parquet-pig-bundle-1.8.1.jar 

###############################################################################
## SQOOP JDBC DRIVERS
###############################################################################
# Postgresql
RUN wget -P /opt/sqoop/lib/ https://jdbc.postgresql.org/download/postgresql-9.4-1201.jdbc4.jar

# mysql
RUN wget -P /tmp/ http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.37.tar.gz && \
    tar -C /tmp/ -xzf /tmp/mysql-connector-java-5.1.37.tar.gz && \
    cp /tmp/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar /opt/sqoop/lib/

RUN mkdir -p /tmp/jupyterhub/spark/local && chmod 777 /tmp/jupyterhub/spark/local

# Set the environment variables
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_PREFIX /opt/hadoop
ENV HADOOP_YARN_HOME /opt/hadoop
ENV HADOOP_HDFS_HOME /opt/hadoop
ENV HADOOP_COMMON_HOME /opt/hadoop
ENV HADOOP_MAPRED_HOME /opt/hadoop
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV HDFS_CONF_DIR /opt/hadoop/etc/hadoop
ENV YARN_CONF_DIR /opt/hadoop/etc/hadoop
ENV YARN_HOME /opt/hadoop
ENV SQOOP_HOME /opt/sqoop
ENV PIG_HOME /opt/pig
ENV PATH ${PATH}:${PIG_HOME}/bin:${SQOOP_HOME}/bin:${HADOOP_HOME}/bin

ADD hadoop-shell /bin/hadoop-shell
RUN chmod a+x /bin/hadoop-shell

WORKDIR /srv/jupyterhub/

EXPOSE 8000

CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
