FROM rabbitmq:alpine
MAINTAINER Adam Drozdz <adrozdz@container-labs.com>

ENV RABBITMQ_ERLANG_COOKIE=default \
  RABBITMQ_DEFAULT_USER=guest \
  RABBITMQ_DEFAULT_PASS=guest \
  RABBITMQ_DEFAULT_VHOST=/ \
  RABBITMQ_NODE_PORT=5672 \
  RABBITMQ_DIST_PORT=25672 \
  RABBITMQ_NET_TICKTIME=60 \
  RABBITMQ_CLUSTER_PARTITION_HANDLING=ignore \
  ERL_EPMD_PORT=4369 \
  RABBITMQ_MANAGEMENT_PORT=15672 \
  MARATHON_URI=http://leader.mesos:8080 \
  AUTOCLUSTER_VERSION=0.6.1 \
  RABBITMQ_SERVER_ERL_ARGS="+K true +A128 +P 1048576 -kernel inet_default_connect_options [{nodelay,true}]" 

ENV PACKAGES="\
  musl \
  linux-headers \
  build-base \
  git \
  python2 \
  python2-dev \
  py-setuptools \
  tar \
  bash \
  coreutils \
  curl \
  xz \
"
RUN echo \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \

  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \

  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main/" > /etc/apk/repositories \
  && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
  && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
  && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \

  && easy_install pip \
  && pip install --upgrade pip \
  && easy_install requests \
  && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi \
  && echo
  RUN \
  curl -sL -o /tmp/autocluster-${AUTOCLUSTER_VERSION}.tgz https://github.com/aweber/rabbitmq-autocluster/releases/download/${AUTOCLUSTER_VERSION}/autocluster-${AUTOCLUSTER_VERSION}.tgz && \
  tar -xvz -C /opt/rabbitmq/ -f /tmp/autocluster-${AUTOCLUSTER_VERSION}.tgz && \
  rm /tmp/autocluster-${AUTOCLUSTER_VERSION}.tgz
  
RUN chown -R rabbitmq /opt/rabbitmq/plugins
RUN chmod -R 777 /opt/rabbitmq/plugins
RUN chown -R rabbitmq /var/lib/rabbitmq
ADD ./rabbitmq-cluster.py /rabbitmq-cluster.py
RUN chmod +x /rabbitmq-cluster.py
#enable management plugin for gui 
RUN rabbitmq-plugins enable --offline \
        autocluster \
        rabbitmq_consistent_hash_exchange \
        rabbitmq_federation \
        rabbitmq_federation_management \
        rabbitmq_mqtt \
        rabbitmq_recent_history_exchange \
        rabbitmq_sharding \
        rabbitmq_shovel \
        rabbitmq_shovel_management \
        rabbitmq_stomp \
        rabbitmq_top \
        rabbitmq_web_stomp && \
  rabbitmq-plugins list

EXPOSE 15671 15672 4369 5671 5672 25672

ENTRYPOINT ["/rabbitmq-cluster.py"]