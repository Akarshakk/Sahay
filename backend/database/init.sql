-- CivicSync PostgreSQL + PostGIS Initialization
-- This script sets up the primary database for Users, Auth, and Incidents

-- Enable PostGIS extension for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types for better type safety
CREATE TYPE user_role AS ENUM ('citizen', 'volunteer', 'authority', 'admin');
CREATE TYPE incident_status AS ENUM ('pending', 'verified', 'in_progress', 'resolved', 'closed');
CREATE TYPE incident_priority AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE incident_source AS ENUM ('direct_report', 'community_promoted', 'authority_created');

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role user_role DEFAULT 'citizen',
    avatar_url VARCHAR(500),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    verification_count INTEGER DEFAULT 0,
    reputation_score INTEGER DEFAULT 0,
    last_known_location GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Incidents Table (High Priority / Official)
CREATE TABLE IF NOT EXISTS incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    status incident_status DEFAULT 'pending',
    priority incident_priority DEFAULT 'medium',
    source incident_source DEFAULT 'direct_report',
    
    -- Geospatial location using PostGIS
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address VARCHAR(500),
    
    -- Media attachments (URLs)
    media_urls TEXT[],
    
    -- Relationships
    reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    assigned_authority_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Community promotion tracking
    community_post_id VARCHAR(50), -- MongoDB ObjectId reference
    verification_count INTEGER DEFAULT 0,
    promoted_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Incident Updates/Timeline
CREATE TABLE IF NOT EXISTS incident_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id UUID REFERENCES incidents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    status_change incident_status,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_location ON users USING GIST(last_known_location);

CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_priority ON incidents(priority);
CREATE INDEX idx_incidents_reporter ON incidents(reporter_id);
CREATE INDEX idx_incidents_location ON incidents USING GIST(location);
CREATE INDEX idx_incidents_created_at ON incidents(created_at DESC);
CREATE INDEX idx_incidents_community_post ON incidents(community_post_id) WHERE community_post_id IS NOT NULL;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating timestamps
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incidents_updated_at
    BEFORE UPDATE ON incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user (password: admin123 - change in production!)
INSERT INTO users (email, password_hash, full_name, role, is_verified)
VALUES (
    'admin@civicsync.gov',
    '$2b$10$rQZ5MqJqJqJqJqJqJqJqJuKqKqKqKqKqKqKqKqKqKqKqKqKqKqKqK', -- bcrypt hash placeholder
    'System Administrator',
    'admin',
    TRUE
) ON CONFLICT (email) DO NOTHING;

COMMENT ON TABLE users IS 'CivicSync users with roles: citizen, volunteer, authority, admin';
COMMENT ON TABLE incidents IS 'Official high-priority incidents from direct reports or promoted community posts';
COMMENT ON COLUMN incidents.community_post_id IS 'Reference to MongoDB ObjectId if promoted from Community Pulse';
