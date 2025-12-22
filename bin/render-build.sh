#!/usr/bin/env bash
# exit on error
set -o errexit

echo "🚀 Iniciando build para Render..."

bundle install

# ==========================================
# MIGRAÇÃO SEGURA (NÃO APAGA DADOS!)
# ==========================================
# IMPORTANTE: Não executamos mais o schema.sql em cada build
# porque ele contém DROP TABLE que apagaria todos os dados.
# Em vez disso, usamos um script de migração que apenas
# adiciona colunas/tabelas novas sem apagar dados existentes.
# ==========================================

echo "📦 Executando migrações seguras do banco de dados..."
bundle exec ruby bin/migrate.rb

# Criar usuário administrador (se não existir)
echo "👤 Verificando usuário administrador..."
bundle exec ruby bin/create_admin.rb

echo "✅ Build finalizado com sucesso!"