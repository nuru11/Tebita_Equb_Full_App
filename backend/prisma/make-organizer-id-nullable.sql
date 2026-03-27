-- Make Equb.organizer_id optional (for admin-created equbs without an organizer).
-- Run this if your Equb table already exists with organizer_id NOT NULL.

ALTER TABLE `Equb`
  MODIFY COLUMN `organizer_id` VARCHAR(36) NULL,
  DROP FOREIGN KEY `Equb_organizer_id_fkey`;

ALTER TABLE `Equb`
  ADD CONSTRAINT `Equb_organizer_id_fkey`
  FOREIGN KEY (`organizer_id`) REFERENCES `User` (`id`) ON DELETE SET NULL;
