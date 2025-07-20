-- --- DADOS DE EXEMPLO PARA DESENVOLVIMENTO LOCAL ---

-- Adiciona um usuário padrão
INSERT INTO usuarios (email, nome, password_digest) VALUES
('admin@jpteam.com', 'Admin JPM', '$2a$12$4a.ODd3/OT2u2K.2gG7yE.cwkFP7aVz0qtlB6nflhN4uY1S0v1u.S')
ON CONFLICT (email) DO NOTHING;

INSERT INTO planos (id, nome, valor) VALUES (1, 'Plano Padrão', 70.00) ON CONFLICT (id) DO NOTHING;

-- Inserindo dados de exemplo
INSERT INTO alunos (id, nome, data_nascimento, cor_faixa, turma, bolsista) VALUES
(1, 'José Augusto (Exemplo)', '2005-08-09', 'Roxa', 'Adultos', FALSE),
(2, 'Maria Oliveira (Exemplo)', '1998-08-22', 'Azul', 'Feminino', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO assinaturas (aluno_id, plano_id, valor_mensalidade, status) VALUES
(1, 1, 70.00, 'ativa'),
(2, 1, 0.00, 'ativa');

INSERT INTO pagamentos (assinatura_id, valor_pago, data_pagamento) VALUES (1, 70.00, CURRENT_DATE - INTERVAL '15 days');
INSERT INTO graduacoes (aluno_id, faixa, data_graduacao) VALUES (1, 'Azul', '2023-06-15'), (1, 'Roxa', '2024-07-01');
INSERT INTO aulas (data_aula, turma, descricao) VALUES (CURRENT_DATE - INTERVAL '2 days', 'Adultos', 'Treino de passagem de guarda');