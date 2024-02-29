-- create database
DROP DATABASE IF EXISTS	project_rides;
CREATE DATABASE project_rides;
USE project_rides;
-- the table data types and columns are extracted from mysql csv import wizard
CREATE TABLE `rides_recent` ( 
                `ride_id` text, 
                `rideable_type` text, 
                `started_at` datetime DEFAULT NULL, 
                `ended_at` datetime DEFAULT NULL, 
                `start_station_name` text, 
                `start_station_id` text, 
                `end_station_name` text, 
                `end_station_id` text, 
                `start_lat` double DEFAULT NULL, 
                `start_lng` double DEFAULT NULL, 
                `end_lat` double DEFAULT NULL, 
                `end_lng` double DEFAULT NULL, 
                `member_casual` text 
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
                
CREATE TABLE `rides_old` ( 
                `trip_id` text, 
                `start_time` datetime DEFAULT NULL, 
                `end_time` datetime DEFAULT NULL, 
                `bikeid` text, 
                `tripduration` text, 
                `from_station_id` text, 
                `from_station_name` text, 
                `to_station_id` text, 
                `to_station_name` text, 
                `usertype` text, 
                `gender` text, 
                `birthyear` int DEFAULT NULL 
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
