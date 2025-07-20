-- Garante uma recriação limpa (opcional, mas bom para testes)
DROP TABLE IF EXISTS presencas, aulas, graduacoes, pagamentos, assinaturas, planos, usuarios, alunos CASCADE;

-- Tabela de Usuários do Sistema
CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  nome VARCHAR(100)
);

-- Tabela principal de Alunos
CREATE TABLE IF NOT EXISTS alunos (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  data_nascimento DATE,
  cor_faixa VARCHAR(50),
  turma VARCHAR(50),
  bolsista BOOLEAN DEFAULT FALSE,
  saude_problema TEXT,
  saude_medicacao TEXT,
  saude_lesao TEXT,
  saude_substancia TEXT
);

-- Tabela de Planos
CREATE TABLE IF NOT EXISTS planos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL
);

-- Tabela de Assinaturas
CREATE TABLE IF NOT EXISTS assinaturas (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
    plano_id INT NOT NULL REFERENCES planos(id),
    valor_mensalidade DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'ativa'
);

-- Tabela de Pagamentos
CREATE TABLE IF NOT EXISTS pagamentos (
    id SERIAL PRIMARY KEY,
    assinatura_id INT NOT NULL REFERENCES assinaturas(id) ON DELETE CASCADE,
    valor_pago DECIMAL(10, 2) NOT NULL,
    data_pagamento DATE NOT NULL
);

-- Tabela de Histórico de Graduações
CREATE TABLE IF NOT EXISTS graduacoes (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
    faixa VARCHAR(50) NOT NULL,
    data_graduacao DATE NOT NULL
);

-- Tabela de Aulas
CREATE TABLE IF NOT EXISTS aulas (
    id SERIAL PRIMARY KEY,
    data_aula DATE NOT NULL,
    turma VARCHAR(50),
    descricao VARCHAR(255)
);

-- Tabela de Presenças
CREATE TABLE IF NOT EXISTS presencas (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
    aula_id INT NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
    presente BOOLEAN DEFAULT FALSE,
    UNIQUE(aluno_id, aula_id)
);