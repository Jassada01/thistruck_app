-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Aug 02, 2025 at 07:58 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mysystem`
--

-- --------------------------------------------------------

--
-- Table structure for table `mobile_notifications`
--

CREATE TABLE `mobile_notifications` (
  `id` int(11) NOT NULL,
  `mobile_user_id` int(11) NOT NULL COMMENT 'Foreign key to mobile_users.id',
  `title` varchar(255) NOT NULL COMMENT 'หัวข้อการแจ้งเตือน',
  `message` text NOT NULL COMMENT 'ข้อความการแจ้งเตือน',
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'ข้อมูลเพิ่มเติม JSON format' CHECK (json_valid(`data`)),
  `notification_type` varchar(50) DEFAULT 'general' COMMENT 'ประเภทการแจ้งเตือน เช่น job, alert, system',
  `priority` enum('low','normal','high','urgent') NOT NULL DEFAULT 'normal' COMMENT 'ระดับความสำคัญ',
  `status` enum('pending','processing','processed','failed') NOT NULL DEFAULT 'pending' COMMENT 'สถานะการประมวลผล: pending=รอ, processing=กำลังส่ง, processed=ส่งแล้ว, failed=ส่งไม่สำเร็จ',
  `processed_at` datetime DEFAULT NULL COMMENT 'เวลาที่ประมวลผลการส่งเสร็จ',
  `is_read` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1=อ่านแล้ว, 0=ยังไม่อ่าน (ถ้าอ่านที่ device ใดก็ตาม)',
  `read_at` datetime DEFAULT NULL COMMENT 'เวลาที่อ่านการแจ้งเตือน',
  `read_device_id` varchar(255) DEFAULT NULL COMMENT 'device_id ที่อ่านการแจ้งเตือน',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='ตารางเก็บข้อมูลการแจ้งเตือนของผู้ใช้';

--
-- Dumping data for table `mobile_notifications`
--

INSERT INTO `mobile_notifications` (`id`, `mobile_user_id`, `title`, `message`, `data`, `notification_type`, `priority`, `status`, `processed_at`, `is_read`, `read_at`, `read_device_id`, `created_at`, `updated_at`) VALUES
(1, 5, 'งานใหม่ได้รับมอบหมาย', 'คุณได้รับงานขนส่งใหม่ จาก กรุงเทพฯ ไป เชียงใหม่', '{\"type\": 12345, \"route\": \"กรุงเทพฯ - เชียงใหม่\", \"pickup_date\": \"2025-08-03\"}', 'job', 'high', 'processed', '2025-08-02 16:01:30', 0, NULL, NULL, '2025-08-02 16:00:00', '2025-08-02 16:01:30'),
(2, 5, 'แจ้งเตือนระบบ', 'ระบบจะปิดปรับปรุงในวันที่ 5 สิงหาคม 2568 เวลา 02:00-04:00 น.', '{\"maintenance_start\": \"2025-08-05 02:00:00\", \"maintenance_end\": \"2025-08-05 04:00:00\"}', 'system', 'normal', 'processed', '2025-08-02 17:01:30', 1, '2025-08-02 17:30:00', '820AEAE2-CF83-434E-9E33-7DCA0A66DF05', '2025-08-02 17:00:00', '2025-08-02 17:30:00'),
(3, 1, 'เตือนความปลอดภัย', 'โปรดตรวจสอบความพร้อมของรถก่อนออกเดินทาง', '{\"safety_checklist\": [\"เบรก\", \"ไฟหน้า\", \"ยาง\", \"น้ำมันเครื่อง\"]}', 'alert', 'urgent', 'pending', NULL, 0, NULL, NULL, '2025-08-02 18:00:00', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `mobile_notifications`
--
ALTER TABLE `mobile_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_mobile_user_id` (`mobile_user_id`),
  ADD KEY `idx_is_read` (`is_read`),
  ADD KEY `idx_notification_type` (`notification_type`),
  ADD KEY `idx_priority` (`priority`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `mobile_notifications`
--
ALTER TABLE `mobile_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `mobile_notifications`
--
ALTER TABLE `mobile_notifications`
  ADD CONSTRAINT `fk_notifications_mobile_user` FOREIGN KEY (`mobile_user_id`) REFERENCES `mobile_users` (`id`) ON DELETE CASCADE;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;