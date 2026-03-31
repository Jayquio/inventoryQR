-- Migration: Create maintenance table
-- Run this against medlab_inventory database

CREATE TABLE IF NOT EXISTS `maintenance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `instrument_name` varchar(128) NOT NULL,
  `technician` varchar(64) NOT NULL,
  `type` varchar(64) NOT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('Completed','Pending','In Progress') NOT NULL DEFAULT 'Completed',
  `performed_at` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_maintenance_instrument` (`instrument_name`),
  KEY `idx_maintenance_date` (`performed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
