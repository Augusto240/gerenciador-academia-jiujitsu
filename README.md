# Sistema de Gestão para Academia de Jiu Jitsu

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Sinatra](https://img.shields.io/badge/Sinatra-000000?style=for-the-badge&logo=sinatra&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

Um aplicativo web simples para gerenciar o cadastro de alunos de uma academia de jiu-jitsu. O projeto é totalmente containerizado com Docker para garantir um ambiente de desenvolvimento robusto, portátil e fácil de executar.

## Sobre o Projeto

Este projeto nasceu de uma necessidade real. Meu professor de jiu jitsu queria ter um controle melhor sobre os alunos da academia, registrando informações como nome, data de nascimento, cor da faixa e a turma em que o aluno luta. A solução inicial foi uma simples planilha no Google Sheets, preenchida manualmente.

Como programador, vi uma oportunidade de criar uma solução melhor e mais robusta. A ideia evoluiu para um site simples de cadastro, edição e remoção de alunos, utilizando um banco de dados para garantir a integridade e escalabilidade dos dados. O projeto evoluiu para uma arquitetura moderna utilizando Docker e Docker Compose, garantindo um ambiente de desenvolvimento consistente e portátil.

## Funcionalidades Principais

* ✅ **Listagem de Alunos:** Visualização de todos os alunos cadastrados com cálculo automático de idade.
* ✅ **Cadastro de Alunos:** Formulário para adicionar novos alunos ao banco de dados.
* ✅ **Edição de Alunos:** Atualização das informações de um aluno existente.
* ✅ **Remoção de Alunos:** Exclusão de um aluno do sistema.
* ✅ **Interface Aprimorada:** Formulários com menus de seleção para padronização de dados (faixas e turmas) e mensagens de feedback visual para o usuário após cada ação.
* ✅ **Banco de Dados Automatizado:** A base de dados e a tabela são criadas e populadas com dados de exemplo automaticamente na inicialização.

## Tecnologias Utilizadas

* **Backend:** Ruby 3.2.3 com o micro-framework Sinatra
* **Banco de Dados:** MariaDB 10.11
* **Frontend:** HTML5, CSS3, ERB (Embedded Ruby)
* **Ambiente e Orquestração:** Docker & Docker Compose

## Como Rodar o Projeto

Graças ao Docker, iniciar todo o ambiente (aplicação + banco de dados) requer apenas um comando.

### Pré-requisitos

* [Git](https://git-scm.com/downloads)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) com a integração do WSL 2 ativada e em execução.

### Instalação e Execução

1.  **Clone o repositório para sua máquina local:**
    ```bash
    git clone [https://github.com/Augusto240/gerenciador-academia-jiujitsu.git](https://github.com/Augusto240/gerenciador-academia-jiujitsu.git)
    ```

2.  **Acesse a pasta do projeto:**
    ```bash
    cd gerenciador-academia-jiujitsu
    ```

3.  **Construa e inicie os contêineres:**
    ```bash
    docker compose up --build
    ```
    Este único comando irá baixar as imagens necessárias, construir o ambiente do aplicativo, iniciar o banco de dados e conectar tudo.

4.  **Acesse a aplicação:**
    Abra seu navegador e vá para o endereço: **[http://localhost:4567](http://localhost:4567)**

Para parar todo o ambiente, basta voltar ao terminal e pressionar `Ctrl` + `C`.

## Estrutura do Projeto

```
/
|-- app.rb                  # O coração da aplicação Sinatra, com todas as rotas e lógica.
|-- Dockerfile              # A "receita" para construir a imagem Docker do aplicativo Ruby.
|-- docker-compose.yml      # O "maestro" que orquestra os contêineres do app e do banco de dados.
|-- init.sql                # Script que cria a tabela `alunos` e insere dados iniciais no banco.
|-- Gemfile / Gemfile.lock  # Define e trava as dependências (gems) do projeto.
|-- /public/                # Pasta para arquivos estáticos (CSS, imagens).
|-- /views/                 # Pasta para os templates de HTML com Ruby embutido (ERB).
|-- README.md               # Este arquivo de documentação.
```

## Roadmap de Melhorias

* **Melhorias de UI/UX:**
    * [x] Utilizar menus de seleção (`<select>`) para campos como "Cor da Faixa" e "Turma".
    * [x] Adicionar mensagens de feedback para o usuário (ex: "Aluno cadastrado com sucesso!").
    * [x] Calcular e exibir a idade do aluno dinamicamente.
    * [ ] Implementar paginação na lista de alunos caso a lista fique muito grande.
* **Novas Funcionalidades:**
    * [ ] Implementar um sistema de **Controle de Presença**.
    * [ ] Criar um **Histórico de Graduação** para cada aluno.
    * [ ] Adicionar um **Controle de Mensalidades**.
* **Melhorias Técnicas:**
    * [ ] Adicionar um **Sistema de Login (Autenticação)** para proteger o acesso.
    * [ ] Escrever testes automatizados para a aplicação.

---

## Autor

**Augusto Oliveira**

* GitHub: `https://github.com/Augusto240`
* LinkedIn: `https://www.linkedin.com/in/augusto-oliveira-4a8068235/`
* Portfólio: `https://augusto240.github.io/Personal-Site/`