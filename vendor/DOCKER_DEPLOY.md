# 🐳 Docker Deployment Guide - TodoList App

Este proyecto incluye configuración completa de Docker para desarrollo y producción.

## 📋 Archivos de Configuración

- `Dockerfile` - Imagen optimizada para producción
- `Dockerfile.dev` - Imagen para desarrollo
- `docker-compose.yml` - Orquestación para producción
- `docker-compose.dev.yml` - Orquestación para desarrollo
- `nginx.conf` - Configuración del reverse proxy
- `deploy.sh` - Script automatizado de deployment
- `env.example` - Variables de entorno de ejemplo

## 🚀 Quick Start - Producción

### 1. Preparar el entorno

```bash
# Clonar el repositorio
git clone <your-repo-url>
cd rails-interview

# Copiar y configurar variables de entorno
cp env.example .env
# Editar .env con tus configuraciones reales
```

### 2. Deploy automático

```bash
# Ejecutar script de deployment
./deploy.sh production

# O paso a paso:
docker-compose up -d
```

### 3. Verificar deployment

```bash
# Verificar servicios
docker-compose ps

# Ver logs
docker-compose logs -f web

# Health check
curl http://localhost/health
```

## 🛠️ Desarrollo Local con Docker

### Opción 1: Desarrollo con Docker Compose

```bash
# Usar configuración de desarrollo
docker-compose -f docker-compose.dev.yml up -d

# Acceder al contenedor
docker-compose -f docker-compose.dev.yml exec web_dev bash

# Ejecutar migraciones
docker-compose -f docker-compose.dev.yml run --rm web_dev rails db:migrate

# Ver logs
docker-compose -f docker-compose.dev.yml logs -f web_dev
```

### Opción 2: Desarrollo híbrido (DB en Docker, App local)

```bash
# Solo base de datos en Docker
docker-compose -f docker-compose.dev.yml up -d postgres_dev redis_dev

# Configurar DATABASE_URL local
export DATABASE_URL="postgresql://rails:development_password@localhost:5433/rails_interview_development"

# Ejecutar app localmente
bundle install
rails db:create db:migrate db:seed
rails server
```

## 🏗️ Arquitectura del Deployment

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │   Rails App     │    │   PostgreSQL    │
│  (Port 80/443)  │───▶│   (Port 3000)   │───▶│   (Port 5432)   │
│  Reverse Proxy  │    │   TodoList API  │    │    Database     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │     Redis       │
                       │   (Port 6379)   │
                       │     Cache       │
                       └─────────────────┘
```

## 🔧 Comandos Útiles

### Gestión de Contenedores

```bash
# Ver estado de servicios
docker-compose ps

# Reiniciar un servicio
docker-compose restart web

# Ver logs en tiempo real
docker-compose logs -f web

# Acceder a un contenedor
docker-compose exec web bash

# Parar todos los servicios
docker-compose down

# Parar y eliminar volúmenes
docker-compose down -v
```

### Base de Datos

```bash
# Ejecutar migraciones
docker-compose run --rm web rails db:migrate

# Seed con datos de ejemplo
docker-compose run --rm web rails db:seed

# Backup de base de datos
docker-compose exec postgres pg_dump -U rails rails_interview_production > backup.sql

# Restaurar backup
docker-compose exec -T postgres psql -U rails rails_interview_production < backup.sql
```

### Debugging

```bash
# Ejecutar tests
docker-compose run --rm web bundle exec rspec

# Rails console
docker-compose run --rm web rails console

# Verificar configuración
docker-compose run --rm web rails runner "puts Rails.application.config.database_configuration"
```

## 🔐 Configuración de Seguridad

### Variables de Entorno Críticas

```bash
# Generar SECRET_KEY_BASE
docker-compose run --rm web rails secret

# Configurar en .env
SECRET_KEY_BASE=tu_clave_secreta_muy_larga_aqui
POSTGRES_PASSWORD=tu_password_seguro_aqui
```

### SSL/HTTPS (Producción)

1. Obtener certificados SSL (Let's Encrypt recomendado)
2. Colocar certificados en `./ssl/`
3. Descomentar configuración HTTPS en `nginx.conf`
4. Reiniciar nginx: `docker-compose restart nginx`

## 📊 Monitoreo

### Health Checks

```bash
# Aplicación
curl http://localhost/health

# Base de datos
docker-compose exec postgres pg_isready -U rails

# Redis
docker-compose exec redis redis-cli ping
```

### Logs

```bash
# Logs de aplicación
docker-compose logs web

# Logs de nginx
docker-compose logs nginx

# Logs de base de datos
docker-compose logs postgres
```

## 🚨 Troubleshooting

### Problemas Comunes

1. **Puerto ocupado**: Cambiar puertos en docker-compose.yml
2. **Permisos**: Verificar ownership de archivos y directorios
3. **Memoria**: Aumentar límites de Docker si es necesario
4. **SSL**: Verificar certificados y configuración de nginx

### Comandos de Diagnóstico

```bash
# Verificar recursos
docker system df

# Limpiar recursos no utilizados
docker system prune -a

# Verificar redes
docker network ls

# Verificar volúmenes
docker volume ls
```

## 🌍 Deploy en Diferentes Entornos

### Staging

```bash
cp env.example .env.staging
# Configurar variables para staging
docker-compose --env-file .env.staging up -d
```

### Producción con Docker Swarm

```bash
# Inicializar swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml todolist

# Verificar servicios
docker service ls
```

## 📝 Notas Adicionales

- **Volúmenes**: Los datos persisten en volúmenes Docker nombrados
- **Backups**: Implementar estrategia de backup regular para PostgreSQL
- **Escalabilidad**: Usar Docker Swarm o Kubernetes para múltiples instancias
- **CI/CD**: Integrar con GitHub Actions o GitLab CI para deployment automático

Para más información, consultar la documentación oficial de Docker y Docker Compose.
