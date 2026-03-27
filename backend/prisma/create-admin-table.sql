-- Admin table (separate from User)
-- Run in your MySQL database (e.g. shinurzb_db_ekub)

CREATE TABLE `Admin` (
  `id` VARCHAR(36) NOT NULL,
  `username` VARCHAR(120) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(120) NOT NULL,
  `role` ENUM('SUPER_ADMIN', 'ADMIN', 'STAFF') NOT NULL DEFAULT 'ADMIN',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Admin_username_key` (`username`),
  KEY `Admin_username_idx` (`username`),
  KEY `Admin_role_idx` (`role`)
);

-- Insert first admin: generate password hash in Node with
--   require('bcryptjs').hashSync('YourPassword', 10)
-- Then run (replace ID, username, hash, name, role as needed):
-- INSERT INTO `Admin` (`id`,`username`,`password_hash`,`full_name`,`role`,`updated_at`)
-- VALUES ('clxx000000000000000000001','admin','$2a$10$...','Super Admin','SUPER_ADMIN',NOW(3));
  