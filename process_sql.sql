USE project_rides;

CREATE TABLE `stations_old` (
                `id` text,
                `name` text,
                `city` text,
                `latitude` double DEFAULT NULL,
                `longitude` double DEFAULT NULL,
                `dpcapacity` text,
                `online_date` text
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOAD DATA LOCAL INFILE 'data/Divvy_Stations_2017_Q3Q4.csv'
                    INTO TABLE `stations_old`
                    FIELDS TERMINATED BY ','
                    ENCLOSED BY '"'
                    LINES TERMINATED BY '\r\n'
                    IGNORE 1 ROWS;

CREATE TABLE stations_recent AS
	SELECT
		start_station_name AS station_name,
    AVG(start_lat) AS lat,
    AVG(start_lng) AS lng
	FROM
		rides_recent
  WHERE
		start_station_name IS NOT NULL AND
    start_lat IS NOT NULL AND
    start_lng IS NOT NULL
	GROUP BY
		station_name;


DROP TABLE IF EXISTS only_old_stations;

CREATE TEMPORARY TABLE only_old_stations
	SELECT
		name AS station_name,
    latitude AS lat,
    longitude AS lng
	FROM
		stations_old
	WHERE
		name NOT IN (SELECT
  			station_name
  		FROM
  			stations_recent);
DROP TABLE IF EXISTS stations;
CREATE TABLE stations AS
	SELECT *
	FROM stations_recent;

INSERT INTO stations
	SELECT *
	FROM only_old_stations;
DROP TABLE IF EXISTS only_old_stations;

CREATE TABLE rides_old_coord AS
SELECT * FROM rides_old
	LEFT JOIN
		(
			SELECT
				station_name AS from_station_name,
				lat AS start_lat,
				lng AS start_lng
			FROM
				stations
		) AS stations_start USING (from_station_name)
	LEFT JOIN
		(
			SELECT
				station_name AS to_station_name,
				lat AS end_lat,
				lng AS end_lng
			FROM
				stations
		) AS stations_end USING	(to_station_name);

CREATE TABLE rides AS
	SELECT *
    FROM rides_recent;
INSERT INTO rides
	SELECT
		CONCAT('OLD', trip_id) AS ride_id,
        NULL AS rideable_type,
        start_time AS started_at,
		    end_time AS ended_at,
        from_station_name AS start_station_name,
        from_station_id AS start_station_id,
        to_station_name AS end_station_name,
        to_station_id AS end_station_id,
        start_lat,
        start_lng,
        end_lat,
        end_lng,
        CASE usertype
			WHEN "Subscriber" THEN "member"
            WHEN "Customer" THEN "casual"
            ELSE "casual"
		END AS member_casual
	FROM
		rides_old_coord;

SELECT group_concat(CONCAT("'", COLUMN_NAME , "'") ORDER BY ORDINAL_POSITION)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME = 'rides'; ---copy the columns' names and paste below
SELECT *
FROM (
		SELECT 'ride_id','rideable_type','started_at',
				    'ended_at','start_station_name','start_station_id',
              'end_station_name','end_station_id','start_lat',
                'start_lng','end_lat','end_lng','member_casual'
        UNION ALL
		SELECT * FROM rides
		) AS dat
WHERE
	ride_id = 'ride_id' OR ---keeps column headers
  (UNIX_TIMESTAMP(ended_at) - UNIX_TIMESTAMP(started_at)) > 0
	AND YEAR(started_at) = 2023
INTO OUTFILE '/var/lib/mysql/full_data.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
