FROM alpine:3.7
# Build arguments
ARG VCS_REF
ARG VERSION
# Set label metadata
LABEL org.label-schema.name="rclone-cron-daemon" \
      org.label-schema.description="Alpine Linux Docker Container running RClone utility with configurable cron schedule" \
      org.label-schema.usage="https://github.com/madcatsu/docker-rclone-cron-daemon/blob/master/README.md" \
      org.label-schema.url="https://github.com/madcatsu/docker-rclone-cron-daemon" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-url="https://github.com/madcatsu/docker-rclone-cron-daemon" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0"
# global environment settings
ENV GOPATH="/go" \
  PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"
# install base packages
RUN apk update && \
  apk add --no-cache --update --virtual build-deps \
    gcc \
    git \
    go \
    libc-dev \
    python3-dev && \
  apk add --no-cache --update \
    bash \
    ca-certificates \
    curl \
    python3 && \
# Install Chaperone as supervisor
  pip3 install --upgrade --no-cache pip && \
  pip3 install --no-cache chaperone && \
# Create container user and directory structure
  mkdir -p \
    /config \
    /defaults \
    /data && \
# Fetch required sources & build
  git clone https://github.com/ncw/rclone.git $GOPATH/src/github.com/ncw/rclone && \
  cd $GOPATH/src/github.com/ncw/rclone && \
  go get && \
  go build -o /usr/local/bin/rclone && \
  chmod +x /usr/local/bin/rclone && \
# Prep rclone job lockfile
  touch /var/lock/rclone.lock && \
# cleanup
  apk del build-deps && \
  rm -rf \
	  /tmp/* \
	  /var/tmp/* \
	  /var/cache/apk/* && \
# cleanup sources
  rm -rf $GOPATH /usr/local/go
# add local files
COPY root/ /
VOLUME ["/config","/data"]
ENTRYPOINT ["/usr/bin/chaperone","--default-home","/config"]
