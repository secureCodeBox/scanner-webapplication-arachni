FROM ruby:latest

WORKDIR /sectools/

ENV ARACHNI_SHORT_VERSION v1.5.1
ENV ARACHNI_LONG_VERSION 1.5.1-0.5.12

RUN wget https://github.com/Arachni/arachni/releases/download/${ARACHNI_SHORT_VERSION}/arachni-${ARACHNI_LONG_VERSION}-linux-x86_64.tar.gz -P /sectools && \
    tar zxvf /sectools/* -C /sectools && \
    rm /sectools/arachni-1.5.1-0.5.12-linux-x86_64.tar.gz

COPY Gemfile src/

RUN bundle install --gemfile=/sectools/src/Gemfile

COPY src/ src/
COPY lib/ lib/

RUN addgroup -system arachni_group && \
    adduser -system arachni_user && \
    usermod -g arachni_group arachni_user

# USER arachni_user

EXPOSE 8080

ARG COMMIT_ID=unkown
ARG REPOSITORY_URL=unkown
ARG BRANCH=unkown

ENV SCB_COMMIT_ID ${COMMIT_ID}
ENV SCB_REPOSITORY_URL ${REPOSITORY_URL}
ENV SCB_BRANCH ${BRANCH}

ENTRYPOINT ["bash","/sectools/src/starter.sh"]
