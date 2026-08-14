-- ─────────────────────────────────────────────────────────
-- NEXSHIPMENT DATABASE SETUP SCRIPT
-- Copy this entire file and run it in the Supabase SQL Editor
-- ─────────────────────────────────────────────────────────

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create Shipments Table
CREATE TABLE IF NOT EXISTS public.shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_number TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL,
    status_reason TEXT,
    description TEXT,
    sender_name TEXT,
    sender_phone TEXT,
    receiver_name TEXT,
    receiver_phone TEXT,
    receiver_email TEXT,
    client_email TEXT,
    origin TEXT,
    origin_city TEXT,
    origin_country TEXT,
    origin_lat NUMERIC,
    origin_lng NUMERIC,
    destination TEXT,
    destination_city TEXT,
    destination_country TEXT,
    destination_lat NUMERIC,
    destination_lng NUMERIC,
    lat NUMERIC,
    lng NUMERIC,
    weight NUMERIC,
    package_type TEXT,
    service_type TEXT,
    transport_type TEXT,
    distance_km NUMERIC,
    eta_display TEXT,
    quantity INTEGER,
    dimensions TEXT,
    declared_value TEXT,
    shipping_cost TEXT,
    estimated_delivery TEXT,
    shipped_date TEXT,
    current_stop_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Milestones Table
CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID REFERENCES public.shipments(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    location TEXT,
    location_name TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Route Stops Table
CREATE TABLE IF NOT EXISTS public.route_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id UUID REFERENCES public.shipments(id) ON DELETE CASCADE,
    stop_order INTEGER,
    location_name TEXT NOT NULL,
    lat NUMERIC,
    lng NUMERIC,
    eta TEXT
);

-- 4. Create Quote Requests Table
CREATE TABLE IF NOT EXISTS public.quote_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    destination TEXT,
    weight TEXT,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- Set up Row Level Security (RLS)
-- To allow public read/write since it's a simple dashboard application
-- ─────────────────────────────────────────────────────────

ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_requests ENABLE ROW LEVEL SECURITY;

-- Allow completely public access (since the old database likely had open RLS or no RLS)
-- NOTE: In a strictly secure production app, you'd limit these, but this matches the previous setup.
CREATE POLICY "Enable all actions for shipments" ON public.shipments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all actions for milestones" ON public.milestones FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all actions for route_stops" ON public.route_stops FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all actions for quote_requests" ON public.quote_requests FOR ALL USING (true) WITH CHECK (true);

-- Create a storage bucket for any images (optional, but good practice if needed)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('assets', 'assets', true) 
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Access" ON storage.objects FOR ALL USING (bucket_id = 'assets') WITH CHECK (bucket_id = 'assets');
