# Sistema de Gestão para Academia de Jiu Jitsu

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Sinatra](https://img.shields.io/badge/Sinatra-000000?style=for-the-badge&logo=sinatra&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

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
* ✅ **Interface Moderna e Profissional:** UI completamente redesenhada com uma paleta de cores sóbria, tipografia clara e componentes consistentes.
* ✅ **Ambiente Containerizado:** 100% configurado com Docker e Docker Compose para portabilidade e facilidade de execução.
* ✅ **Segurança de Dados:** Separação da estrutura (`schema.sql`) e dos dados (`data.sql`), com os dados sensíveis dos alunos sendo ignorados pelo Git para garantir a privacidade.

## Tecnologias Utilizadas

* **Backend:** Ruby 3.2.3 com o micro-framework Sinatra
* **Banco de Dados:** MariaDB 10.11
* **Frontend:** HTML5, CSS3, ERB (Embedded Ruby)
* **Ambiente e Orquestração:** Docker & Docker Compose

## Como Rodar o Projeto

Graças ao Docker, iniciar todo o ambiente (aplicação + banco de dados) requer poucos passos.

### Pré-requisitos

* [Git](https://git-scm.com/downloads)
* [Docker](https://www.docker.com/products/docker-desktop/) (Docker Desktop no Windows/Mac ou Docker Engine no Linux)

### Instalação e Execução

1.  **Clone o repositório para sua máquina local:**
    ```bash
    git clone [https://github.com/Augusto240/gerenciador-academia-jiujitsu.git](https://github.com/Augusto240/gerenciador-academia-jiujitsu.git)
    ```

2.  **Acesse a pasta do projeto:**
    ```bash
    cd gerenciador-academia-jiujitsu
    ```
3.  **(Apenas na primeira vez em uma máquina nova)** Crie um arquivo de dados vazio para o Docker. Como os dados dos alunos são privados e não vão para o GitHub, este passo é necessário para que o ambiente inicie corretamente.
    ```bash
    touch initdb/20_data.sql
    ```

4.  **Construa e inicie os contêineres:**
    ```bash
    docker compose up --build
    ```
    Este único comando irá baixar as imagens necessárias, construir o ambiente do aplicativo, iniciar o banco de dados com a estrutura correta e conectar tudo.

5.  **Acesse a aplicação:**
    Abra seu navegador e vá para o endereço: **[http://localhost:4567](http://localhost:4567)**

Para parar todo o ambiente, basta voltar ao terminal e pressionar `Ctrl` + `C`.

## Estrutura do Projeto

```
/
|-- app.rb                  # O coração da aplicação Sinatra, com todas as rotas e lógica.
|-- Dockerfile              # A "receita" para construir a imagem Docker do aplicativo Ruby.
|-- docker-compose.yml      # O "maestro" que orquestra os contêineres do app e do banco.
|-- /initdb/                # Pasta com os scripts de inicialização do banco de dados.
|   |-- 10_schema.sql       # Cria a estrutura de todas as tabelas. (Público)
|   |-- 20_data.sql         # Insere os dados dos alunos. (Privado, ignorado pelo Git)
|-- Gemfile / Gemfile.lock  # Define as dependências (gems) do projeto.
|-- /public/                # Pasta para arquivos estáticos (CSS, imagens).
|-- /views/                 # Pasta para os templates de HTML com Ruby embutido (ERB).
|-- README.md               # Este arquivo de documentação.
```

## Roadmap de Melhorias

* **Melhorias Técnicas:**
    * [ ] Adicionar um **Sistema de Login (Autenticação)** para proteger o acesso.
    * [ ] Escrever testes automatizados para a aplicação.
    * [ ] Implementar paginação na lista de alunos para melhor performance com muitos registros.
    * [ ] Refatorar o código para uma arquitetura mais orientada a objetos (ex: Models).

---

## Autor

**Augusto Oliveira**

* GitHub: `https://github.com/Augusto240`
* LinkedIn: `https://www.linkedin.com/in/augusto-oliveira-4a8068235/`
* Portfólio: `https://augusto240.github.io/Personal-Site/`