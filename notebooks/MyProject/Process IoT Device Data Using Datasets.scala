// Databricks notebook source
// MAGIC %md ## How to Process IoT Device JSON Data Using Datasets

// COMMAND ----------

// MAGIC %md Datasets in Apache Spark 2 and 3 provide high-level domain specific APIs as well as provide structure and compile-time type safety. You can read your
// MAGIC JSON data file into a DataFrame, which is essentially a generic row of JVM objects, and convert them into a type-specific collection of JVM objects. 
// MAGIC 
// MAGIC This notebook shows you how to read a JSON file, convert your semi-structured JSON data into a collection of Datasets[T], where `T` is a class, and provides an introduction to some high-level Spark Dataset APIs.

// COMMAND ----------

// MAGIC %md ####Reading JSON as a Dataset

// COMMAND ----------

// MAGIC %md Use the Scala case class `DeviceIoTData` to convert the JSON device data into a Scala object. In addition to the IP address, the file contains the geographic information for each device entry:
// MAGIC * ISO-3166-1 two and three letter codes
// MAGIC * Country Name
// MAGIC * Latitude and longitude
// MAGIC 
// MAGIC For each IP address, you can obtain these attributes from a webservice at https://ipstack.com/. With these attributes, you can create map visualizations of the data.
// MAGIC 
// MAGIC `{"device_id": 198164, "device_name": "sensor-pad-198164owomcJZ", "ip": "80.55.20.25", "cca2": "PL", "cca3": "POL", "cn": "Poland", "latitude": 53.080000, "longitude": 18.620000, "scale": "Celsius", "temp": 21, "humidity": 65, "battery_level": 8, "c02_level": 1408, "lcd": "red", "timestamp" :1458081226051 }`

// COMMAND ----------

// MAGIC %md Create a case class to represent your IoT Device Data

// COMMAND ----------

case class DeviceIoTData (battery_level: Long, c02_level: Long, cca2: String, cca3: String, cn: String, device_id: Long, device_name: String, humidity: Long, ip: String, latitude: Double, lcd: String, longitude: Double, scale:String, temp: Long, timestamp: Long)

// COMMAND ----------

//read the JSON file and create the dataset from the case class DeviceIoTData
// ds is now a collection of JVM Scala objects DeviceIoTData
val ds = spark.read.json(s"/databricks-datasets/iot/iot_devices.json").as[DeviceIoTData]

// COMMAND ----------

// MAGIC %md Count the number of devices

// COMMAND ----------

ds.count()

// COMMAND ----------

// MAGIC %md Display your Dataset

// COMMAND ----------

display(ds)

// COMMAND ----------

// MAGIC %md #### Iterating, transforming, and filtering Dataset

// COMMAND ----------

// MAGIC %md Iterate over the first 10 entries with the `foreach()` method and print them

// COMMAND ----------

ds.take(10).foreach(println(_))

// COMMAND ----------

// MAGIC %md  For all relational expressions, Apache Spark formulates an optimized logical and physical plan for execution, and optimizes the generated code. For our `DeviceIoTData`, it will use its standard encoders to optimize its binary internal representation, hence decrease the size of generated code, minimize the bytes transferred over the networks between nodes, and execute faster.
// MAGIC 
// MAGIC First filter the device dataset on `temp` and `humidity` attributes with a predicate.

// COMMAND ----------

// Issue select, map, filter, foreach operations on the datasets, just as you would for DataFrames
// it returns back a Dataset
val dsTempDS = ds.filter(d => {d.temp > 30 && d.humidity > 70})
display(dsTempDS)


// COMMAND ----------

// MAGIC %md Use Dataset APIs for filtering: `take(10)` returns an `Array[DeviceIoTData]`; using a `foreach()` method on the Array collection, print each item.

// COMMAND ----------

//filter out dataset rows that meet the temperature and humidity predicate
val dsFilter = ds.filter(d => {d.temp > 30 && d.humidity > 70}).take(10).foreach(println(_))

// COMMAND ----------

// MAGIC %md Filter out dataset using the high-level and readable method `where()`. `filter()` and `where()` are equivalent.

// COMMAND ----------

val dsTemp = ds.where($"temp" > 25).map(d => (d.temp, d.device_name, d.device_id, d.cca3))

// COMMAND ----------

display(dsTemp)

// COMMAND ----------

// MAGIC %md Both `where()` and `map()` return a Dataset

// COMMAND ----------

// MAGIC %md Use the `filter()` method that is equivalent as the `where()` method used above.

// COMMAND ----------

display(ds.filter(d=> {d.temp > 25} ).map(d => (d.temp, d.device_name, d.device_id, d.cca3)))

// COMMAND ----------

// MAGIC %md Select individual fields using the Dataset method `select()` where battery_level is greater than 6, sort in ascending order on C02_level. This high-level domain specific language API reads like a SQL query.

// COMMAND ----------

display(ds.select($"battery_level", $"c02_level", $"device_name").where($"battery_level" > 6).sort($"c02_level"))

// COMMAND ----------

display(ds.filter(d => d.temp > 25).map(d => (d.temp, d.device_name, d.device_id, d.cca3)))

// COMMAND ----------

// MAGIC %md Apply higher-level Dataset API methods such as `groupBy()` and `avg()`. In order words, take all temperatures readings > 25, along with their corresponding devices' humidity, groupBy ccca3 country code, and compute averages. Plot the resulting Dataset.

// COMMAND ----------

display(ds.map(d => (d.temp, d.humidity, d.cca3)).groupBy($"_3").avg())

// COMMAND ----------

// MAGIC %md #### Visualizing datasets

// COMMAND ----------

// MAGIC %md
// MAGIC 
// MAGIC Data without visualization without a narrative arc, to infer insights or to see a trend, is useless. By saving a Dataset as a temporary table, you can issue complex SQL queries against it and visualize the results, using notebook's myriad plotting options.

// COMMAND ----------

dsTempDS.createOrReplaceTempView("iot_device_data")

// COMMAND ----------

// MAGIC %sql 
// MAGIC select * from iot_device_data

// COMMAND ----------

// MAGIC %md Count all devices for a particular country and map them.

// COMMAND ----------

// MAGIC %sql select cca3, count(device_id) as number, avg(humidity), avg(temp) from iot_device_data group by cca3 order by number desc limit 20

// COMMAND ----------

// MAGIC %md Find the distribution for devices in the country where C02 is high and visualize the results as a pie chart.

// COMMAND ----------

// MAGIC %sql select cca3, c02_level from iot_device_data where c02_level > 1400 order by c02_level desc

// COMMAND ----------

// MAGIC %md Find all devices in countries whose batteries need replacements.

// COMMAND ----------

// MAGIC %sql select cca3, count(distinct device_id) as device_id from iot_device_data where battery_level == 0 group by cca3 order by device_id desc limit 100