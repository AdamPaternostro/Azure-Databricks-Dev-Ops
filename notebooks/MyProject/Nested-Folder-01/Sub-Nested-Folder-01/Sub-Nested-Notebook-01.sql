-- Databricks notebook source
-- MAGIC %md ## Population versus Price

-- COMMAND ----------

-- MAGIC %md Use `%python` magic commands in the next few cells because this is a SQL notebook.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Use the Spark CSV datasource with options specifying:
-- MAGIC #  - First line of file is a header
-- MAGIC #  - Automatically infer the schema of the data
-- MAGIC data = spark.read.csv("/databricks-datasets/samples/population-vs-price/data_geo.csv", header="true", inferSchema="true") 
-- MAGIC data.cache()  # Cache data for faster reuse
-- MAGIC data = data.dropna() # drop rows with missing values

-- COMMAND ----------

-- MAGIC %python
-- MAGIC data.take(10)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC display(data)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Register table so it is accessible via SQL Context
-- MAGIC data.createOrReplaceTempView("data_geo")

-- COMMAND ----------

-- MAGIC %md #### Hover over the state for 2015 Median Home Prices

-- COMMAND ----------

select `State Code`, `2015 median sales price` from data_geo

-- COMMAND ----------

-- MAGIC %md ## Top 10 Cities by 2015 Median Sales Price

-- COMMAND ----------

select City, `2014 Population estimate`/1000 as `2014 Population Estimate (1000s)`, `2015 median sales price` as `2015 Median Sales Price (1000s)` from data_geo order by `2015 median sales price` desc limit 10;

-- COMMAND ----------

-- MAGIC %md ## 2014 Population Estimates in Washington State

-- COMMAND ----------

select City, `2014 Population estimate` from data_geo where `State Code` = 'WA';

-- COMMAND ----------

-- MAGIC %md ## 2015 Median Sales Price Box Plot
-- MAGIC 
-- MAGIC Box plot shows means + variation of prices.

-- COMMAND ----------

select `State Code`, `2015 median sales price` from data_geo order by `2015 median sales price` desc;

-- COMMAND ----------

-- MAGIC %md ## 2015 Median Sales Price by State Histogram

-- COMMAND ----------

select `State Code`, `2015 median sales price` from data_geo order by `2015 median sales price` desc;

-- COMMAND ----------

-- MAGIC %md ## 2015 Median Sales Price by State Quantile Plot >= $ 300,000
-- MAGIC 
-- MAGIC Quantile plots help describe distributions (in this case, the distribution of sales prices across cities) and highlight aspects such as skewed distributions.

-- COMMAND ----------

select `State Code`, `2015 median sales price` from data_geo where `2015 median sales price` >= 300;

-- COMMAND ----------

-- MAGIC %md ## Cities with 2015 Median Sales Price >= $ 300,000

-- COMMAND ----------

select `City`, `State Code`, `2015 median sales price` from data_geo where `2015 median sales price` >= 300 limit 20;

-- COMMAND ----------

-- MAGIC %md ## 2015 Median Sales Price Q-Q Plot
-- MAGIC 
-- MAGIC Q-Q plots provide yet another view of distributions.  See [Wikipedia on Q-Q Plots](https://en.wikipedia.org/wiki/Q%E2%80%93Q_plot) for more background.

-- COMMAND ----------

select `State Code`, case when `2015 median sales price` >= 300 then '>=300K' when `2015 median sales price` < 300 then '< 300K' end as `Category`, `2015 median sales price` from data_geo order by `2015 median sales price` desc;