-- ─────────────────────────────────────────────────────────────────────────────
-- PRIMETRACKCARGO — COMPLETE DATABASE SETUP
-- Run this entire script in the Supabase SQL Editor for project: demxmeowtwgbcwhkugxv
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────
-- 1. SHIPMENTS TABLE
-- Core table: every tracked shipment lives here.
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.shipments (
    id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_number     TEXT        NOT NULL UNIQUE,
    status              TEXT        NOT NULL,
    status_reason       TEXT,
    description         TEXT,

    -- Sender info
    sender_name         TEXT,
    sender_phone        TEXT,

    -- Receiver info
    receiver_name       TEXT,
    receiver_phone      TEXT,
    receiver_email      TEXT,

    -- Email to send status notifications
    client_email        TEXT,

    -- Origin fields
    origin              TEXT,
    origin_city         TEXT,
    origin_country      TEXT,
    origin_lat          NUMERIC,
    origin_lng          NUMERIC,

    -- Destination fields
    destination         TEXT,
    destination_city    TEXT,
    destination_country TEXT,
    destination_lat     NUMERIC,
    destination_lng     NUMERIC,

    -- Current live GPS coords (updated as stops advance)
    lat                 NUMERIC,
    lng                 NUMERIC,

    -- Package details
    weight              NUMERIC,
    package_type        TEXT,
    service_type        TEXT,
    transport_type      TEXT,       -- 'plane' | 'ship' | 'bus' | 'train'
    distance_km         NUMERIC,
    eta_display         TEXT,
    quantity            INTEGER,
    dimensions          TEXT,
    declared_value      TEXT,
    shipping_cost       TEXT,

    -- Dates
    estimated_delivery  TEXT,
    shipped_date        TEXT,

    -- Route tracking
    current_stop_index  INTEGER     DEFAULT 0,

    -- Timestamps
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 2. MILESTONES TABLE
-- Timeline of events pushed by admin for the customer feed.
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.milestones (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id   UUID        REFERENCES public.shipments(id) ON DELETE CASCADE,
    message       TEXT        NOT NULL,
    location      TEXT,
    location_name TEXT,
    timestamp     TIMESTAMPTZ NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 3. ROUTE STOPS TABLE
-- Ordered waypoints for the live map route.
-- NOTE: column is 'stop_index' (integer 0-based), NOT 'stop_order'
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.route_stops (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id   UUID        REFERENCES public.shipments(id) ON DELETE CASCADE,
    stop_index    INTEGER     NOT NULL,       -- 0 = origin, last = destination
    name          TEXT        NOT NULL,
    lat           NUMERIC,
    lng           NUMERIC,
    stop_type     TEXT,                       -- 'origin' | 'waypoint' | 'destination'
    reason        TEXT,                       -- e.g. "Refuel & Transit Stop"
    eta           TEXT                        -- optional display ETA for this stop
);

-- ─────────────────────────────────────────────────────────
-- 4. QUOTE REQUESTS TABLE
-- Incoming leads from the homepage quote form.
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quote_requests (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT        NOT NULL,
    email       TEXT        NOT NULL,
    destination TEXT,
    weight      TEXT,
    message     TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 5. ROW LEVEL SECURITY
-- Enable RLS on all tables, then open public access.
-- (This site does not use auth — admin uses hardcoded credentials)
-- ─────────────────────────────────────────────────────────
ALTER TABLE public.shipments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_requests ENABLE ROW LEVEL SECURITY;

-- Drop policies if they exist (safe re-run)
DROP POLICY IF EXISTS "Enable all actions for shipments"      ON public.shipments;
DROP POLICY IF EXISTS "Enable all actions for milestones"     ON public.milestones;
DROP POLICY IF EXISTS "Enable all actions for route_stops"    ON public.route_stops;
DROP POLICY IF EXISTS "Enable all actions for quote_requests" ON public.quote_requests;

-- Create open policies
CREATE POLICY "Enable all actions for shipments"
  ON public.shipments FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all actions for milestones"
  ON public.milestones FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all actions for route_stops"
  ON public.route_stops FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all actions for quote_requests"
  ON public.quote_requests FOR ALL USING (true) WITH CHECK (true);

-- ─────────────────────────────────────────────────────────
-- 6. INDEXES for performance
-- ─────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_shipments_tracking ON public.shipments(tracking_number);
CREATE INDEX IF NOT EXISTS idx_shipments_status   ON public.shipments(status);
CREATE INDEX IF NOT EXISTS idx_milestones_shipment ON public.milestones(shipment_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_shipment ON public.route_stops(shipment_id, stop_index);

-- ─────────────────────────────────────────────────────────
-- 7. STORAGE BUCKET (optional, for future file uploads)
-- ─────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
  VALUES ('assets', 'assets', true)
  ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access"
  ON storage.objects FOR ALL
  USING (bucket_id = 'assets')
  WITH CHECK (bucket_id = 'assets');

-- ─────────────────────────────────────────────────────────
-- SETUP COMPLETE ✅
-- Tables: shipments, milestones, route_stops, quote_requests
-- All RLS policies are open (public read/write)
-- Project: demxmeowtwgbcwhkugxv.supabase.co
-- ─────────────────────────────────────────────────────────
