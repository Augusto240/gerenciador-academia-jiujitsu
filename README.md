# Sistema de Gestão para Academia de Artes Marciais

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Sinatra](https://img.shields.io/badge/Sinatra-000000?style=for-the-badge&logo=sinatra&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

Uma aplicação web completa para gestão de academias de artes marciais (Jiu-Jitsu e Muay Thai), desenvolvida para ser uma ferramenta robusta e fácil de usar. O projeto é totalmente containerizado com Docker para garantir um ambiente de desenvolvimento e implantação consistente e portátil.

## Sobre o Projeto

Este projeto nasceu de uma necessidade real: substituir a planilha manual do meu professor por uma solução digital, centralizada e eficiente. O que começou como um simples CRUD (Cadastro, Leitura, Edição e Deleção) de alunos, evoluiu para um sistema de gestão multifacetado, capaz de controlar aspectos financeiros, de progressão e de frequência dos alunos, tudo isso rodando em uma arquitetura moderna com Docker.

## Funcionalidades Implementadas

### Gestão de Alunos
* ✅ **CRUD Completo:** Cadastro, edição e exclusão com busca e filtros avançados (por nome, faixa, turma e modalidade).
* ✅ **Suporte Multi-Modalidade:** Gerenciamento de alunos de Jiu-Jitsu e Muay Thai com faixas e turmas específicas.
* ✅ **Página de Detalhes:** Visão 360º de cada aluno com dados cadastrais, status financeiro, histórico de graduações e frequência.
* ✅ **Anamnese:** Seção dedicada para registrar informações importantes de saúde.

### Controle Financeiro
* ✅ **Mensalidades:** Sistema para registrar pagamentos com cálculo automático de status ("Em Dia", "Atrasado", "Pendente").
* ✅ **Relatório de Mensalidades:** Visualização consolidada do status financeiro de todos os alunos.
* ✅ **Suporte a Bolsistas:** Alunos podem ser marcados como bolsistas com mensalidade zerada.

### Aulas e Presença
* ✅ **Controle de Aulas:** Cadastro de aulas por modalidade (Jiu-Jitsu ou Muay Thai) e turma.
* ✅ **Lista de Chamada:** Interface intuitiva para marcar presença dos alunos.
* ✅ **Filtro Automático:** Lista de presença filtra automaticamente alunos pela modalidade da aula.

### Dashboard e Relatórios
* ✅ **Dashboard Interativo:** Estatísticas, gráficos de presença, status de mensalidades e aniversariantes do mês.
* ✅ **Sistema de Notificações:** Alertas automáticos para mensalidades atrasadas e aniversários.
* ✅ **Relatórios de Frequência:** Geração de relatórios com exportação para CSV e filtros por período.

### Técnico
* ✅ **Interface Moderna:** UI profissional com paleta de cores sóbria e componentes consistentes.
* ✅ **Ambiente Containerizado:** 100% configurado com Docker e Docker Compose.
* ✅ **Testes Automatizados:** Suite de testes com Minitest e Rack::Test.
* ✅ **Segurança:** BCrypt para senhas, Prepared Statements contra SQL Injection, proteção XSS.
* ✅ **Padrões de Design:** MVC, Presenter Pattern, Service Objects, Connection Pool.

## Tecnologias Utilizadas

| Categoria | Tecnologia |
|-----------|------------|
| **Backend** | Ruby 3.2.3 com Sinatra |
| **Banco de Dados** | PostgreSQL 14 |
| **Frontend** | HTML5, CSS3, JavaScript, ERB |
| **Visualização** | Chart.js |
| **Containerização** | Docker & Docker Compose |
| **Testes** | Minitest, Rack::Test |
| **Segurança** | BCrypt, Prepared Statements |

## Como Rodar o Projeto

Graças ao Docker, iniciar todo o ambiente (aplicação + banco de dados) requer poucos passos.

### Pré-requisitos

* [Git](https://git-scm.com/downloads)
* [Docker](https://www.docker.com/products/docker-desktop/) (Docker Desktop no Windows/Mac ou Docker Engine no Linux)

### Instalação e Execução

1.  **Clone o repositório para sua máquina local:**
    ```bash
    git clone https://github.com/Augusto240/gerenciador-academia-jiujitsu.git
    ```

2.  **Acesse a pasta do projeto:**
    ```bash
    cd gerenciador-academia-jiujitsu
    ```

3.  **Construa e inicie os contêineres:**
    ```bash
    docker compose up --build
    ```
    Este único comando irá baixar as imagens necessárias, construir o ambiente do aplicativo, iniciar o banco de dados com a estrutura correta e conectar tudo.

4.  **Acesse a aplicação:**
    Abra seu navegador e vá para o endereço: **[http://localhost:4567](http://localhost:4567)**

5.  **Credenciais padrão para login:**
    ```
    Email: admin@jpteam.com
    Senha: admin123
    ```

Para parar todo o ambiente, basta voltar ao terminal e pressionar `Ctrl` + `C`.

## Estrutura do Projeto
```
/
├── app.rb                   # Aplicação principal Sinatra com rotas
├── config/
│   └── database.rb          # Configuração do pool de conexões PostgreSQL
├── app/
│   ├── helpers/
│   │   └── validador.rb     # Validações de dados
│   ├── models/              # Modelos de dados (Aluno, Aula, Presenca, etc.)
│   ├── presenters/          # Padrão Presenter para lógica de apresentação
│   └── services/            # Service Objects para operações complexas
├── views/                   # Templates ERB
│   ├── alunos/              # Views de alunos
│   ├── aulas/               # Views de aulas e presença
│   ├── auth/                # Tela de login
│   └── relatorios/          # Views de relatórios
├── public/                  # Arquivos estáticos (CSS, imagens)
├── test/                    # Testes automatizados
├── bin/                     # Scripts utilitários
├── initdb/                  # Scripts de inicialização do banco
│   ├── 10_schema.sql        # Estrutura das tabelas
│   └── 20_data.sql          # Dados iniciais
├── Dockerfile               # Imagem Docker do aplicativo
├── docker-compose.yml       # Orquestração dos containers
└── README.md                # Esta documentação
```

## Padrões de Design Implementados

* **MVC (Model-View-Controller):** Separação clara entre a camada de dados, a lógica de negócio e a interface do usuário.
* **Presenter Pattern:** Separa a lógica de apresentação dos modelos de dados, tornando as views mais limpas e reutilizáveis.
* **Service Objects:** Encapsula operações complexas de negócio em classes dedicadas e reutilizáveis.
* **Connection Pool:** Gerencia eficientemente as conexões com o banco de dados para melhor performance.

## 📚 Documentação de Rotas (API)

### Autenticação
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/login` | Página de login |
| POST | `/login` | Autenticar usuário (email, password) |
| POST | `/logout` | Encerrar sessão |

### Alunos
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/` | Lista de alunos (com filtros: busca, faixa, turma, modalidade) |
| GET | `/alunos/novo` | Formulário de novo aluno |
| POST | `/alunos` | Criar aluno |
| GET | `/alunos/:id` | Detalhes do aluno |
| GET | `/alunos/:id/editar` | Formulário de edição |
| PUT | `/alunos/:id` | Atualizar aluno |
| DELETE | `/alunos/:id` | Excluir aluno (soft delete) |
| GET | `/alunos-excluidos` | Lista de alunos excluídos (admin) |
| POST | `/alunos/:id/restaurar` | Restaurar aluno excluído |

### Aulas
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/aulas` | Lista de aulas (com filtros: data_inicio, data_fim, turma_filtro) |
| GET | `/aulas/nova` | Formulário de nova aula |
| POST | `/aulas` | Criar aula |
| GET | `/aulas/:id` | Detalhes e lista de presença |
| POST | `/aulas/:id/presencas` | Atualizar presenças |

### Pagamentos e Graduações
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/pagamentos` | Registrar pagamento |
| POST | `/graduacoes` | Registrar graduação |

### Relatórios
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/relatorios` | Lista de relatórios disponíveis |
| GET | `/relatorios/frequencia` | Relatório de frequência (formato: html/csv) |
| GET | `/relatorios/mensalidades` | Relatório de mensalidades (formato: html/csv) |

### Outros
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/dashboard` | Dashboard com estatísticas |
| GET | `/health` | Health check (JSON) |
| POST | `/notificacoes/:id/marcar-como-lida` | Marcar notificação como lida |

## Executando os Testes

```bash
# Via Docker
docker compose exec app ruby -Ilib:test -e "Dir['test/**/*_test.rb'].each { |f| require_relative f }"

# Localmente (com Ruby instalado)
ruby -Ilib:test -e "Dir['test/**/*_test.rb'].each { |f| require_relative f }"
```

## Roadmap de Melhorias

* [ ] Implementar autenticação de dois fatores (2FA)
* [ ] Adicionar portal do aluno para acesso próprio às informações
* [ ] Desenvolver aplicativo móvel complementar
* [ ] Integrar com métodos de pagamento online
* [ ] Implementar sistema de eventos e competições
* [ ] Adicionar backup automático dos dados

---

## Autor

**Augusto Oliveira**

* GitHub: [https://github.com/Augusto240](https://github.com/Augusto240)
* LinkedIn: [https://www.linkedin.com/in/augusto-oliveira-4a8068235/](https://www.linkedin.com/in/augusto-oliveira-4a8068235/)
* Portfólio: [https://augusto240.github.io/Personal-Site/](https://augusto240.github.io/Personal-Site/)