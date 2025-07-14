# generate_hash.rb
require 'bcrypt'

puts "--- Gerador de Hash BCrypt ---"
print "Digite a senha que você quer criptografar (ex: admin123): "
password = gets.chomp

# Gera o hash da senha
hashed_password = BCrypt::Password.create(password)

puts "\n✅ Hash gerado com sucesso!"
puts "------------------------------------------------------------"
puts hashed_password
puts "------------------------------------------------------------"
puts "\nCopie a linha de hash acima e cole no seu arquivo init.sql."