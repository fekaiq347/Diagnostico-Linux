#!/bin/bash
# -----------------------------------------------------------------------------
# Script de Diagnóstico de Sistema para Linux
# Autor: Kaique Eufrásio
# Data: 2025-03-26
# Versão: 2.0
#
# Descrição:
#   Este script coleta informações detalhadas do sistema Linux para diagnóstico,
#   incluindo data/hora, OS, kernel, CPU, memória, disco, rede, processos,
#   inodes e logs do sistema. Foram adicionadas:
#     - Validação de dependências
#     - Suporte a opções de linha de comando
#     - Modularização (possibilidade de incluir um arquivo de configuração)
#     - Tratamento de erros
#
# Uso:
#   sudo ./diagnostico.sh [opções]
#
# Opções:
#   -a, --all           Executa todos os diagnósticos (padrão se nenhuma opção for
#                       especificada)
#   -d, --data          Data e hora do sistema
#   -o, --os            Informações do sistema operacional
#   -k, --kernel        Versão do kernel
#   -c, --cpu           Informações da CPU
#   -m, --memoria       Uso de memória
#   -D, --disco         Uso de disco e particionamento
#   -n, --rede          Informações de rede e tabela de rotas
#   -p, --processos     Processos em execução (top 10 por CPU e memória)
#   -i, --inode         Uso de inodes
#   -l, --logs          Últimas linhas do log do sistema
#   -h, --help          Exibe esta mensagem de ajuda
#
# Exemplo:
#   sudo ./diagnostico.sh --cpu --memoria --rede
#
# Observação:
#   Personalize conforme suas necessidades. É recomendado executar como root.
# -----------------------------------------------------------------------------

# Configuração de modularização: se existir, carrega configurações adicionais.
CONFIG_FILE="./diagnostico_config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Define o arquivo de log com timestamp
LOGFILE="./diagnostico_$(date +%Y%m%d_%H%M%S).log"

# Função para imprimir mensagens e salvar no log
log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# Função para tratamento de erros
error_exit() {
    log "Erro: $1"
    exit 1
}

# Validação de dependências: comandos necessários
check_dependencies() {
    local deps=(date uname grep free df lsblk ip ps tail getopt)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_exit "O comando '$cmd' não foi encontrado. Instale-o para continuar."
        fi
    done
}

# Exibe a mensagem de uso
usage() {
    cat <<EOF
Uso: $0 [opções]

Opções:
  -a, --all           Executa todos os diagnósticos (padrão se nenhuma opção for especificada)
  -d, --data          Data e hora do sistema
  -o, --os            Informações do sistema operacional
  -k, --kernel        Versão do kernel
  -c, --cpu           Informações da CPU
  -m, --memoria       Uso de memória
  -D, --disco         Uso de disco e particionamento
  -n, --rede          Informações de rede e tabela de rotas
  -p, --processos     Processos em execução (top 10 por CPU e memória)
  -i, --inode         Uso de inodes
  -l, --logs          Últimas linhas do log do sistema
  -h, --help          Exibe esta mensagem de ajuda

Exemplo:
  sudo $0 --cpu --memoria --rede
EOF
    exit 0
}

# Inicializa flags de diagnóstico
RUN_ALL=0
RUN_DATA=0
RUN_OS=0
RUN_KERNEL=0
RUN_CPU=0
RUN_MEM=0
RUN_DISCO=0
RUN_REDE=0
RUN_PROCESSOS=0
RUN_INODE=0
RUN_LOGS=0

# Se nenhum parâmetro for fornecido, executa todos os diagnósticos
if [ $# -eq 0 ]; then
    RUN_ALL=1
fi

# Parse de opções usando getopt
OPTS=$(getopt -o adokcmDnpilh --long all,data,os,kernel,cpu,memoria,disco,rede,processos,inode,logs,help -n 'diagnostico.sh' -- "$@")
if [ $? != 0 ]; then
    usage
fi

eval set -- "$OPTS"

while true; do
    case "$1" in
        -a|--all)
            RUN_ALL=1
            shift ;;
        -d|--data)
            RUN_DATA=1
            shift ;;
        -o|--os)
            RUN_OS=1
            shift ;;
        -k|--kernel)
            RUN_KERNEL=1
            shift ;;
        -c|--cpu)
            RUN_CPU=1
            shift ;;
        -m|--memoria)
            RUN_MEM=1
            shift ;;
        -D|--disco)
            RUN_DISCO=1
            shift ;;
        -n|--rede)
            RUN_REDE=1
            shift ;;
        -p|--processos)
            RUN_PROCESSOS=1
            shift ;;
        -i|--inode)
            RUN_INODE=1
            shift ;;
        -l|--logs)
            RUN_LOGS=1
            shift ;;
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

# Se RUN_ALL estiver ativado, habilita todas as opções
if [ $RUN_ALL -eq 1 ]; then
    RUN_DATA=1
    RUN_OS=1
    RUN_KERNEL=1
    RUN_CPU=1
    RUN_MEM=1
    RUN_DISCO=1
    RUN_REDE=1
    RUN_PROCESSOS=1
    RUN_INODE=1
    RUN_LOGS=1
fi

# Verifica se está sendo executado como root (apenas aviso)
check_root() {
    if [[ $EUID -ne 0 ]]; then
       log "Aviso: É recomendado executar este script como root para obter informações completas."
    fi
}

# Função de diagnóstico para data e hora do sistema
diagnostico_data_hora() {
    log "\n====== Data e Hora do Sistema ======"
    if ! date | tee -a "$LOGFILE"; then
        log "Falha ao coletar data e hora."
    fi
}

# Função de diagnóstico para informações do sistema operacional
diagnostico_os() {
    log "\n====== Informações do Sistema Operacional ======"
    if [ -f /etc/os-release ]; then
        if ! cat /etc/os-release | tee -a "$LOGFILE"; then
            log "Falha ao ler /etc/os-release."
        fi
    else
        if ! uname -a | tee -a "$LOGFILE"; then
            log "Falha ao coletar informações do kernel com uname."
        fi
    fi
}

# Função de diagnóstico para versão do kernel
diagnostico_kernel() {
    log "\n====== Versão do Kernel ======"
    if ! uname -r | tee -a "$LOGFILE"; then
        log "Falha ao coletar a versão do kernel."
    fi
}

# Função de diagnóstico para informações da CPU
diagnostico_cpu() {
    log "\n====== Informações da CPU ======"
    if [ -f /proc/cpuinfo ]; then
        if ! grep "model name" /proc/cpuinfo | uniq | tee -a "$LOGFILE"; then
            log "Falha ao coletar o modelo da CPU."
        fi
        if ! grep "cpu cores" /proc/cpuinfo | uniq | tee -a "$LOGFILE"; then
            log "Falha ao coletar a quantidade de núcleos da CPU."
        fi
    else
        log "Arquivo /proc/cpuinfo não encontrado."
    fi
}

# Função de diagnóstico para uso de memória
diagnostico_memoria() {
    log "\n====== Uso de Memória ======"
    if ! free -h | tee -a "$LOGFILE"; then
        log "Falha ao coletar informações de memória."
    fi
}

# Função de diagnóstico para uso de disco e particionamento
diagnostico_disco() {
    log "\n====== Uso de Disco ======"
    if ! df -h | tee -a "$LOGFILE"; then
        log "Falha ao coletar informações de disco."
    fi
    log "\n====== Partições e Dispositivos ======"
    if ! lsblk | tee -a "$LOGFILE"; then
        log "Falha ao listar dispositivos e partições."
    fi
}

# Função de diagnóstico para informações de rede
diagnostico_rede() {
    log "\n====== Informações de Rede ======"
    if ! ip addr show | tee -a "$LOGFILE"; then
        log "Falha ao coletar informações das interfaces de rede."
    fi
    log "\n====== Tabela de Rotas ======"
    if ! ip route | tee -a "$LOGFILE"; then
        log "Falha ao coletar a tabela de rotas."
    fi
}

# Função de diagnóstico para processos em execução
diagnostico_processos() {
    log "\n====== Processos em Execução (Top 10 por uso de CPU) ======"
    if ! ps aux --sort=-%cpu | head -n 11 | tee -a "$LOGFILE"; then
        log "Falha ao coletar processos por CPU."
    fi
    log "\n====== Processos em Execução (Top 10 por uso de Memória) ======"
    if ! ps aux --sort=-%mem | head -n 11 | tee -a "$LOGFILE"; then
        log "Falha ao coletar processos por memória."
    fi
}

# Função de diagnóstico para uso de inodes
diagnostico_inode() {
    log "\n====== Uso de Inodes ======"
    if ! df -i | tee -a "$LOGFILE"; then
        log "Falha ao coletar informações de inodes."
    fi
}

# Função de diagnóstico para últimas linhas dos logs do sistema
diagnostico_logs() {
    log "\n====== Últimas Linhas do Log do Sistema ======"
    if [ -f /var/log/syslog ]; then
        if ! tail -n 20 /var/log/syslog | tee -a "$LOGFILE"; then
            log "Falha ao ler /var/log/syslog."
        fi
    elif [ -f /var/log/messages ]; then
        if ! tail -n 20 /var/log/messages | tee -a "$LOGFILE"; then
            log "Falha ao ler /var/log/messages."
        fi
    else
        log "Log do sistema não encontrado."
    fi
}

# Função principal para executar os diagnósticos selecionados
executar_diagnostico() {
    check_dependencies
    check_root

    [ $RUN_DATA -eq 1 ] && diagnostico_data_hora
    [ $RUN_OS -eq 1 ] && diagnostico_os
    [ $RUN_KERNEL -eq 1 ] && diagnostico_kernel
    [ $RUN_CPU -eq 1 ] && diagnostico_cpu
    [ $RUN_MEM -eq 1 ] && diagnostico_memoria
    [ $RUN_DISCO -eq 1 ] && diagnostico_disco
    [ $RUN_REDE -eq 1 ] && diagnostico_rede
    [ $RUN_PROCESSOS -eq 1 ] && diagnostico_processos
    [ $RUN_INODE -eq 1 ] && diagnostico_inode
    [ $RUN_LOGS -eq 1 ] && diagnostico_logs

    log "\nDiagnóstico concluído. Log salvo em: $LOGFILE"
}

# Execução do script
executar_diagnostico

