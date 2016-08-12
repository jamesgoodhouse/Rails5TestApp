FROM jamgood96/ruby:2.3.1

WORKDIR /app

ADD gems /app/bundle
ADD project-code /app

# ADD Gemfile /app/Gemfile
# ADD Gemfile.lock /app/Gemfile.lock
# RUN bundle install

# ADD . /app
