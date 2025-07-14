DROP TABLE IF EXISTS presencas, aulas, graduacoes, pagamentos, assinaturas, planos, usuarios, alunos CASCADE;

CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  nome VARCHAR(100)
);

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

CREATE TABLE IF NOT EXISTS planos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS assinaturas (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
    plano_id INT NOT NULL REFERENCES planos(id),
    valor_mensalidade DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'ativa'
);

CREATE TABLE IF NOT EXISTS pagamentos (
    id SERIAL PRIMARY KEY,
    assinatura_id INT NOT NULL REFERENCES assinaturas(id) ON DELETE CASCADE,
    valor_pago DECIMAL(10, 2) NOT NULL,
    data_pagamento DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS graduacoes (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
    faixa VARCHAR(50) NOT NULL,
    data_graduacao DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS aulas (
    id SERIAL PRIMARY KEY,
    data_aula DATE NOT NULL,
    turma VARCHAR(50),
    descricao VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS presencas (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
    aula_id INT NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
    presente BOOLEAN DEFAULT FALSE,
    UNIQUE(aluno_id, aula_id)
);

INSERT INTO usuarios (email, nome, password_digest) VALUES
('admin@jpteam.com', 'Admin JPM', '$2a$12$GjwrLz6wYSLcttaAXeSdkugn3TR9WzOLfX3P6rrh0H1NwSdKVDZ9K')
ON CONFLICT (email) DO NOTHING;

INSERT INTO planos (id, nome, valor) VALUES (1, 'Plano Padrão', 70.00) ON CONFLICT (id) DO NOTHING;

INSERT INTO alunos (id, nome, data_nascimento, cor_faixa, turma, bolsista) VALUES
(1, 'José Augusto', '2005-08-09', 'Roxa', 'Adultos', FALSE),
(2, 'Maria Oliveira', '1998-08-22', 'Azul', 'Feminino', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO assinaturas (aluno_id, plano_id, valor_mensalidade, status) VALUES
(1, 1, 70.00, 'ativa'),
(2, 1, 0.00, 'ativa');

INSERT INTO pagamentos (assinatura_id, valor_pago, data_pagamento) VALUES (1, 70.00, CURRENT_DATE - INTERVAL '15 days');
INSERT INTO graduacoes (aluno_id, faixa, data_graduacao) VALUES (1, 'Azul', '2023-06-15'), (1, 'Roxa', '2024-07-01');
INSERT INTO aulas (data_aula, turma, descricao) VALUES (CURRENT_DATE - INTERVAL '2 days', 'Adultos', 'Treino de passagem de guarda');