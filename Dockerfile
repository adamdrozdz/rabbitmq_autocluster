FROM rabbitmq:alpine

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
  MARATHON_URI=http://leader.mesos:8080

ENV PACKAGES="\
  musl \
  linux-headers \
  build-base \
  git \
  python2 \
  python2-dev \
  py-setuptools \
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


RUN chown -R rabbitmq:rabbitmq /var/lib/rabbitmq
ADD ./rabbitmq-cluster.py /rabbitmq-cluster.py
RUN chmod +x /rabbitmq-cluster.py
#enable management plugin for gui 
RUN rabbitmq-plugins enable --offline rabbitmq_management

EXPOSE 15671 15672 4369 5671 5672 25672

ENTRYPOINT ["/rabbitmq-cluster.py"]