-- Garante que as tabelas sejam limpas e recriadas se já existirem
DROP TABLE IF EXISTS presencas, aulas, graduacoes, pagamentos, assinaturas, planos, alunos;

-- Tabela principal de Alunos
CREATE TABLE IF NOT EXISTS alunos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  data_nascimento DATE,
  cor_faixa VARCHAR(50),
  turma VARCHAR(50)
);

-- Tabela de Planos (agora com apenas um plano)
CREATE TABLE IF NOT EXISTS planos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL
);

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

-- --- DADOS DE EXEMPLO ---

-- 1. Cria o plano padrão único
INSERT INTO planos (id, nome, valor) VALUES (1, 'Plano Padrão', 70.00);

-- 2. Insere os alunos de exemplo
INSERT INTO alunos (id, nome, data_nascimento, cor_faixa, turma) VALUES
(1, 'José Augusto', '2005-08-09', 'Roxa', 'Adultos'),
(2, 'Maria Oliveira', '1998-08-22', 'Azul', 'Feminino');

-- 3. Cria as assinaturas para os alunos de exemplo
INSERT INTO assinaturas (aluno_id, plano_id, valor_mensalidade, status) VALUES
(1, 1, 70.00, 'ativa'),
(2, 1, 70.00, 'ativa');

-- 4. Insere pagamentos de exemplo
-- Pagamento de Augusto em dia
INSERT INTO pagamentos (assinatura_id, valor_pago, data_pagamento) VALUES (1, 70.00, CURDATE() - INTERVAL 15 DAY);
-- Pagamento de Maria atrasado
INSERT INTO pagamentos (assinatura_id, valor_pago, data_pagamento) VALUES (2, 70.00, CURDATE() - INTERVAL 40 DAY);

-- 5. Insere graduações de exemplo
INSERT INTO graduacoes (aluno_id, faixa, data_graduacao) VALUES (1, 'Azul', '2023-06-15'), (1, 'Roxa', '2024-07-01');