FROM alpine:3.8

# Add necessary packages
RUN apk --update add bash tzdata ruby ruby-dev build-base nodejs zlib-dev libxml2-dev libxslt-dev libffi-dev ca-certificates mysql-dev

# Create the run user and group
RUN addgroup --gid 18570 sse && adduser --uid 1984 docker -G sse -D

# set the timezone appropriatly
ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Add necessary gems
RUN gem install bundler io-console --no-ri --no-rdoc

# Copy the Gemfile into the image and temporarily set the working directory to where they are.
WORKDIR /tmp
ADD Gemfile Gemfile
RUN bundle install

# Specify home 
ENV APP_HOME /booktraces
WORKDIR $APP_HOME

# install the app and bundle
COPY . $APP_HOME
RUN rm $APP_HOME/Gemfile.lock && rake assets:precompile

# Update permissions
RUN chown -R docker $APP_HOME && chgrp -R sse $APP_HOME

# Specify the user
USER docker

# define port and startup script
EXPOSE 3000
CMD scripts/entry.sh

# move in the profile
COPY data/container_bash_profile /home/docker/.profile
