#!/bin/bash

# CivicSync Backend Setup Script
# This script sets up the development environment

set -e

echo "🚀 Setting up Sahay Backend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Start databases
echo -e "${YELLOW}📦 Starting PostgreSQL and MongoDB...${NC}"
docker-compose up -d

# Wait for databases to be ready
echo -e "${YELLOW}⏳ Waiting for databases to be ready...${NC}"
sleep 10

# Check PostgreSQL
until docker-compose exec -T postgres pg_isready -U civicsync -d civicsync; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"

# Check MongoDB
until docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" --quiet; do
    echo "Waiting for MongoDB..."
    sleep 2
done
echo -e "${GREEN}✅ MongoDB is ready${NC}"

# Install Node.js dependencies
echo -e "${YELLOW}📥 Installing Node.js dependencies...${NC}"
npm install

# Copy environment file if not exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created. Please update with your settings.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and update .env file"
echo "  2. Run: npm run start:dev"
echo "  3. Open: http://localhost:3000/api/docs"
echo ""
echo "Database connections:"
echo "  PostgreSQL: localhost:5432 (civicsync/civicsync_secret_2024)"
echo "  MongoDB: localhost:27017 (civicsync_community)"
echo ""
