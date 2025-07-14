# Dockerfile

FROM ruby:3.2.3
WORKDIR /usr/src/app

# ---- INÍCIO DA CORREÇÃO ----
# Instala as dependências do sistema necessárias para a gem 'pg' ANTES do bundle install
RUN apt-get update -qq && apt-get install -y libpq-dev build-essential
# ---- FIM DA CORREÇÃO ----

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Garante que os scripts são executáveis
RUN chmod +x wait-for-it.sh docker-entrypoint.sh

EXPOSE 4567

ENTRYPOINT ["./docker-entrypoint.sh"]

# Espera pela porta 5432 do PostgreSQL
CMD ["bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0"]