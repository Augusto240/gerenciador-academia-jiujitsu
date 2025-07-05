FROM ruby:3.2.3
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY wait-for-it.sh docker-entrypoint.sh ./
RUN chmod +x wait-for-it.sh docker-entrypoint.sh

COPY . .

EXPOSE 4567

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["./wait-for-it.sh", "db:3306", "--timeout=60", "--strict", "--", "bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0"]
