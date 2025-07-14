# Sistema de Gestão para Academia de Jiu Jitsu

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Sinatra](https://img.shields.io/badge/Sinatra-000000?style=for-the-badge&logo=sinatra&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

Uma aplicação web completa para gestão de academias de jiu-jitsu, desenvolvida para ser uma ferramenta robusta e fácil de usar. O projeto é totalmente containerizado com Docker para garantir um ambiente de desenvolvimento e implantação consistente e portátil.

## Sobre o Projeto

Este projeto nasceu de uma necessidade real: substituir a planilha manual do meu professor por uma solução digital, centralizada e eficiente. O que começou como um simples CRUD (Cadastro, Leitura, Edição e Deleção) de alunos, evoluiu para um sistema de gestão multifacetado, capaz de controlar aspectos financeiros, de progressão e de frequência dos alunos, tudo isso rodando em uma arquitetura moderna com Docker.

## Funcionalidades Implementadas

* ✅ **Gestão Completa de Alunos:** CRUD completo com busca e filtros avançados (por nome, faixa e turma).
* ✅ **Página de Detalhes do Aluno:** Uma visão 360º de cada aluno, consolidando dados cadastrais, status financeiro, histórico de graduações e frequência.
* ✅ **Controle de Mensalidades:** Sistema para registrar pagamentos, com cálculo automático de status ("Em Dia", "Atrasado", "Pendente").
* ✅ **Histórico de Graduação:** Registro de todas as trocas de faixa de um aluno, atualizando seu status atual no sistema.
* ✅ **Controle de Aulas e Presença:** Cadastro de aulas por turma e uma interface de lista de chamada para marcar a presença dos alunos.
* ✅ **Anamnese:** Seção dedicada no cadastro e perfil do aluno para registrar informações importantes de saúde.
* ✅ **Dashboard Interativo:** Painel principal com estatísticas, gráficos de presença, status de mensalidades e aniversariantes do mês.
* ✅ **Sistema de Notificações:** Alertas automáticos para mensalidades atrasadas e aniversários, com interface para gerenciamento.
* ✅ **Relatórios e Exportação:** Geração de relatórios de frequência com exportação para CSV e filtros por período.
* ✅ **Interface Moderna e Profissional:** UI completamente redesenhada com uma paleta de cores sóbria, tipografia clara e componentes consistentes.
* ✅ **Ambiente Containerizado:** 100% configurado com Docker e Docker Compose para portabilidade e facilidade de execução.
* ✅ **Segurança de Dados:** Separação da estrutura (`schema.sql`) e dos dados (`data.sql`), com os dados sensíveis dos alunos sendo ignorados pelo Git para garantir a privacidade.
* ✅ **Padrão Presenter:** Implementado para separar a lógica de apresentação dos modelos de dados.
* ✅ **Service Objects:** Adicionados para encapsular operações de negócio complexas.
* ✅ **Paginação:** Implementada para melhorar a performance com grande volume de dados.
* ✅ **Pool de Conexões:** Sistema otimizado para gerenciamento eficiente de conexões com o banco de dados.
* ✅ **Validações Avançadas:** Sistema robusto de validação para todos os tipos de dados.
* ✅ **Proteção contra XSS:** Escapamento HTML consistente em toda a aplicação.

## Tecnologias Utilizadas

* **Backend:** Ruby 3.2.3 com o micro-framework Sinatra
* **Banco de Dados:** PostgreSQL 14
* **Frontend:** HTML5, CSS3, JavaScript, ERB (Embedded Ruby)
* **Visualização de Dados:** Chart.js para gráficos interativos
* **Ambiente e Orquestração:** Docker & Docker Compose
* **Segurança:** BCrypt para senhas, Prepared Statements para prevenção de SQL Injection

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
/
├── app.rb                   # O coração da aplicação Sinatra, com todas as rotas, lógica e padrões de design
├── Dockerfile               # A "receita" para construir a imagem Docker do aplicativo Ruby
├── docker-compose.yml       # O "maestro" que orquestra os contêineres do app e do banco
├── /initdb/                 # Pasta com os scripts de inicialização do banco de dados
│   └── 10_schema.sql        # Cria a estrutura de todas as tabelas
├── Gemfile / Gemfile.lock   # Define as dependências (gems) do projeto
├── /public/                 # Pasta para arquivos estáticos (CSS, imagens)
├── /views/                  # Pasta para os templates de HTML com Ruby embutido (ERB)
│   ├── /alunos/             # Templates relacionados a alunos
│   ├── /aulas/              # Templates relacionados a aulas
│   └── /relatorios/         # Templates para relatórios
└── README.md                # Este arquivo de documentação


## Padrões de Design Implementados

* **MVC (Model-View-Controller):** Separação clara entre a camada de dados, a lógica de negócio e a interface do usuário.
* **Presenter Pattern:** Separa a lógica de apresentação dos modelos de dados, tornando as views mais limpas e reutilizáveis.
* **Service Objects:** Encapsula operações complexas de negócio em classes dedicadas e reutilizáveis.
* **Connection Pool:** Gerencia eficientemente as conexões com o banco de dados para melhor performance.

## Roadmap de Melhorias

* **Melhorias Técnicas:**
    * [ ] Desenvolver um aplicativo móvel para complementar o sistema web.
    * [ ] Implementar funcionalidades de backup automático para os dados.
    * [ ] Escrever testes automatizados para a aplicação.
    * [ ] Adicionar um portal do aluno para acesso próprio às informações.
    * [ ] Integrar com métodos de pagamento online.
    * [ ] Implementar sistema de eventos e competições.

---

## Autor

**Augusto Oliveira**

* GitHub: [https://github.com/Augusto240](https://github.com/Augusto240)
* LinkedIn: [https://www.linkedin.com/in/augusto-oliveira-4a8068235/](https://www.linkedin.com/in/augusto-oliveira-4a8068235/)
* Portfólio: [https://augusto240.github.io/Personal-Site/](https://augusto240.github.io/Personal-Site/)