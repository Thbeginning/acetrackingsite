-- Migration: Add missing shipment fields for tracking page display
-- These columns power the 4-card info grid on the customer tracking page

ALTER TABLE shipments
  ADD COLUMN IF NOT EXISTS sender_phone      text,
  ADD COLUMN IF NOT EXISTS receiver_phone    text,
  ADD COLUMN IF NOT EXISTS receiver_email    text,
  ADD COLUMN IF NOT EXISTS shipped_date      date;
