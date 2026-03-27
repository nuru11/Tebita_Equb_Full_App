-- Option B: Alter existing Equb table (member_type on the group, not on membership)
-- Run this in your MySQL database (e.g. shinurzb_db_ekub) if the tables already exist.

-- 1. Add current_cycle_number and add PAUSED to status enum on Equb
ALTER TABLE `Equb`
  ADD COLUMN `current_cycle_number` INT NOT NULL DEFAULT 0 AFTER `max_members`;

ALTER TABLE `Equb`
  MODIFY COLUMN `status` ENUM('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'DRAFT';

-- 2. Add member_type to Equb (group-level: MERCHANT, EMPLOYEE, MEMBER, ORGANIZER)
ALTER TABLE `Equb`
  ADD COLUMN `member_type` ENUM('MERCHANT', 'EMPLOYEE', 'MEMBER', 'ORGANIZER') NOT NULL DEFAULT 'MEMBER' AFTER `status`;

-- If you previously added member_type to EqubMember, remove it:
-- ALTER TABLE `EqubMember` DROP COLUMN `member_type`;
