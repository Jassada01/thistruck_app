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
-- Table structure for table `mobile_notification_sends`
--

CREATE TABLE `mobile_notification_sends` (
  `id` int(11) NOT NULL,
  `notification_id` int(11) NOT NULL COMMENT 'Foreign key to mobile_notifications.id',
  `device_id` int(11) NOT NULL COMMENT 'Foreign key to mobile_user_devices.id',
  `fcm_token` text NOT NULL COMMENT 'FCM Token ที่ใช้ส่ง',
  `send_status` enum('pending','sent','failed','delivered') NOT NULL DEFAULT 'pending' COMMENT 'สถานะการส่ง',
  `send_result` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'ผลการส่งจาก Firebase' CHECK (json_valid(`send_result`)),
  `error_message` text DEFAULT NULL COMMENT 'ข้อความ error หากส่งไม่สำเร็จ',
  `retry_count` int(11) NOT NULL DEFAULT 0 COMMENT 'จำนวนครั้งที่พยายามส่งซ้ำ',
  `sent_at` datetime DEFAULT NULL COMMENT 'เวลาที่ส่งจริง',
  `delivered_at` datetime DEFAULT NULL COMMENT 'เวลาที่ส่งถึง device',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='ตารางเก็บประวัติการส่งแจ้งเตือนไปยังแต่ละอุปกรณ์';

--
-- Dumping data for table `mobile_notification_sends`
--

INSERT INTO `mobile_notification_sends` (`id`, `notification_id`, `device_id`, `fcm_token`, `send_status`, `send_result`, `error_message`, `retry_count`, `sent_at`, `delivered_at`, `created_at`, `updated_at`) VALUES
(1, 1, 33, 'fw139E-rkUm5kYvrIYMdVl:APA91bGwcSsjZ2MUfkxsMGxV9Wo6UktNaxPxsg7sTB0-Pns_lt5bFqmwENkhG4x2OtapiB4QRMvVmITlIVLSajlw_AVdvsXiI1PUt_0Db_dx8B1tPvVIRR4', 'delivered', '{\"success\": true, \"message_id\": \"0:1722632400000%31bd1c9631bd1c96\", \"canonical_ids\": 0, \"failure\": 0}', NULL, 0, '2025-08-02 16:01:00', '2025-08-02 16:01:15', '2025-08-02 16:00:30', '2025-08-02 16:01:15'),
(2, 1, 34, 'cXXJG2Adwkp4u7PAM_yzt9:APA91bFlk9a9fUakcz7Z045suTESFv8X5bIVrUW3OobwaHvNx5yXMAgCSNh-TEUBW5tmbTJ4cDEKlzPOsztEOslEFva5XULZq2GCVhvd_XvsNq8JOhd2Er8', 'sent', '{\"success\": true, \"message_id\": \"0:1722632401000%31bd1c9631bd1c97\"}', NULL, 0, '2025-08-02 16:01:00', NULL, '2025-08-02 16:00:30', '2025-08-02 16:01:00'),
(3, 1, 35, 'eIH2cMTBShyXLjomzrFOc_:APA91bFjT4AG4EnI9jWLDvayL6RupoD_FcdshskozUgAWqZcx8drP7yCcc2YwAdSZfa3bBays-m7K8AITmTHSGUCfjnpGNlPNLT-8CETaB6vD8ROCgzKePc', 'failed', NULL, 'Invalid FCM token', 2, NULL, NULL, '2025-08-02 16:00:30', '2025-08-02 16:05:00'),
(4, 2, 33, 'fw139E-rkUm5kYvrIYMdVl:APA91bGwcSsjZ2MUfkxsMGxV9Wo6UktNaxPxsg7sTB0-Pns_lt5bFqmwENkhG4x2OtapiB4QRMvVmITlIVLSajlw_AVdvsXiI1PUt_0Db_dx8B1tPvVIRR4', 'delivered', '{\"success\": true, \"message_id\": \"0:1722636000000%31bd1c9631bd1c98\", \"canonical_ids\": 0, \"failure\": 0}', NULL, 0, '2025-08-02 17:01:00', '2025-08-02 17:01:10', '2025-08-02 17:00:30', '2025-08-02 17:01:10'),
(5, 2, 34, 'cXXJG2Adwkp4u7PAM_yzt9:APA91bFlk9a9fUakcz7Z045suTESFv8X5bIVrUW3OobwaHvNx5yXMAgCSNh-TEUBW5tmbTJ4cDEKlzPOsztEOslEFva5XULZq2GCVhvd_XvsNq8JOhd2Er8', 'delivered', '{\"success\": true, \"message_id\": \"0:1722636001000%31bd1c9631bd1c99\", \"canonical_ids\": 0, \"failure\": 0}', NULL, 0, '2025-08-02 17:01:00', '2025-08-02 17:01:20', '2025-08-02 17:00:30', '2025-08-02 17:01:20'),
(6, 3, 1, 'dummy_fcm_token_for_user_1_device_1', 'pending', NULL, NULL, 0, NULL, NULL, '2025-08-02 18:00:30', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `mobile_notification_sends`
--
ALTER TABLE `mobile_notification_sends`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_notification_device` (`notification_id`,`device_id`),
  ADD KEY `idx_notification_id` (`notification_id`),
  ADD KEY `idx_device_id` (`device_id`),
  ADD KEY `idx_send_status` (`send_status`),
  ADD KEY `idx_sent_at` (`sent_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `mobile_notification_sends`
--
ALTER TABLE `mobile_notification_sends`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `mobile_notification_sends`
--
ALTER TABLE `mobile_notification_sends`
  ADD CONSTRAINT `fk_notification_sends_notification` FOREIGN KEY (`notification_id`) REFERENCES `mobile_notifications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_notification_sends_device` FOREIGN KEY (`device_id`) REFERENCES `mobile_user_devices` (`id`) ON DELETE CASCADE;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;