-- Garante uma recriação limpa
DROP TABLE IF EXISTS presencas, aulas, graduacoes, pagamentos, assinaturas, planos, usuarios, alunos, notificacoes CASCADE;

-- Tabela de Usuários do Sistema
CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  nome VARCHAR(100),
  admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
  saude_substancia TEXT,
  deleted_at TIMESTAMP DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

-- ======================
-- ÍNDICES PARA PERFORMANCE
-- ======================

-- Índice para busca de alunos por nome (usado no filtro)
CREATE INDEX idx_alunos_nome ON alunos(nome);
CREATE INDEX idx_alunos_modalidade ON alunos(modalidade);
CREATE INDEX idx_alunos_turma ON alunos(turma);
CREATE INDEX idx_alunos_data_nascimento ON alunos(data_nascimento);

-- Índices para assinaturas
CREATE INDEX idx_assinaturas_aluno_id ON assinaturas(aluno_id);
CREATE INDEX idx_assinaturas_status ON assinaturas(status);

-- Índices para pagamentos
CREATE INDEX idx_pagamentos_assinatura_id ON pagamentos(assinatura_id);
CREATE INDEX idx_pagamentos_data ON pagamentos(data_pagamento DESC);

-- Índices para aulas
CREATE INDEX idx_aulas_data ON aulas(data_aula DESC);
CREATE INDEX idx_aulas_modalidade ON aulas(modalidade);
CREATE INDEX idx_aulas_turma ON aulas(turma);

-- Índices para presenças
CREATE INDEX idx_presencas_aula_id ON presencas(aula_id);
CREATE INDEX idx_presencas_aluno_id ON presencas(aluno_id);
CREATE INDEX idx_presencas_presente ON presencas(presente) WHERE presente = TRUE;

-- Índices para graduações
CREATE INDEX idx_graduacoes_aluno_id ON graduacoes(aluno_id);
CREATE INDEX idx_graduacoes_data ON graduacoes(data_graduacao DESC);

-- Índices para notificações
CREATE INDEX idx_notificacoes_lida ON notificacoes(lida) WHERE lida = FALSE;
CREATE INDEX idx_notificacoes_criado_em ON notificacoes(criado_em DESC);