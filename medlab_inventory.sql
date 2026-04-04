-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Apr 04, 2026 at 02:37 PM
-- Server version: 10.4.34-MariaDB-1:10.4.34+maria~ubu2004
-- PHP Version: 8.3.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `medlab_inventory`
--

-- --------------------------------------------------------

--
-- Table structure for table `instruments`
--

CREATE TABLE `instruments` (
  `type` enum('instrument','reagent') NOT NULL DEFAULT 'instrument',
  `id` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  `serial_number` varchar(64) DEFAULT NULL,
  `category` varchar(64) DEFAULT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `available` int(11) NOT NULL DEFAULT 0,
  `status` varchar(32) DEFAULT NULL,
  `condition` varchar(32) DEFAULT NULL,
  `location` varchar(64) DEFAULT NULL,
  `last_maintenance` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `instruments`
--

INSERT INTO `instruments` (`type`, `id`, `name`, `serial_number`, `category`, `quantity`, `available`, `status`, `condition`, `location`, `last_maintenance`) VALUES
('instrument', 1, 'Microscope Olympus CX23', NULL, 'Microscopy', 5, 1, 'Available', 'Good', 'Lab Room A', '2024-10-15'),
('instrument', 2, 'Centrifuge Machine', NULL, 'Sample Processing', 3, 0, 'Available', 'Good', 'Lab Room B', '2024-09-20'),
('instrument', 3, 'Hematology Analyzer', NULL, 'Hematology', 2, 1, 'Available', 'Excellent', 'Lab Room C', '2024-08-05'),
('instrument', 4, 'Clinical Chemistry Analyzer', NULL, 'Chemistry', 2, 1, 'In Use', 'Good', 'Lab Room C', '2024-07-18'),
('instrument', 5, 'Autoclave Sterilizer', NULL, 'Sterilization', 1, 1, 'Available', 'Good', 'Sterilization Room', '2024-06-10'),
('instrument', 6, 'microscope', NULL, 'yes', 10, 7, 'good', 'good', 'secret', '0000-00-00');

--
-- Triggers `instruments`
--
DELIMITER $$
CREATE TRIGGER `instruments_available_check` BEFORE UPDATE ON `instruments` FOR EACH ROW BEGIN
  IF NEW.available < 0 THEN SET NEW.available = 0; END IF;
  IF NEW.available > NEW.quantity THEN SET NEW.available = NEW.quantity; END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_instruments_ad` AFTER DELETE ON `instruments` FOR EACH ROW BEGIN
  DELETE FROM instrument_qr WHERE instrument_name = OLD.name;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_instruments_ai` AFTER INSERT ON `instruments` FOR EACH ROW BEGIN
  INSERT INTO instrument_qr (instrument_name, type, payload)
  VALUES
    (NEW.name, 'borrow',  CONCAT('QR|type=borrow;name=',  NEW.name)),
    (NEW.name, 'receive', CONCAT('QR|type=receive;name=', NEW.name)),
    (NEW.name, 'return',  CONCAT('QR|type=return;name=',  NEW.name))
  ON DUPLICATE KEY UPDATE payload = VALUES(payload);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_instruments_au` AFTER UPDATE ON `instruments` FOR EACH ROW BEGIN
  IF NEW.name <> OLD.name THEN
    UPDATE instrument_qr
    SET instrument_name = NEW.name,
        payload = REPLACE(payload, CONCAT('name=', OLD.name), CONCAT('name=', NEW.name))
    WHERE instrument_name = OLD.name;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `instrument_qr`
--

CREATE TABLE `instrument_qr` (
  `id` int(11) NOT NULL,
  `instrument_name` varchar(255) NOT NULL,
  `type` enum('borrow','receive','return') NOT NULL,
  `payload` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `instrument_qr`
--

INSERT INTO `instrument_qr` (`id`, `instrument_name`, `type`, `payload`, `created_at`) VALUES
(1, 'Autoclave Sterilizer', 'borrow', 'QR|type=borrow;name=Autoclave Sterilizer', '2026-03-06 05:53:35'),
(2, 'Centrifuge Machine', 'borrow', 'QR|type=borrow;name=Centrifuge Machine', '2026-03-06 05:53:35'),
(3, 'Clinical Chemistry Analyzer', 'borrow', 'QR|type=borrow;name=Clinical Chemistry Analyzer', '2026-03-06 05:53:35'),
(4, 'Hematology Analyzer', 'borrow', 'QR|type=borrow;name=Hematology Analyzer', '2026-03-06 05:53:35'),
(5, 'Microscope Olympus CX23', 'borrow', 'QR|type=borrow;name=Microscope Olympus CX23', '2026-03-06 05:53:35'),
(8, 'Autoclave Sterilizer', 'receive', 'QR|type=receive;name=Autoclave Sterilizer', '2026-03-06 05:53:35'),
(9, 'Centrifuge Machine', 'receive', 'QR|type=receive;name=Centrifuge Machine', '2026-03-06 05:53:35'),
(10, 'Clinical Chemistry Analyzer', 'receive', 'QR|type=receive;name=Clinical Chemistry Analyzer', '2026-03-06 05:53:35'),
(11, 'Hematology Analyzer', 'receive', 'QR|type=receive;name=Hematology Analyzer', '2026-03-06 05:53:35'),
(12, 'Microscope Olympus CX23', 'receive', 'QR|type=receive;name=Microscope Olympus CX23', '2026-03-06 05:53:35'),
(15, 'Autoclave Sterilizer', 'return', 'QR|type=return;name=Autoclave Sterilizer', '2026-03-06 05:53:35'),
(16, 'Centrifuge Machine', 'return', 'QR|type=return;name=Centrifuge Machine', '2026-03-06 05:53:35'),
(17, 'Clinical Chemistry Analyzer', 'return', 'QR|type=return;name=Clinical Chemistry Analyzer', '2026-03-06 05:53:35'),
(18, 'Hematology Analyzer', 'return', 'QR|type=return;name=Hematology Analyzer', '2026-03-06 05:53:35'),
(19, 'Microscope Olympus CX23', 'return', 'QR|type=return;name=Microscope Olympus CX23', '2026-03-06 05:53:35'),
(28, 'microscope', 'borrow', 'QR|type=borrow;name=microscope', '2026-03-06 18:12:51'),
(29, 'microscope', 'receive', 'QR|type=receive;name=microscope', '2026-03-06 18:12:51'),
(30, 'microscope', 'return', 'QR|type=return;name=microscope', '2026-03-06 18:12:51');

-- --------------------------------------------------------

--
-- Table structure for table `requests`
--

CREATE TABLE `requests` (
  `id` int(11) NOT NULL,
  `student_name` varchar(128) NOT NULL,
  `instrument_name` varchar(128) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `purpose` text DEFAULT NULL,
  `course` enum('BS Pharmacy','BS Biology','BS Radiologic Technology','BS Medical Technology/Medical Laboratory Science','BS Nursing') DEFAULT NULL,
  `needed_at` datetime DEFAULT NULL,
  `status` enum('pending','approved','rejected','returned') NOT NULL DEFAULT 'pending',
  `approved_by` varchar(64) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `rejected_by` varchar(64) DEFAULT NULL,
  `rejected_at` datetime DEFAULT NULL,
  `returned_by` varchar(64) DEFAULT NULL,
  `returned_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `requests`
--

INSERT INTO `requests` (`id`, `student_name`, `instrument_name`, `quantity`, `purpose`, `course`, `needed_at`, `status`, `approved_by`, `approved_at`, `rejected_by`, `rejected_at`, `returned_by`, `returned_at`, `created_at`) VALUES
(11, 'alexa', 'Centrifuge Machine', 1, 'for lab', NULL, NULL, 'approved', 'admin', '2026-03-11 02:01:36', NULL, NULL, NULL, NULL, '2026-03-07 08:24:01'),
(12, 'teacher', 'microscope', 1, 'for project', '', '2026-03-13 02:13:00', 'approved', 'admin', '2026-03-11 02:01:42', NULL, NULL, NULL, NULL, '2026-03-10 17:13:39'),
(14, 'ryota-kun', 'microscope', 1, 'wowo', '', '2026-03-12 04:19:00', 'approved', 'admin', '2026-03-11 04:20:24', NULL, NULL, NULL, NULL, '2026-03-10 20:19:58'),
(15, 'ryota-kun', 'Microscope Olympus CX23', 1, 'yes', '', '2026-03-12 12:15:00', 'approved', 'admin', '2026-03-11 10:15:48', NULL, NULL, NULL, NULL, '2026-03-11 01:15:58'),
(16, 'student', 'Centrifuge Machine', 1, 'for project', 'BS Medical Technology/Medical Laboratory Science', '2026-03-27 15:00:00', 'approved', 'admin', '2026-03-29 12:10:33', NULL, NULL, NULL, NULL, '2026-03-26 04:20:58'),
(17, 'dmcb', 'microscope', 1, 'for project', 'BS Medical Technology/Medical Laboratory Science', '2026-03-30 00:00:00', 'approved', 'admin', '2026-03-29 13:24:31', NULL, NULL, NULL, NULL, '2026-03-27 02:17:11'),
(18, 'ryota-kun', 'Hematology Analyzer', 1, 'activity', 'BS Medical Technology/Medical Laboratory Science', '2026-04-10 12:09:00', 'approved', 'admin', '2026-03-29 10:10:51', NULL, NULL, NULL, NULL, '2026-03-29 02:09:50'),
(19, 'alexa', 'microscope', 1, 'For Activity', 'BS Medical Technology/Medical Laboratory Science', '2026-03-31 10:10:00', 'approved', 'admin', '2026-03-29 10:11:08', NULL, NULL, NULL, NULL, '2026-03-29 02:10:18'),
(20, 'alexa', 'Centrifuge Machine', 1, 'Laboratory', 'BS Pharmacy', '2026-04-01 10:14:00', 'rejected', NULL, NULL, 'admin', '2026-03-29 14:04:38', NULL, NULL, '2026-03-29 02:13:51'),
(21, 'teacher', 'Clinical Chemistry Analyzer', 1, 'yes', 'BS Biology', '2026-03-31 13:05:00', 'approved', 'admin', '2026-03-29 11:59:07', NULL, NULL, NULL, NULL, '2026-03-29 02:49:14'),
(22, 'ryota-kun', 'Centrifuge Machine', 1, 'Activity', 'BS Nursing', '2026-03-31 13:46:00', 'approved', 'admin', '2026-03-29 13:56:39', NULL, NULL, NULL, NULL, '2026-03-29 05:46:19'),
(23, 'alexa', 'Clinical Chemistry Analyzer', 1, 'For laboratory', 'BS Biology', '2026-03-31 15:30:00', 'rejected', NULL, NULL, 'admin', '2026-03-29 14:03:24', NULL, NULL, '2026-03-29 06:02:33'),
(24, 'alexa', 'microscope', 1, 'For laboratory activity', 'BS Medical Technology/Medical Laboratory Science', '2026-03-30 15:30:00', 'approved', 'admin', '2026-03-29 14:07:39', NULL, NULL, NULL, NULL, '2026-03-29 06:07:10'),
(25, 'dmcb', 'Centrifuge Machine', 1, 'yes', 'BS Medical Technology/Medical Laboratory Science', '2026-03-31 05:30:00', 'approved', 'admin', '2026-03-30 03:33:27', NULL, NULL, NULL, NULL, '2026-03-29 19:30:49');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL,
  `instrument_name` varchar(128) NOT NULL,
  `type` enum('receive','return','borrow') NOT NULL,
  `processed_by` varchar(64) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `instrument_name`, `type`, `processed_by`, `created_at`) VALUES
(1, 'Microscope Olympus CX23', 'receive', 'admin', '2026-02-24 10:03:04'),
(2, 'Microscope Olympus CX23', 'receive', 'admin', '2026-02-24 10:04:45'),
(3, 'Autoclave Sterilizer', 'receive', 'teacher', '2026-03-06 15:50:38'),
(4, 'Autoclave Sterilizer', 'return', 'admin', '2026-03-29 14:33:53'),
(5, 'Centrifuge Machine', 'return', 'admin', '2026-03-29 14:33:57'),
(6, 'Clinical Chemistry Analyzer', 'return', 'admin', '2026-03-29 14:34:00');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(64) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','teacher','student') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`) VALUES
(1, 'admin', 'admin', 'admin'),
(2, 'teacher', 'teacher', 'teacher'),
(3, 'student', 'student', 'student'),
(4, 'dmcb', 'dmcb', 'student'),
(5, 'ryota-kun', 'arigato', 'teacher'),
(6, 'alexa', 'alexa123', 'student'),
(10, 'jq', '123', 'teacher');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `instruments`
--
ALTER TABLE `instruments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `instrument_qr`
--
ALTER TABLE `instrument_qr`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_instrument_type` (`instrument_name`,`type`);

--
-- Indexes for table `requests`
--
ALTER TABLE `requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_requests_status` (`status`),
  ADD KEY `idx_requests_student` (`student_name`),
  ADD KEY `idx_requests_instrument` (`instrument_name`),
  ADD KEY `idx_requests_returned_at` (`returned_at`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tx_instrument` (`instrument_name`),
  ADD KEY `idx_tx_type_created` (`type`,`created_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `instruments`
--
ALTER TABLE `instruments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `instrument_qr`
--
ALTER TABLE `instrument_qr`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `requests`
--
ALTER TABLE `requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
