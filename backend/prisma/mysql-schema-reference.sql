-- Equb app - Raw MySQL schema reference
-- Use this for quick reference; Prisma migrations are the source of truth when using Prisma.

-- Users
CREATE TABLE `User` (
  `id` VARCHAR(36) NOT NULL,
  `email` VARCHAR(255) NULL,
  `phone` VARCHAR(20) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(120) NOT NULL,
  `avatar_url` VARCHAR(500) NULL,
  `is_verified` BOOLEAN NOT NULL DEFAULT false,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `User_email_key` (`email`),
  UNIQUE KEY `User_phone_key` (`phone`)
);

-- Refresh tokens (auth)
CREATE TABLE `RefreshToken` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `token` VARCHAR(500) NOT NULL,
  `expires_at` DATETIME(3) NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `RefreshToken_token_key` (`token`),
  KEY `RefreshToken_user_id_idx` (`user_id`),
  CONSTRAINT `RefreshToken_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`) ON DELETE CASCADE
);

-- Admin (separate from User, role: SUPER_ADMIN, ADMIN, STAFF)
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

-- Equb groups
CREATE TABLE `Equb` (
  `id` VARCHAR(36) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `description` TEXT NULL,
  `type` ENUM('PUBLIC', 'PRIVATE', 'CORPORATE', 'PARTNERSHIP') NOT NULL DEFAULT 'PRIVATE',
  `contribution_amount` DECIMAL(12, 2) NOT NULL,
  `currency` VARCHAR(5) NOT NULL DEFAULT 'ETB',
  `frequency` ENUM('WEEKLY', 'BIWEEKLY', 'MONTHLY') NOT NULL DEFAULT 'MONTHLY',
  `payout_order_type` ENUM('FIXED_ORDER', 'LOTTERY', 'BIDDING', 'NEED_BASED') NOT NULL DEFAULT 'FIXED_ORDER',
  `max_members` INT NOT NULL,
  `current_cycle_number` INT NOT NULL DEFAULT 0,
  `invite_code` VARCHAR(20) NULL,
  `is_invite_only` BOOLEAN NOT NULL DEFAULT false,
  `status` ENUM('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'DRAFT',
  `member_type` ENUM('MERCHANT', 'EMPLOYEE', 'MEMBER', 'ORGANIZER') NOT NULL DEFAULT 'MEMBER',
  `start_date` DATE NULL,
  `end_date` DATE NULL,
  `organizer_id` VARCHAR(36) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Equb_invite_code_key` (`invite_code`),
  KEY `Equb_organizer_id_idx` (`organizer_id`),
  KEY `Equb_status_idx` (`status`),
  KEY `Equb_invite_code_idx` (`invite_code`),
  CONSTRAINT `Equb_organizer_id_fkey` FOREIGN KEY (`organizer_id`) REFERENCES `User` (`id`) ON DELETE SET NULL
);

-- Equb membership
CREATE TABLE `EqubMember` (
  `id` VARCHAR(36) NOT NULL,
  `equb_id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `role` ENUM('ORGANIZER', 'MEMBER') NOT NULL DEFAULT 'MEMBER',
  `payout_order` INT NULL,
  `status` ENUM('ACTIVE', 'LEFT', 'REMOVED') NOT NULL DEFAULT 'ACTIVE',
  `joined_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `EqubMember_equb_id_user_id_key` (`equb_id`, `user_id`),
  KEY `EqubMember_user_id_idx` (`user_id`),
  KEY `EqubMember_equb_id_idx` (`equb_id`),
  CONSTRAINT `EqubMember_equb_id_fkey` FOREIGN KEY (`equb_id`) REFERENCES `Equb` (`id`) ON DELETE CASCADE,
  CONSTRAINT `EqubMember_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`) ON DELETE CASCADE
);

-- Rounds (one cycle through all members)
CREATE TABLE `EqubRound` (
  `id` VARCHAR(36) NOT NULL,
  `equb_id` VARCHAR(36) NOT NULL,
  `round_number` INT NOT NULL,
  `due_date` DATE NOT NULL,
  `pot_amount` DECIMAL(12, 2) NULL,
  `status` ENUM('PENDING', 'COLLECTING', 'DRAWN', 'COMPLETED') NOT NULL DEFAULT 'PENDING',
  `winner_id` VARCHAR(36) NULL,
  `drawn_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `EqubRound_equb_id_round_number_key` (`equb_id`, `round_number`),
  KEY `EqubRound_equb_id_idx` (`equb_id`),
  KEY `EqubRound_winner_id_idx` (`winner_id`),
  CONSTRAINT `EqubRound_equb_id_fkey` FOREIGN KEY (`equb_id`) REFERENCES `Equb` (`id`) ON DELETE CASCADE,
  CONSTRAINT `EqubRound_winner_id_fkey` FOREIGN KEY (`winner_id`) REFERENCES `EqubMember` (`id`) ON DELETE SET NULL
);

-- Contributions (per member per round)
CREATE TABLE `Contribution` (
  `id` VARCHAR(36) NOT NULL,
  `round_id` VARCHAR(36) NOT NULL,
  `member_id` VARCHAR(36) NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `status` ENUM('PENDING', 'PAID', 'LATE', 'WAIVED') NOT NULL DEFAULT 'PENDING',
  `paid_at` DATETIME(3) NULL,
  `payment_ref` VARCHAR(100) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Contribution_round_id_member_id_key` (`round_id`, `member_id`),
  KEY `Contribution_round_id_idx` (`round_id`),
  KEY `Contribution_member_id_idx` (`member_id`),
  CONSTRAINT `Contribution_round_id_fkey` FOREIGN KEY (`round_id`) REFERENCES `EqubRound` (`id`) ON DELETE CASCADE,
  CONSTRAINT `Contribution_member_id_fkey` FOREIGN KEY (`member_id`) REFERENCES `EqubMember` (`id`) ON DELETE CASCADE
);

-- Payment audit log
CREATE TABLE `PaymentTransaction` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `equb_id` VARCHAR(36) NULL,
  `type` ENUM('CONTRIBUTION', 'PAYOUT') NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` VARCHAR(5) NOT NULL DEFAULT 'ETB',
  `status` ENUM('PENDING', 'SUCCESS', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `reference` VARCHAR(100) NULL,
  `metadata` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `PaymentTransaction_user_id_idx` (`user_id`),
  KEY `PaymentTransaction_equb_id_idx` (`equb_id`),
  KEY `PaymentTransaction_created_at_idx` (`created_at`),
  CONSTRAINT `PaymentTransaction_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `PaymentTransaction_equb_id_fkey` FOREIGN KEY (`equb_id`) REFERENCES `Equb` (`id`) ON DELETE SET NULL
);

-- Notifications
CREATE TABLE `Notification` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `title` VARCHAR(120) NOT NULL,
  `body` TEXT NULL,
  `type` VARCHAR(50) NOT NULL,
  `read_at` DATETIME(3) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `Notification_user_id_idx` (`user_id`),
  KEY `Notification_created_at_idx` (`created_at`),
  CONSTRAINT `Notification_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`) ON DELETE CASCADE
);
