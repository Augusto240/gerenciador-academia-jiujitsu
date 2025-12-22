-- Garante uma recriação limpa
DROP TABLE IF EXISTS presencas, aulas, graduacoes, pagamentos, assinaturas, planos, usuarios, alunos CASCADE;

-- Tabela de Usuários do Sistema
CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  nome VARCHAR(100)
);

-- Tabela principal de Alunos
CREATE TABLE alunos (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  data_nascimento DATE,
  modalidade VARCHAR(50) DEFAULT 'Jiu Jitsu',
  cor_faixa VARCHAR(50),
  turma VARCHAR(50),
  bolsista BOOLEAN DEFAULT FALSE,
  saude_problema TEXT,
  saude_medicacao TEXT,
  saude_lesao TEXT,
  saude_substancia TEXT
);

-- Tabela de Planos
CREATE TABLE planos (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  valor DECIMAL(10, 2) NOT NULL
);

-- Tabela de Assinaturas
CREATE TABLE assinaturas (
  id SERIAL PRIMARY KEY,
  aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  plano_id INT NOT NULL REFERENCES planos(id),
  valor_mensalidade DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'ativa'
);

-- Tabela de Pagamentos
CREATE TABLE pagamentos (
  id SERIAL PRIMARY KEY,
  assinatura_id INT NOT NULL REFERENCES assinaturas(id) ON DELETE CASCADE,
  valor_pago DECIMAL(10, 2) NOT NULL,
  data_pagamento DATE NOT NULL
);

-- Tabela de Histórico de Graduações
CREATE TABLE graduacoes (
  id SERIAL PRIMARY KEY,
  aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  faixa VARCHAR(50) NOT NULL,
  data_graduacao DATE NOT NULL
);

-- Tabela de Aulas
CREATE TABLE aulas (
  id SERIAL PRIMARY KEY,
  data_aula DATE NOT NULL,
  modalidade VARCHAR(50) DEFAULT 'Jiu Jitsu',
  turma VARCHAR(50),
  descricao VARCHAR(255)
);

-- Tabela de Presenças
CREATE TABLE presencas (
  id SERIAL PRIMARY KEY,
  aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  aula_id INT NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
  presente BOOLEAN DEFAULT FALSE,
  UNIQUE(aluno_id, aula_id)
);

-- Tabela de Notificações
CREATE TABLE notificacoes (
  id SERIAL PRIMARY KEY,
  titulo VARCHAR(255) NOT NULL,
  mensagem TEXT,
  tipo VARCHAR(50) DEFAULT 'info',
  lida BOOLEAN DEFAULT FALSE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  lida_em TIMESTAMP
);