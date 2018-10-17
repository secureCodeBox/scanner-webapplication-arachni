FROM ruby:latest

WORKDIR /sectools/

ARG ARACHNI_DISTRIBUTION=https://github.com/Arachni/arachni/releases/download/v1.5.1/arachni-1.5.1-0.5.12-linux-x86_64.tar.gz
# Name of the arachni main folder contained in the .tar.gz
ARG ARACHNI_LONG_VERSION=arachni-1.5.1-0.5.12

ENV ARACHNI_LONG_VERSION ${ARACHNI_LONG_VERSION}

RUN wget ${ARACHNI_DISTRIBUTION} -P /sectools --output-document arachni.tar.gz && \
    tar zxvf arachni.tar.gz && \
    mv arachni-${ARACHNI_FOLDER_NAME} arachni && \
    rm arachni.tar.gz

COPY Gemfile src/

RUN bundle install --gemfile=/sectools/src/Gemfile

COPY src/ src/
COPY lib/ lib/

RUN addgroup -system arachni && \
    adduser -system arachni && \
    usermod -g arachni arachni

RUN chgrp -R 0 /sectools/ && \
    chmod -R g=u /sectools/ && \
    chown -R arachni /sectools/

USER arachni

VOLUME /securecodebox/scripts/

EXPOSE 8080

ARG COMMIT_ID=unkown
ARG REPOSITORY_URL=unkown
ARG BRANCH=unkown
ARG BUILD_DATE
ARG VERSION

ENV SCB_COMMIT_ID ${COMMIT_ID}
ENV SCB_REPOSITORY_URL ${REPOSITORY_URL}
ENV SCB_BRANCH ${BRANCH}

LABEL org.opencontainers.image.title="secureCodeBox scanner-webapplication-arachni" \
    org.opencontainers.image.description="Arachni integration for secureCodeBox" \
    org.opencontainers.image.authors="iteratec GmbH" \
    org.opencontainers.image.vendor="iteratec GmbH" \
    org.opencontainers.image.documentation="https://github.com/secureCodeBox/secureCodeBox" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.url=$REPOSITORY_URL \
    org.opencontainers.image.source=$REPOSITORY_URL \
    org.opencontainers.image.revision=$COMMIT_ID \
    org.opencontainers.image.created=$BUILD_DATE

ENTRYPOINT ["bash","/sectools/src/starter.sh"]
