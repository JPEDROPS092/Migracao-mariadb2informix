#!/bin/bash

# Script para configurar e inicializar o Informix Database
# Autor: Setup automatizado para desenvolvimento

echo "🚀 Iniciando configuração do Informix Database..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado. Instale o Docker primeiro."
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
    exit 1
fi

# Criar diretório de configuração se não existir
if [ ! -d "./informix_config" ]; then
    print_status "Criando diretório de configuração..."
    mkdir -p ./informix_config
fi

# Parar containers existentes
print_status "Parando containers existentes..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null

# Remover volumes antigos (opcional - descomente se quiser começar do zero)
# print_warning "Removendo volumes antigos..."
# docker volume rm $(docker volume ls -q | grep informix) 2>/dev/null

# Iniciar o container
print_status "Iniciando container Informix..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi

# Aguardar inicialização
print_status "Aguardando inicialização do Informix (isso pode levar alguns minutos)..."
sleep 30

# Verificar status do container
CONTAINER_STATUS=$(docker inspect informix_database --format='{{.State.Status}}' 2>/dev/null)

if [ "$CONTAINER_STATUS" = "running" ]; then
    print_success "Container Informix está executando!"
else
    print_error "Falha ao iniciar o container. Verificando logs..."
    docker logs informix_database --tail 20
    exit 1
fi

# Aguardar o banco ficar disponível
print_status "Aguardando o banco de dados ficar disponível..."
TIMEOUT=300  # 5 minutos
COUNTER=0

while [ $COUNTER -lt $TIMEOUT ]; do
    if docker exec informix_database /opt/ibm/informix/bin/onstat - >/dev/null 2>&1; then
        print_success "Banco de dados Informix está pronto!"
        break
    fi
    
    sleep 10
    COUNTER=$((COUNTER + 10))
    echo -n "."
done

if [ $COUNTER -ge $TIMEOUT ]; then
    print_error "Timeout aguardando o banco ficar disponível."
    print_error "Verificando logs do container..."
    docker logs informix_database --tail 50
    exit 1
fi

echo ""
print_success "🎉 Informix Database configurado com sucesso!"
echo ""
print_status "Informações de conexão:"
echo "  📍 Host: localhost"
echo "  🔌 Porta SQL: 9088"
echo "  🔌 Porta SQLI: 9089"
echo "  👤 Usuário: informix"
echo "  🔑 Senha: informix123"
echo "  🗄️  Database: test_db"
echo "  🖥️  Server: informix_server"
echo ""
print_status "String de conexão JDBC:"
echo "  jdbc:informix-sqli://localhost:9088/test_db:INFORMIXSERVER=informix_server"
echo ""
print_status "Comandos úteis:"
echo "  📊 Verificar status: docker exec informix_database /opt/ibm/informix/bin/onstat -"
echo "  📋 Ver logs: docker logs informix_database"
echo "  🔄 Reiniciar: docker-compose restart"
echo "  ⏹️  Parar: docker-compose down"
echo "  🗑️  Remover tudo: docker-compose down -v"
echo ""

# Testar conexão básica
print_status "Testando conexão com o banco..."
if docker exec informix_database /opt/ibm/informix/bin/dbaccess - <<< "select current from sysmaster:sysdual;" >/dev/null 2>&1; then
    print_success "✅ Conexão com banco testada com sucesso!"
else
    print_warning "⚠️  Não foi possível testar a conexão automaticamente, mas o serviço parece estar executando."
fi

print_success "Setup concluído! O Informix está pronto para uso."