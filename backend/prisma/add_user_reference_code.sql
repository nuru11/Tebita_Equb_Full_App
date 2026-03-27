-- Add reference_code column to User table (optional)
-- Run this if you are not using Prisma migrate (e.g. already have the table).

ALTER TABLE User
ADD COLUMN reference_code VARCHAR(80) NULL;

