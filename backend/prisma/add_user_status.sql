-- Add status column to User table (PENDING, ACTIVE, INACTIVE)
-- Run this if you are not using Prisma migrate (e.g. already have the table).

ALTER TABLE User
ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'PENDING';

-- Optional: add constraint so only allowed values are accepted (MySQL 8.0.16+)
-- ALTER TABLE User ADD CONSTRAINT chk_user_status CHECK (status IN ('PENDING', 'ACTIVE', 'INACTIVE'));

-- Optional: backfill existing users as ACTIVE
-- UPDATE User SET status = 'ACTIVE' WHERE status = 'PENDING';
