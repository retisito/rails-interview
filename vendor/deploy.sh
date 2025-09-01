#!/bin/bash

# TodoList App - Deployment Script
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
echo "🚀 Deploying TodoList App to $ENVIRONMENT environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from example..."
    if [ -f env.example ]; then
        cp env.example .env
        print_warning "Please edit .env file with your actual configuration before continuing."
        read -p "Press enter to continue after editing .env file..."
    else
        print_error "env.example file not found. Please create .env file manually."
        exit 1
    fi
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans

# Pull latest images
print_status "Pulling latest images..."
docker-compose pull

# Build application image
print_status "Building application image..."
docker-compose build --no-cache web

# Start services
print_status "Starting services..."
docker-compose up -d postgres redis

# Wait for database to be ready
print_status "Waiting for database to be ready..."
sleep 10

# Run database migrations
print_status "Running database migrations..."
docker-compose run --rm web bundle exec rails db:create db:migrate

# Seed database if needed
if [ "$ENVIRONMENT" = "development" ] || [ "$ENVIRONMENT" = "staging" ]; then
    print_status "Seeding database with sample data..."
    docker-compose run --rm web bundle exec rails db:seed
fi

# Start web application
print_status "Starting web application..."
docker-compose up -d web

# Start nginx
print_status "Starting nginx reverse proxy..."
docker-compose up -d nginx

# Wait for application to be ready
print_status "Waiting for application to be ready..."
sleep 15

# Health check
print_status "Performing health check..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_status "Health check passed!"
else
    print_error "Health check failed. Check application logs:"
    docker-compose logs web
    exit 1
fi

# Show status
print_status "Deployment completed successfully!"
echo ""
echo "🌐 Application URLs:"
echo "   Web Interface: http://localhost"
echo "   API Endpoint:  http://localhost/api/todolists"
echo "   Health Check:  http://localhost/health"
echo ""
echo "📊 Container Status:"
docker-compose ps
echo ""
echo "📝 To view logs: docker-compose logs -f [service_name]"
echo "🛑 To stop: docker-compose down"
echo "🔄 To restart: docker-compose restart [service_name]"
