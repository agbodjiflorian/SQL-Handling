# SQL-Handling
Data projects with SQL

Case Study 5#: Data Mart
===

This case study actually is based off a real life change in Australia retailers where plastic bags were no longer provided for free - as you can expect, some customers would have changed their shopping behaviour because of this change!

Analysis which is related to certain key events which can have a significant impact on sales or engagement metrics is always a part of the data analytics menu. Learning how to approach these types of problems is a super valuable lesson and hopefully these ideas can help you next time you are faced with a tough problem like this in the workplace!

Questions :
----

A: Data Cleansing Steps
----

1. Convert the week_date to a DATE format
2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
3. Add a month_number with the calendar month for each week_date value as the 3rd column
4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value: 1 ==>	"Young Adults", 2 ==> "Middle Aged", 3 or 4	==> "Retirees"
6. Add a new demographic column using the following mapping for the first letter in the 
    segment values: C ==> Couples, F ==> Families
7. Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
8. Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

B: Data Exploration
----

1. What day of the week is used for each week_date value?
2. What range of week numbers are missing from the dataset?
3. How many total transactions were there for each year in the dataset?
4. What is the total sales for each region for each month?
5. What is the total count of transactions for each platform
6. What is the percentage of sales for Retail vs Shopify for each month?
7. What is the percentage of sales by demographic for each year in the dataset?
8. Which age_band and demographic values contribute the most to Retail sales?
9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
    If not - how would you calculate it instead?

C: Before & After Analysis
----

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before.
Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? 
What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

D: Bonus Question
----

Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region, platform, age_band, demographic, customer_type