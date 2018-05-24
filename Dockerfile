# secureBoxArachni
# Based on Sinatra-Ruby
FROM ruby:2.4.0
MAINTAINER Jasper.Boyn@iteratec.de, Robert.Seedorff@iteratec.de

RUN apt-get update && apt-get install -y --no-install-recommends wget vim ca-certificates
RUN gem install sinatra rest-client ruby-debug-ide activesupport aws-sdk -N

#Install pry for debugging
RUN gem install pry -N
RUN mkdir /sectools && wget https://github.com/Arachni/arachni/releases/download/v1.5/arachni-1.5-0.5.11-linux-x86_64.tar.gz -P /sectools && tar zxvf /sectools/* -C /sectools && rm /sectools/arachni-1.5-0.5.11-linux-x86_64.tar.gz

COPY securebox/ /sectools/

EXPOSE 8080

# Uncomment for REST-API usage
ENTRYPOINT ["bash","./sectools/arachni.sh"]
#CMD []

#ENTRYPOINT ["rdebug-ide", "--host", "0.0.0.0", "--port", "1234", "--dispatcher-port", "26162", "./sectools/arachni-client.rb"]
# Uncomment for debugging
#ENTRYPOINT ["ruby", "-d", "./sectools/arachni-client.rb"]

# Uncomment for bash
#ENTRYPOINT ["bash"]
