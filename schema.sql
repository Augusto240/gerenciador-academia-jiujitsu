-- Estrutura do Banco de Dados
-- Este arquivo define a arquitetura das tabelas.

-- Tabela principal de Alunos
CREATE TABLE IF NOT EXISTS alunos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  data_nascimento DATE,
  cor_faixa VARCHAR(50),
  turma VARCHAR(50)
);

-- Tabela de Planos (com o plano padrão)
CREATE TABLE IF NOT EXISTS planos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL
);
INSERT INTO planos (id, nome, valor) VALUES (1, 'Plano Padrão', 70.00);

-- Tabela de Assinaturas (vínculo entre aluno e plano)
CREATE TABLE IF NOT EXISTS assinaturas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    aluno_id INT NOT NULL,
    plano_id INT NOT NULL,
    valor_mensalidade DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'ativa',
    FOREIGN KEY (aluno_id) REFERENCES alunos(id) ON DELETE CASCADE,
    FOREIGN KEY (plano_id) REFERENCES planos(id)
);

-- Tabela de Pagamentos
CREATE TABLE IF NOT EXISTS pagamentos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    assinatura_id INT NOT NULL,
    valor_pago DECIMAL(10, 2) NOT NULL,
    data_pagamento DATE NOT NULL,
    FOREIGN KEY (assinatura_id) REFERENCES assinaturas(id) ON DELETE CASCADE
);

-- Tabela de Histórico de Graduações
CREATE TABLE IF NOT EXISTS graduacoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    aluno_id INT NOT NULL,
    faixa VARCHAR(50) NOT NULL,
    data_graduacao DATE NOT NULL,
    FOREIGN KEY (aluno_id) REFERENCES alunos(id) ON DELETE CASCADE
);