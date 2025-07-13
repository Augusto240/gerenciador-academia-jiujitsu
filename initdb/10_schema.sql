-- Estrutura do Banco de Dados
-- Este arquivo define a arquitetura das tabelas.

-- Garante uma recriação limpa sempre que o ambiente sobe do zero
DROP TABLE IF EXISTS presencas, aulas, graduacoes, pagamentos, assinaturas, planos, alunos;

-- Tabela principal de Alunos
CREATE TABLE IF NOT EXISTS alunos (
  id INT AUTO_INCREMENT PRIMARY KEY,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL
);

-- Tabela de Assinaturas
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

-- Tabela de Aulas (com a coluna 'turma')
CREATE TABLE IF NOT EXISTS aulas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data_aula DATE NOT NULL,
    turma VARCHAR(50),
    descricao VARCHAR(255)
);

-- Tabela de Presenças
CREATE TABLE IF NOT EXISTS presencas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    aluno_id INT NOT NULL,
    aula_id INT NOT NULL,
    presente BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (aluno_id) REFERENCES alunos(id) ON DELETE CASCADE,
    FOREIGN KEY (aula_id) REFERENCES aulas(id) ON DELETE CASCADE,
    UNIQUE(aluno_id, aula_id)
);

-- --- DADOS DE EXEMPLO ---
INSERT INTO planos (id, nome, valor) VALUES (1, 'Plano Padrão', 70.00);

INSERT INTO alunos (id, nome, data_nascimento, cor_faixa, turma, bolsista) VALUES
(1, 'José Augusto', '2005-08-09', 'Roxa', 'Adultos', FALSE),
(2, 'Maria Oliveira', '1998-08-22', 'Azul', 'Feminino', TRUE);

INSERT INTO assinaturas (aluno_id, plano_id, valor_mensalidade, status) VALUES
(1, 1, 70.00, 'ativa'),
(2, 1, 0.00, 'ativa'); -- Assinatura de bolsista com valor zero

INSERT INTO pagamentos (assinatura_id, valor_pago, data_pagamento) VALUES (1, 70.00, CURDATE() - INTERVAL 15 DAY);

INSERT INTO graduacoes (aluno_id, faixa, data_graduacao) VALUES
(1, 'Azul', '2023-06-15'),
(1, 'Roxa', '2024-07-01');

INSERT INTO aulas (id, data_aula, descricao) VALUES
(1, CURDATE() - INTERVAL 2 DAY, 'Treino de passagem de guarda'),
(2, CURDATE() - INTERVAL 1 DAY, 'Treino de finalizações');
