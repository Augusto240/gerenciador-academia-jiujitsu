#!/usr/bin/env ruby
# Script para rodar todos os testes
# Uso: ruby test/run_tests.rb

require 'minitest/autorun'

# Carregar todos os arquivos de teste
Dir.glob(File.join(__dir__, '*_test.rb')).each do |test_file|
  require test_file
end
