Create Database Ola;
Use ola;

# 1. Retrieve all successful bookings:
Create View Successful_bookings AS
Select * from bookings
where Booking_Status = 'Success';

#2. Find the average ride distance for each vehicle
Create View Ride_distance_for_each_vehicle AS
Select Vehicle_Type, Round(AVG(Ride_Distance), 2) AS Avg_distance
from bookings
Group by  Vehicle_Type;

#3. Get the total number of canceled rides by customers:
CREATE VIEW Total_number_of_rides_canceled_by_customers AS
SELECT COUNT(*) 
from bookings
where Booking_Status= 'Canceled by Customer';

#4. List the top 5 customers who booked the highest number of rides:
CREATE VIEW Top_5_customers AS
SELECT Customer_ID, COUNT(Booking_ID) as total_rides
from bookings
group by Customer_ID
Order by total_rides DESC
Limit 5;

#5. Get the number of rides canceled by drivers due to personal and car-related issues:
CREATE VIEW Rides_Canceled_by_Drivers_due_to_personal_and_Car_related_issues AS
Select Count(*) 
from bookings
where Canceled_Rides_by_Driver = 'Personal & Car related issue';

#6. Find the maximum and minimum driver ratings for Prime Sedan Bookings:
CREATE VIEW Max_and_Min_Driver_Rating as
SELECT Max(Driver_Ratings) as Max_Rating, Min(Driver_Ratings) as Min_Rating
from bookings
where Vehicle_Type = 'Prime Sedan';

#7. Retrieve all rides where payment was made using UPI:
CREATE VIEW Payment_Method_is_UPI AS
SELECT * 
FROM bookings
where Payment_Method = 'UPI';

#8. Find the average customer rating per vehicle type:
Create view Avg_Customer_Rating AS
SELECT Vehicle_Type, AVG(Customer_Rating) as Avg_customer_rating
from bookings
group by Vehicle_Type;

#9. Calculate the total booking value of rides completed successfully:
Create view total_successful_ride_value AS
SELECT SUM(Booking_Value) as total_successful_ride_value
from bookings
where Booking_Status= 'Success';

#10. List all incomplete rides along with the reason:
Create view Icomplete_Rides_Reason AS
Select Booking_ID, Incomplete_Rides_Reason
from bookings
where Incomplete_Rides = 'Yes';

## ADVANCED SQL QUERIES

#11. Top 3 Pickup-Drop Location Pairs by Average Fare (Only Successful Rides):
SELECT pickup_location, drop_location, ROUND(AVG(booking_value), 2) AS avg_fare
FROM bookings
WHERE booking_status = 'success'
GROUP BY pickup_location, drop_location
ORDER BY avg_fare DESC
LIMIT 3;

#12. Most Frequently Used Vehicle Type on Weekends:
SELECT vehicle_type, COUNT(*) AS ride_count
FROM bookings
WHERE WEEKDAY(STR_TO_DATE(date, '%Y-%m-%d %H:%i:%s')) IN (5, 6) -- Saturday, Sunday
GROUP BY vehicle_type
ORDER BY ride_count DESC;

#13. Weekly success-rate trend with WoW deltas

WITH weekly AS (
  SELECT
    YEARWEEK(Date, 2) AS yearweek,
    COUNT(*) AS total_rides,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) AS success_rides
  FROM bookings
  GROUP BY YEARWEEK(Date, 2)
)
SELECT    
  yearweek,
  ROUND(100.0 * success_rides / NULLIF(total_rides,0), 2) AS success_rate_pct,
  ROUND(
    (100.0 * success_rides / NULLIF(total_rides,0))
    - LAG(100.0 * success_rides / NULLIF(total_rides,0)) OVER (ORDER BY yearweek)
  , 2) AS wow_delta_pct_points
FROM weekly
ORDER BY yearweek;


#14 Weekend vs Weekday lift in success rate (absolute & relative)
WITH d AS (
  SELECT
    (DAYOFWEEK(Date) IN (1,7)) AS is_weekend,
    COUNT(*) n,
    SUM(Booking_Status='Success') s
  FROM bookings
  GROUP BY (DAYOFWEEK(Date) IN (1,7))
)
SELECT
  CASE WHEN is_weekend=1 THEN 'weekend' ELSE 'weekday' END AS day_type,
  ROUND(100.0*s/NULLIF(n,0),2) AS success_pct
FROM d;

-- And the lift in one row:
WITH d AS (
  SELECT
    (DAYOFWEEK(Date) IN (1,7)) AS is_weekend,
    COUNT(*) n,
    SUM(Booking_Status='Success') s
  FROM bookings
  GROUP BY (DAYOFWEEK(Date) IN (1,7))
)
SELECT
  ROUND( (100.0*MAX(CASE WHEN is_weekend=1 THEN s/n END)) -
         (100.0*MAX(CASE WHEN is_weekend=0 THEN s/n END)), 2) AS abs_lift_pp,
  ROUND( (MAX(CASE WHEN is_weekend=1 THEN s/n END) /
          NULLIF(MAX(CASE WHEN is_weekend=0 THEN s/n END),0) - 1)*100, 2) AS rel_lift_pct
FROM d;


# 15 Cohort: first-time customers vs repeat (conversion lift)
WITH ranked AS (
  SELECT
    Customer_ID,
    Date,
    Booking_Status,
    ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Date, Time, Booking_ID) AS rn
  FROM bookings
),
agg AS (
  SELECT
    CASE WHEN rn = 1 THEN 'first_ride' ELSE 'repeat_rides' END AS cohort,
    COUNT(*) AS total_rides,
    SUM(Booking_Status = 'Success') AS success_rides
  FROM ranked
  GROUP BY cohort
)
SELECT
  cohort,
  total_rides,
  success_rides,
  ROUND(100.0 * success_rides/NULLIF(total_rides,0), 2) AS success_rate_pct
FROM agg;













