CREATE TABLE IF NOT EXISTS alunos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  data_nascimento DATE,
  cor_faixa VARCHAR(50),
  turma VARCHAR(50)
);

INSERT INTO alunos (nome, data_nascimento, cor_faixa, turma) VALUES
('João Silva', '2000-05-10', 'Azul', 'Manhã'),
('Maria Oliveira', '1998-08-22', 'Branca', 'Noite');
