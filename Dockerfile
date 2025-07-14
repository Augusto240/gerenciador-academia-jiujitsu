
FROM ruby:3.2.3
WORKDIR /usr/src/app

RUN apt-get update -qq && apt-get install -y libpq-dev build-essential

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x wait-for-it.sh docker-entrypoint.sh

EXPOSE 4567

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0"]