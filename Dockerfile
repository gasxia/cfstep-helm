ARG HELM_VERSION
ARG S3_PLUGIN_VERSION
ARG GCS_PLUGIN_VERSION
ARG PUSH_PLUGIN_VERSION

FROM golang:latest as setup
ARG HELM_VERSION
ARG S3_PLUGIN_VERSION
ARG GCS_PLUGIN_VERSION
ARG PUSH_PLUGIN_VERSION
RUN echo "HELM_VERSION is set to: ${HELM_VERSION}" && mkdir /temp
RUN curl -L "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz \
    && tar -zxvf helm.tar.gz \
    && mv ./linux-amd64/helm /usr/local/bin/helm \
    && helm plugin install https://github.com/hypnoglow/helm-s3.git --version=${S3_PLUGIN_VERSION} \
    && helm plugin install https://github.com/nouney/helm-gcs.git --version=${GCS_PLUGIN_VERSION} \
    && helm plugin install https://github.com/chartmuseum/helm-push.git --version=${PUSH_PLUGIN_VERSION}

# Run acceptance tests
COPY Makefile Makefile
COPY bin/ bin/
COPY lib/ lib/
RUN apt-get update \
    && apt-get install -y python3-venv

FROM codefresh/kube-helm:${HELM_VERSION}
ARG HELM_VERSION
COPY --from=setup /temp /root/.helm/* /root/.helm/
COPY --from=setup /temp /root/.cache/helm/* /root/.cache/helm/
COPY bin/* /opt/bin/
RUN chmod +x /opt/bin/*
COPY lib/* /opt/lib/

# Install Python3
#RUN apk add --no-cache python3 \
 #   && rm -rf /root/.cache

ENV HELM_VERSION ${HELM_VERSION}

ENTRYPOINT ["/opt/bin/release_chart"]