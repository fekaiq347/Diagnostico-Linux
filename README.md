# Diagnóstico de Sistema Linux

Este projeto contém um script em **Shell (Bash)** que realiza um diagnóstico completo de sistemas Linux. O script coleta informações essenciais, como data/hora, informações do sistema operacional, kernel, CPU, memória, disco, rede, processos, inodes e logs do sistema. Além disso, ele implementa validação de dependências, opções de linha de comando, modularização e tratamento de erros para tornar a ferramenta robusta e flexível.

## Sumário

- [Visão Geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Estrutura e Componentes do Script](#estrutura-e-componentes-do-script)
  - [Cabeçalho e Metadados](#cabeçalho-e-metadados)
  - [Modularização](#modularização)
  - [Arquivo de Log](#arquivo-de-log)
  - [Tratamento de Logs e Erros](#tratamento-de-logs-e-erros)
  - [Validação de Dependências](#validação-de-dependências)
  - [Opções de Linha de Comando](#opções-de-linha-de-comando)
  - [Funções de Diagnóstico](#funções-de-diagnóstico)
- [Como Usar](#como-usar)
- [Contribuições](#contribuições)
- [Contato](#contato)

## Visão Geral

Este script foi desenvolvido para auxiliar administradores e usuários a identificar rapidamente o estado de um sistema Linux. Ao reunir dados críticos do sistema em um único local, o diagnóstico se torna mais fácil e rápido. A ferramenta pode ser personalizada e adaptada conforme a necessidade do ambiente, tornando-a uma base sólida para monitoramento e troubleshooting.

## Funcionalidades

- **Validação de Dependências:** Garante que todos os comandos necessários estejam disponíveis no sistema.
- **Opções de Linha de Comando:** Permite a execução seletiva dos diagnósticos (ex.: apenas CPU, memória ou rede).
- **Modularização:** Possibilidade de carregar um arquivo de configuração externo para customizações sem modificar o script principal.
- **Tratamento de Erros:** Verificação da execução dos comandos e registro de mensagens de falha.
- **Diagnóstico Completo:** Coleta dados de data/hora, sistema operacional, kernel, CPU, memória, disco, rede, processos, inodes e logs.

## Estrutura e Componentes do Script

### Cabeçalho e Metadados

No início do script, há um cabeçalho que contém informações como:
- **Autor, Data e Versão:** Identifica quem criou o script, quando e qual é a versão atual.
- **Descrição:** Um resumo das funcionalidades e objetivos do script.
- **Uso e Opções:** Instruções de como executar o script e quais parâmetros podem ser utilizados.

Esse cabeçalho é importante para documentação e para que outros colaboradores entendam o propósito e a evolução do projeto.

### Modularização

O script possibilita a inclusão de um arquivo de configuração externo (por padrão, `diagnostico_config.sh`). Se este arquivo estiver presente, ele será carregado com o comando `source`, permitindo que variáveis e parâmetros sejam ajustados sem alterar o código principal.

```bash
# Configuração de modularização: se existir, carrega configurações adicionais.
CONFIG_FILE="./diagnostico_config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi
```

### Arquivo de Log

O script gera um arquivo de log cujo nome é definido dinamicamente com base na data e hora de execução. Esse log registra todas as saídas e erros, facilitando a análise posterior.

```bash
LOGFILE="./diagnostico_$(date +%Y%m%d_%H%M%S).log"
```

A função `log` centraliza a impressão de mensagens no terminal e a gravação no log:

```bash
log() {
    echo -e "$1" | tee -a "$LOGFILE"
}
```

### Tratamento de Logs e Erros

Para garantir robustez, o script possui um mecanismo de tratamento de erros. A função `error_exit` exibe uma mensagem de erro e encerra o script caso uma operação crítica falhe:

```bash
error_exit() {
    log "Erro: $1"
    exit 1
}
```

Cada função de diagnóstico possui testes que verificam se o comando foi executado com sucesso. Se não, uma mensagem de erro é registrada no log.

### Validação de Dependências

Antes de executar os diagnósticos, o script valida se os comandos essenciais estão instalados. A função `check_dependencies` percorre uma lista de comandos e interrompe a execução se algum deles estiver ausente:

```bash
check_dependencies() {
    local deps=(date uname grep free df lsblk ip ps tail getopt)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_exit "O comando '$cmd' não foi encontrado. Instale-o para continuar."
        fi
    done
}
```

### Opções de Linha de Comando

O script utiliza o `getopt` para interpretar as opções fornecidas na linha de comando. Isso permite que o usuário selecione quais diagnósticos deseja executar:

- **Exemplo de opções:**  
  `--cpu`, `--memoria`, `--rede`, etc.

Se nenhuma opção for passada, o script executa todas as funções de diagnóstico (opção padrão).

O parse das opções é feito da seguinte forma:

```bash
# Inicializa flags de diagnóstico
RUN_ALL=0
RUN_DATA=0
...
# Se nenhum parâmetro for fornecido, executa todos os diagnósticos
if [ $# -eq 0 ]; then
    RUN_ALL=1
fi

# Parse de opções usando getopt
OPTS=$(getopt -o adokcmDnpilh --long all,data,os,kernel,cpu,memoria,disco,rede,processos,inode,logs,help -n 'diagnostico.sh' -- "$@")
...
while true; do
    case "$1" in
        -a|--all)
            RUN_ALL=1
            shift ;;
        -d|--data)
            RUN_DATA=1
            shift ;;
        ...
        -h|--help)
            usage
            shift ;;
        --)
            shift
            break ;;
        *)
            break ;;
    esac
done
```

Ao final, se a flag `RUN_ALL` estiver ativa, todas as funções são marcadas para execução.

### Funções de Diagnóstico

Cada área do sistema possui uma função específica para coletar e registrar as informações:

- **diagnostico_data_hora:**  
  Coleta a data e hora atual do sistema utilizando o comando `date`.

- **diagnostico_os:**  
  Lê informações do sistema operacional a partir do arquivo `/etc/os-release`. Se o arquivo não existir, utiliza `uname -a` para obter os dados.

- **diagnostico_kernel:**  
  Exibe a versão atual do kernel com `uname -r`.

- **diagnostico_cpu:**  
  Obtém informações da CPU, como o modelo e o número de núcleos, através da leitura do arquivo `/proc/cpuinfo`.

- **diagnostico_memoria:**  
  Exibe o uso de memória de forma legível utilizando o comando `free -h`.

- **diagnostico_disco:**  
  Lista informações sobre o uso do disco e o particionamento usando `df -h` e `lsblk`.

- **diagnostico_rede:**  
  Coleta detalhes das interfaces de rede e a tabela de rotas com os comandos `ip addr show` e `ip route`.

- **diagnostico_processos:**  
  Mostra os processos em execução ordenados pelo uso de CPU e memória, utilizando `ps aux` com ordenação apropriada.

- **diagnostico_inode:**  
  Exibe o uso de inodes no sistema através do comando `df -i`.

- **diagnostico_logs:**  
  Mostra as últimas linhas dos logs do sistema, procurando por `/var/log/syslog` ou `/var/log/messages`.

Cada função contém verificações para garantir que, se algum comando falhar, uma mensagem de erro seja registrada no log, contribuindo para um diagnóstico mais seguro e informativo.

## Como Usar

1. **Clone o repositório:**

   ```bash
   git clone https://github.com/seu-usuario/diagnostico-sistema-linux.git
   ```

2. **Navegue até o diretório do projeto:**

   ```bash
   cd diagnostico-sistema-linux
   ```

3. **Torne o script executável:**

   ```bash
   chmod +x diagnostico.sh
   ```

4. **Execute o script com privilégios de superusuário (para coletar todas as informações):**

   ```bash
   sudo ./diagnostico.sh
   ```

5. **Uso de opções específicas:**

   Para executar apenas alguns diagnósticos, utilize as opções de linha de comando. Exemplo, para verificar somente a CPU, memória e rede:

   ```bash
   sudo ./diagnostico.sh --cpu --memoria --rede
   ```

## Contribuições

Contribuições são bem-vindas! Se você deseja melhorar o script, corrigir erros ou adicionar novas funcionalidades, siga os passos abaixo:

1. Faça um fork do repositório.
2. Crie uma branch para sua feature: `git checkout -b minha-feature`
3. Faça suas modificações e commit: `git commit -m 'Adiciona nova funcionalidade X'`
4. Envie para o repositório remoto: `git push origin minha-feature`
5. Abra um Pull Request para revisão.

## Contato

- **Autor:** Seu Nome  
- **E-mail:** seu.email@exemplo.com  
- **GitHub:** [https://github.com/fekaiq347](https://github.com/fekaiq347)

---

Este README detalha cada parte do script, explicando a finalidade e o funcionamento de cada módulo e função. Dessa forma, outros usuários e colaboradores poderão entender, utilizar e estender o projeto de forma eficaz. Sinta-se à vontade para ajustar as seções conforme as necessidades do seu projeto!
