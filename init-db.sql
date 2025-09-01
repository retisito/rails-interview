-- Initial database setup for production
-- This file is executed when the PostgreSQL container starts for the first time

-- Create database if it doesn't exist (handled by POSTGRES_DB env var)
-- CREATE DATABASE IF NOT EXISTS rails_interview_production;

-- Grant permissions to rails user
GRANT ALL PRIVILEGES ON DATABASE rails_interview_production TO rails;

-- Create extensions if needed
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "pg_trgm";
