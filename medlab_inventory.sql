-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Apr 21, 2026 at 03:16 AM
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
('instrument', 1, 'Microscope Olympus CX23', NULL, 'Microscopy', 5, 5, 'Available', 'Good', 'Lab Room A', '2024-10-15'),
('instrument', 2, 'Centrifuge Machine', NULL, 'Sample Processing', 3, 3, 'Available', 'Good', 'Lab Room B', '2024-09-20'),
('instrument', 3, 'Hematology Analyzer', NULL, 'Hematology', 2, 2, 'Available', 'Excellent', 'Lab Room C', '2024-08-05'),
('instrument', 4, 'Clinical Chemistry Analyzer', NULL, 'Chemistry', 2, 2, 'Available', 'Good', 'Lab Room C', '2024-07-18'),
('instrument', 5, 'Autoclave Sterilizer', NULL, 'Sterilization', 1, 1, 'Available', 'Good', 'Sterilization Room', '2024-06-10'),
('instrument', 7, 'Incubators', 'INC-94HS2L', 'Heating', 20, 20, 'Available', 'New', 'Front Desk', NULL),
('instrument', 8, 'Purple Top Tube', 'PUR-C4OCNB', 'Biology', 1, 1, 'Available', 'Good', 'Central Lab', NULL),
('instrument', 9, 'Testtube', 'TES-RO03HM', 'Glassware', 1, 1, 'Available', 'Good', 'Central Lab', NULL),
('instrument', 10, 'Red Top Tube', 'RED-X5T7H4', 'Biology', 1, 1, 'Available', 'Good', 'Central Lab', NULL),
('instrument', 11, 'Test Tube Rack', 'TES-YS9RCQ', 'Glassware', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 12, 'Water Bath', 'WAT-2E29M6', 'Heating', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 13, 'Pipette', 'PIP-5DQBT5', 'Measuring', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 14, 'Glass Slide', 'GLA-7G72CS', 'Microscopy', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 15, 'Syringes', 'SYR-JZRGXN', '', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 16, 'Blood Container', 'BLO-CUZO3R', '', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 17, 'Platelet Counter', 'PLA-E991I6', '', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 18, 'Gloves', 'GLO-1KP2UN', '', 1, 1, 'Available', '', 'Central Lab', NULL),
('instrument', 19, 'Alcohol', 'ALC-32F4EM', 'Chemicals', 1, 1, 'Available', '', 'Central Lab', NULL),
-- Glasswares from Sheet 8
('instrument', 20, 'Alcohol Lamp', 'LAG001', 'Glasswares', 19, 19, 'Available', 'New', 'Central Lab', NULL),
('instrument', 21, 'Aspirator Bulb', 'LAG002', 'Glasswares', 35, 35, 'Available', 'New', 'Central Lab', NULL),
('instrument', 22, 'Beaker, Glass 250ML', 'LAG013', 'Glasswares', 44, 44, 'Available', 'New', 'Central Lab', NULL),
('instrument', 23, 'Erlenmeyer Flask 250ML', 'LAG033', 'Glasswares', 44, 44, 'Available', 'New', 'Central Lab', NULL),
('instrument', 24, 'Graduated Cylinder 10ML', 'LAG056', 'Glasswares', 28, 28, 'Available', 'New', 'Central Lab', NULL),
('instrument', 25, 'Petri Dish, Glass', 'LAG082', 'Glasswares', 142, 142, 'Available', 'New', 'Central Lab', NULL),
('instrument', 26, 'Test Tube 3ML', 'LAG109', 'Glasswares', 230, 230, 'Available', 'New', 'Central Lab', NULL),
('instrument', 27, 'Test Tube 8ML', 'LAG111', 'Glasswares', 206, 206, 'Available', 'New', 'Central Lab', NULL),
-- Chemicals from Sheet 7
('reagent', 28, '1-Naphthol, A.R. 500G', '0000215300', 'Chemicals', 1, 1, 'Available', 'New', 'Central Lab', NULL),
('reagent', 29, '2-Propanol 2.5L', 'BATCH 21794306', 'Chemicals', 1, 1, 'Available', 'New', 'Central Lab', NULL),
('reagent', 30, 'Acetamide 500G', NULL, 'Chemicals', 1, 1, 'Available', 'New', 'Central Lab', NULL),
('reagent', 31, 'Activated Glutaraldehyde Solution 1L', '66J3', 'Chemicals', 2, 2, 'Available', 'New', 'Central Lab', NULL),
-- Machines from Sheet 9
('instrument', 32, 'Analgesiometer', 'LEM001', 'Machines', 2, 2, 'Available', 'New', 'Central Lab', NULL),
('instrument', 33, 'Vertical Autoclave 50L', 'LEM002', 'Machines', 8, 8, 'Available', 'New', 'Central Lab', NULL),
('instrument', 34, 'Analytical Balance', 'LEM008', 'Machines', 2, 2, 'Available', 'New', 'Central Lab', NULL),
('instrument', 35, 'Centrifuge, 12 Placer', 'LEM072', 'Machines', 3, 3, 'Available', 'New', 'Central Lab', NULL),
-- Additional items from CSVs
('instrument', 36, 'Buchner Funnel 100ML', 'LAG003', 'Glasswares', 5, 5, 'Available', 'New', 'Central Lab', NULL),
('instrument', 37, 'Burette, Acid 25ML', 'LAG004', 'Glasswares', 1, 1, 'Available', 'New', 'Central Lab', NULL),
('instrument', 38, 'Evaporating Dish 50ML', 'LAG036', 'Glasswares', 12, 12, 'Available', 'New', 'Central Lab', NULL),
('reagent', 39, 'Acetone', '1.903285997E9', 'Chemicals', 1, 1, 'Available', 'New', 'Central Lab', NULL),
('reagent', 40, 'Acid Alcohol 500ML', NULL, 'Chemicals', 1, 1, 'Available', 'New', 'Central Lab', NULL),
('instrument', 41, 'Biosafety Cabinet, Class III', 'LEM013', 'Machines', 11, 11, 'Available', 'New', 'Central Lab', NULL),
('instrument', 42, 'Blood Cell Counter', NULL, 'Machines', 2, 2, 'Available', 'New', 'Central Lab', NULL);


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
(30, 'microscope', 'return', 'QR|type=return;name=microscope', '2026-03-06 18:12:51'),
(32, 'Incubators', 'borrow', 'QR|type=borrow;name=Incubators', '2026-04-09 12:32:10'),
(33, 'Incubators', 'receive', 'QR|type=receive;name=Incubators', '2026-04-09 12:32:10'),
(34, 'Incubators', 'return', 'QR|type=return;name=Incubators', '2026-04-09 12:32:10'),
(36, 'Purple Top Tube', 'borrow', 'QR|type=borrow;name=Purple Top Tube', '2026-04-17 03:10:12'),
(37, 'Purple Top Tube', 'receive', 'QR|type=receive;name=Purple Top Tube', '2026-04-17 03:10:12'),
(38, 'Purple Top Tube', 'return', 'QR|type=return;name=Purple Top Tube', '2026-04-17 03:10:12'),
(40, 'Testtube', 'borrow', 'QR|type=borrow;name=Testtube', '2026-04-17 03:11:02'),
(41, 'Testtube', 'receive', 'QR|type=receive;name=Testtube', '2026-04-17 03:11:02'),
(42, 'Testtube', 'return', 'QR|type=return;name=Testtube', '2026-04-17 03:11:02'),
(44, 'Red Top Tube', 'borrow', 'QR|type=borrow;name=Red Top Tube', '2026-04-17 03:11:41'),
(45, 'Red Top Tube', 'receive', 'QR|type=receive;name=Red Top Tube', '2026-04-17 03:11:41'),
(46, 'Red Top Tube', 'return', 'QR|type=return;name=Red Top Tube', '2026-04-17 03:11:41'),
(48, 'Test Tube Rack', 'borrow', 'QR|type=borrow;name=Test Tube Rack', '2026-04-17 03:14:13'),
(49, 'Test Tube Rack', 'receive', 'QR|type=receive;name=Test Tube Rack', '2026-04-17 03:14:13'),
(50, 'Test Tube Rack', 'return', 'QR|type=return;name=Test Tube Rack', '2026-04-17 03:14:13'),
(52, 'Water Bath', 'borrow', 'QR|type=borrow;name=Water Bath', '2026-04-17 03:14:36'),
(53, 'Water Bath', 'receive', 'QR|type=receive;name=Water Bath', '2026-04-17 03:14:36'),
(54, 'Water Bath', 'return', 'QR|type=return;name=Water Bath', '2026-04-17 03:14:36'),
(56, 'Pipette', 'borrow', 'QR|type=borrow;name=Pipette', '2026-04-17 03:15:41'),
(57, 'Pipette', 'receive', 'QR|type=receive;name=Pipette', '2026-04-17 03:15:41'),
(58, 'Pipette', 'return', 'QR|type=return;name=Pipette', '2026-04-17 03:15:41'),
(60, 'Glass Slide', 'borrow', 'QR|type=borrow;name=Glass Slide', '2026-04-17 03:20:29'),
(61, 'Glass Slide', 'receive', 'QR|type=receive;name=Glass Slide', '2026-04-17 03:20:29'),
(62, 'Glass Slide', 'return', 'QR|type=return;name=Glass Slide', '2026-04-17 03:20:29'),
(64, 'Syringes', 'borrow', 'QR|type=borrow;name=Syringes', '2026-04-17 03:20:54'),
(65, 'Syringes', 'receive', 'QR|type=receive;name=Syringes', '2026-04-17 03:20:54'),
(66, 'Syringes', 'return', 'QR|type=return;name=Syringes', '2026-04-17 03:20:54'),
(68, 'Blood Container', 'borrow', 'QR|type=borrow;name=Blood Container', '2026-04-17 03:21:12'),
(69, 'Blood Container', 'receive', 'QR|type=receive;name=Blood Container', '2026-04-17 03:21:12'),
(70, 'Blood Container', 'return', 'QR|type=return;name=Blood Container', '2026-04-17 03:21:12'),
(72, 'Platelet Counter', 'borrow', 'QR|type=borrow;name=Platelet Counter', '2026-04-17 03:22:22'),
(73, 'Platelet Counter', 'receive', 'QR|type=receive;name=Platelet Counter', '2026-04-17 03:22:22'),
(74, 'Platelet Counter', 'return', 'QR|type=return;name=Platelet Counter', '2026-04-17 03:22:22'),
(76, 'Gloves', 'borrow', 'QR|type=borrow;name=Gloves', '2026-04-17 03:23:26'),
(77, 'Gloves', 'receive', 'QR|type=receive;name=Gloves', '2026-04-17 03:23:26'),
(78, 'Gloves', 'return', 'QR|type=return;name=Gloves', '2026-04-17 03:23:26'),
(80, 'Alcohol', 'borrow', 'QR|type=borrow;name=Alcohol', '2026-04-17 03:24:02'),
(81, 'Alcohol', 'receive', 'QR|type=receive;name=Alcohol', '2026-04-17 03:24:02'),
(82, 'Alcohol', 'return', 'QR|type=return;name=Alcohol', '2026-04-17 03:24:02');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('request','error','warning','success','info') NOT NULL DEFAULT 'info',
  `recipient` varchar(128) NOT NULL DEFAULT 'All',
  `course` varchar(128) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `priority` enum('high','medium','low') NOT NULL DEFAULT 'medium',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `title`, `message`, `type`, `recipient`, `course`, `is_read`, `priority`, `created_at`) VALUES
(1, 'New Borrow Request', 'teacher requested 5 unit(s) of Incubators. Purpose: yes [SN: INC-94HS2L]', 'request', 'Admin', 'BS Biology', 1, 'medium', '2026-04-09 18:00:20'),
(2, 'Instrument Returned', 'Instrument \'Incubators\' has been successfully returned and confirmed by admin on 2026-04-18 07:04:40.', 'success', 'Student', NULL, 1, 'medium', '2026-04-17 23:04:40'),
(3, 'New Borrow Request', 'teacher requested 10 unit(s) of Incubators. Purpose: project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-17 23:13:36'),
(4, 'New Borrow Request', 'student requested 2 unit(s) of Incubators. Purpose: project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-18 18:19:33'),
(5, 'Request Approved', 'Your request for Incubators has been approved.', 'success', 'Student', NULL, 1, 'medium', '2026-04-18 18:20:07'),
(6, 'New Borrow Request', 'teacher requested 5 unit(s) of Incubators. Purpose: project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-19 04:46:19'),
(7, 'Request Approved', 'Your request for Incubators has been approved.', 'success', 'Teacher', NULL, 1, 'medium', '2026-04-19 04:47:05'),
(8, 'Instrument Returned', 'Instrument \'microscope\' has been successfully returned and confirmed by admin on 2026-04-19 13:01:35.', 'success', 'Student', NULL, 1, 'medium', '2026-04-19 05:01:35'),
(9, 'New Borrow Request', 'teacher requested 9 unit(s) of Incubators. Purpose: project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-20 13:14:22'),
(10, 'New Borrow Request', 'teacher requested 1 unit(s) of Incubators. Purpose: project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-20 13:14:41'),
(11, 'Request Approved', 'Your request for 5 unit(s) of Incubators has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-20 13:15:32'),
(12, 'Request Approved', 'Your request for 5 unit(s) of Incubators has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-20 13:15:35'),
(13, 'Request Approved', 'Your request for 5 unit(s) of Incubators has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-20 13:15:37'),
(14, 'Request Rejected', 'Your request for 5 unit(s) of Incubators has been REJECTED.', 'error', 'teacher', NULL, 1, 'high', '2026-04-20 13:15:55'),
(15, 'Instrument Returned', 'Instrument \'Incubators\' has been successfully returned and confirmed by admin on 2026-04-20 21:16:20.', 'success', 'teacher', NULL, 1, 'medium', '2026-04-20 13:16:20'),
(16, 'Request Approved', 'Your request for 5 unit(s) of Incubators has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-20 13:16:25'),
(17, 'New Borrow Request', 'teacher requested 1 unit(s) of Glass Slide. Purpose: activity', 'request', 'Admin', NULL, 1, 'medium', '2026-04-20 13:21:10'),
(18, 'Request Approved', 'Your request for 1 unit(s) of Glass Slide has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-20 13:21:45'),
(19, 'New Borrow Request', 'teacher requested 1 unit(s) of Alcohol. Purpose: activity', 'request', 'Admin', NULL, 1, 'medium', '2026-04-21 00:35:26'),
(20, 'Request Approved', 'Your request for 1 unit(s) of Alcohol has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-21 00:35:44'),
(21, 'Request Approved', 'Your request for 1 unit(s) of Alcohol has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-21 00:35:46'),
(22, 'Request Approved', 'Your request for 1 unit(s) of Alcohol has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-21 00:35:57'),
(23, 'New Borrow Request', 'teacher requested 1 unit(s) of Gloves. Purpose: use for activity', 'request', 'Admin', NULL, 1, 'medium', '2026-04-21 01:35:35'),
(24, 'Request Approved', 'Your request for 1 unit(s) of Gloves has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-21 01:36:17'),
(25, 'Request Approved', 'Your request for 1 unit(s) of Gloves has been APPROVED.', 'success', 'teacher', NULL, 1, 'high', '2026-04-21 01:36:28'),
(26, 'New Borrow Request', 'student requested 1 unit(s) of Water Bath. Purpose: for project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-21 02:50:31'),
(27, 'Request Approved', 'Your request for 1 unit(s) of Water Bath has been APPROVED.', 'success', 'student', NULL, 1, 'high', '2026-04-21 02:50:51'),
(28, 'New Borrow Request', 'student requested 1 unit(s) of Microscope Olympus CX23. Purpose: project', 'request', 'Admin', NULL, 1, 'medium', '2026-04-21 03:00:24'),
(29, 'Request Approved', 'Your request for 1 unit(s) of Microscope Olympus CX23 has been APPROVED.', 'success', 'student', NULL, 1, 'high', '2026-04-21 03:00:54'),
(30, 'Instrument Returned', 'Instrument \'Microscope Olympus CX23\' has been successfully returned and confirmed by admin on 2026-04-21 11:03:09.', 'success', 'student', NULL, 0, 'medium', '2026-04-21 03:03:09');

-- --------------------------------------------------------

--
-- Table structure for table `requests`
--

CREATE TABLE `requests` (
  `id` int(11) NOT NULL,
  `batch_id` varchar(64) DEFAULT NULL,
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
  `is_override` tinyint(1) NOT NULL DEFAULT 0,
  `original_quantity` int(11) DEFAULT NULL,
  `override_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `requests`
--

INSERT INTO `requests` (`id`, `student_name`, `instrument_name`, `quantity`, `purpose`, `course`, `needed_at`, `status`, `approved_by`, `approved_at`, `rejected_by`, `rejected_at`, `returned_by`, `returned_at`, `is_override`, `original_quantity`, `override_reason`, `created_at`) VALUES
(11, 'alexa', 'Centrifuge Machine', 1, 'for lab', NULL, NULL, 'approved', 'admin', '2026-03-11 02:01:36', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-07 08:24:01'),
(12, 'teacher', 'microscope', 1, 'for project', '', '2026-03-13 02:13:00', 'returned', 'admin', '2026-03-11 02:01:42', NULL, NULL, 'admin', '2026-04-19 13:01:35', 0, NULL, NULL, '2026-03-10 17:13:39'),
(14, 'ryota-kun', 'microscope', 1, 'wowo', '', '2026-03-12 04:19:00', 'approved', 'admin', '2026-03-11 04:20:24', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-10 20:19:58'),
(15, 'ryota-kun', 'Microscope Olympus CX23', 1, 'yes', '', '2026-03-12 12:15:00', 'approved', 'admin', '2026-03-11 10:15:48', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-11 01:15:58'),
(16, 'student', 'Centrifuge Machine', 1, 'for project', 'BS Medical Technology/Medical Laboratory Science', '2026-03-27 15:00:00', 'approved', 'admin', '2026-03-29 12:10:33', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-26 04:20:58'),
(17, 'dmcb', 'microscope', 1, 'for project', 'BS Medical Technology/Medical Laboratory Science', '2026-03-30 00:00:00', 'approved', 'admin', '2026-03-29 13:24:31', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-27 02:17:11'),
(18, 'ryota-kun', 'Hematology Analyzer', 1, 'activity', 'BS Medical Technology/Medical Laboratory Science', '2026-04-10 12:09:00', 'approved', 'admin', '2026-03-29 10:10:51', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 02:09:50'),
(19, 'alexa', 'microscope', 1, 'For Activity', 'BS Medical Technology/Medical Laboratory Science', '2026-03-31 10:10:00', 'approved', 'admin', '2026-03-29 10:11:08', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 02:10:18'),
(20, 'alexa', 'Centrifuge Machine', 1, 'Laboratory', 'BS Pharmacy', '2026-04-01 10:14:00', 'rejected', NULL, NULL, 'admin', '2026-03-29 14:04:38', NULL, NULL, 0, NULL, NULL, '2026-03-29 02:13:51'),
(21, 'teacher', 'Clinical Chemistry Analyzer', 1, 'yes', 'BS Biology', '2026-03-31 13:05:00', 'approved', 'admin', '2026-03-29 11:59:07', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 02:49:14'),
(22, 'ryota-kun', 'Centrifuge Machine', 1, 'Activity', 'BS Nursing', '2026-03-31 13:46:00', 'approved', 'admin', '2026-03-29 13:56:39', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 05:46:19'),
(23, 'alexa', 'Clinical Chemistry Analyzer', 1, 'For laboratory', 'BS Biology', '2026-03-31 15:30:00', 'rejected', NULL, NULL, 'admin', '2026-03-29 14:03:24', NULL, NULL, 0, NULL, NULL, '2026-03-29 06:02:33'),
(24, 'alexa', 'microscope', 1, 'For laboratory activity', 'BS Medical Technology/Medical Laboratory Science', '2026-03-30 15:30:00', 'approved', 'admin', '2026-03-29 14:07:39', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 06:07:10'),
(25, 'dmcb', 'Centrifuge Machine', 1, 'yes', 'BS Medical Technology/Medical Laboratory Science', '2026-03-31 05:30:00', 'approved', 'admin', '2026-03-30 03:33:27', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-03-29 19:30:49'),
(26, 'dmcb', 'microscope', 2, 'Business', 'BS Biology', '2026-04-09 17:53:00', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-05 09:54:06'),
(27, 'teacher', 'Hematology Analyzer', 1, 'practice', 'BS Radiologic Technology', '2026-04-09 16:00:00', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-05 12:51:05'),
(28, 'dmcb', 'microscope', 7, 'yes', 'BS Nursing', '2026-04-14 13:25:00', 'approved', 'admin', '2026-04-09 20:47:49', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-09 09:41:24'),
(29, 'dmcb', 'Incubators', 10, 'lab [SN: INC-94HS2L]', 'BS Medical Technology/Medical Laboratory Science', '2026-04-13 20:43:00', 'returned', 'admin', '2026-04-09 20:47:46', NULL, NULL, 'admin', '2026-04-09 23:29:21', 0, NULL, NULL, '2026-04-09 12:43:15'),
(30, 'dmcb', 'Incubators', 10, 'project [SN: INC-94HS2L]', 'BS Biology', '2026-04-13 12:30:00', 'returned', 'admin', '2026-04-09 23:58:24', NULL, NULL, 'admin', '2026-04-10 00:06:22', 1, 20, '10 lang kay gamiton sa uban', '2026-04-09 15:30:11'),
(31, 'dmcb', 'Incubators', 1, 'nothing [SN: INC-94HS2L]', 'BS Biology', '2026-04-16 16:08:00', 'rejected', NULL, NULL, 'admin', '2026-04-10 00:09:37', NULL, NULL, 0, NULL, NULL, '2026-04-09 16:08:34'),
(32, 'dmcb', 'Incubators', 1, 'yes [SN: INC-94HS2L]', 'BS Radiologic Technology', '2026-04-14 00:39:00', 'approved', 'admin', '2026-04-10 01:33:00', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-09 16:39:21'),
(33, 'dmcb', 'Incubators', 1, 'oo [SN: INC-94HS2L]', 'BS Biology', '2026-04-24 04:07:00', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, '', '2026-04-09 17:07:43'),
(34, 'teacher', 'Incubators', 2, 'project [SN: INC-94HS2L]', 'BS Biology', '2026-04-16 01:33:00', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '', '2026-04-09 17:34:11'),
(35, 'teacher', 'Incubators', 5, 'yes [SN: INC-94HS2L]', 'BS Biology', '2026-04-14 02:00:00', 'returned', 'admin', '2026-04-10 19:26:21', NULL, NULL, 'admin', '2026-04-18 07:04:40', 0, NULL, NULL, '2026-04-09 18:00:20'),
(36, 'teacher', 'Incubators', 5, 'project', NULL, '2026-04-22 00:00:00', 'approved', 'admin', '2026-04-18 07:14:40', NULL, NULL, NULL, NULL, 1, 10, 'already used by the other courses', '2026-04-17 23:13:36'),
(37, 'student', 'Incubators', 2, 'project', NULL, NULL, 'approved', 'admin', '2026-04-19 02:20:07', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-18 18:19:33'),
(38, 'teacher', 'Incubators', 3, 'project', NULL, NULL, 'returned', 'admin', '2026-04-19 12:47:05', NULL, NULL, 'admin', '2026-04-20 21:16:20', 1, 5, '', '2026-04-19 04:46:19'),
(39, 'teacher', 'Incubators', 5, 'project', NULL, NULL, 'approved', 'admin', '2026-04-20 21:16:25', NULL, NULL, NULL, NULL, 1, 9, '5 nalang free', '2026-04-20 13:14:22'),
(40, 'teacher', 'Incubators', 5, 'project', NULL, NULL, 'rejected', NULL, NULL, 'admin', '2026-04-20 21:15:55', NULL, NULL, 1, 1, 'naa nay nag gamit', '2026-04-20 13:14:41'),
(41, 'teacher', 'Glass Slide', 1, 'activity', NULL, NULL, 'approved', 'admin', '2026-04-20 21:21:45', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-20 13:21:10'),
(42, 'teacher', 'Alcohol', 1, 'activity', NULL, NULL, 'approved', 'admin', '2026-04-21 08:35:57', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-21 00:35:26'),
(43, 'teacher', 'Gloves', 1, 'use for activity', NULL, NULL, 'approved', 'admin', '2026-04-21 09:36:28', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-21 01:35:35'),
(44, 'student', 'Water Bath', 1, 'for project', NULL, '2026-04-25 00:00:00', 'approved', 'admin', '2026-04-21 10:50:51', NULL, NULL, NULL, NULL, 0, NULL, NULL, '2026-04-21 02:50:31'),
(45, 'student', 'Microscope Olympus CX23', 1, 'project', NULL, NULL, 'returned', 'admin', '2026-04-21 11:00:54', NULL, NULL, 'admin', '2026-04-21 11:03:09', 0, NULL, NULL, '2026-04-21 03:00:24');

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
(6, 'Clinical Chemistry Analyzer', 'return', 'admin', '2026-03-29 14:34:00'),
(7, 'Incubators', 'return', 'admin', '2026-04-09 15:27:18'),
(8, 'Incubators', 'return', 'admin', '2026-04-09 15:29:21'),
(9, 'Incubators', 'return', 'admin', '2026-04-09 16:06:22'),
(10, 'Incubators', 'return', 'admin', '2026-04-17 23:04:40'),
(11, 'microscope', 'return', 'admin', '2026-04-19 05:01:35'),
(12, 'Incubators', 'return', 'admin', '2026-04-20 13:16:20'),
(13, 'Microscope Olympus CX23', 'return', 'admin', '2026-04-21 03:03:09');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(64) NOT NULL,
  `email` varchar(128) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','teacher','student') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `password`, `role`) VALUES
(1, 'admin', 'admin@inventory.com', 'admin', 'admin'),
(2, 'teacher', 'teacher@jmc.edu.ph', 'teacher', 'teacher'),
(3, 'student', 'student@jmc.edu.ph', 'student', 'student'),
(4, 'dmcb', 'dmcb@jmc.edu.ph', 'dmcb', 'student'),
(5, 'ryota-kun', 'ryota@jmc.edu.ph', 'arigato', 'teacher'),
(6, 'alexa', 'alexa@jmc.edu.ph', 'alexa123', 'student'),
(10, 'jq', 'jayquio.lagrama@jmc.edu.ph', '123', 'teacher'),
(11, 'dmcb-chan', 'daniella.bello@jmc.edu.ph', 'sidmcbchan', 'student');

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
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `instrument_qr`
--
ALTER TABLE `instrument_qr`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=84;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `requests`
--
ALTER TABLE `requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
