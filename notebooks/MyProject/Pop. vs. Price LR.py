# Databricks notebook source
# MAGIC %md # Population vs. Median Home Prices
# MAGIC #### *Linear Regression with Single Variable*

# COMMAND ----------

# MAGIC %md ### Load and parse the data

# COMMAND ----------

# Use the Spark CSV datasource with options specifying:
#  - First line of file is a header
#  - Automatically infer the schema of the data
data = spark.read.csv("/databricks-datasets/samples/population-vs-price/data_geo.csv", header="true", inferSchema="true")
data.cache()  # Cache data for faster reuse
data.count()

# COMMAND ----------

display(data)

# COMMAND ----------

data = data.dropna()  # drop rows with missing values
data.count()

# COMMAND ----------

from pyspark.sql.functions import col

exprs = [col(column).alias(column.replace(' ', '_')) for column in data.columns]

vdata = data.select(*exprs).selectExpr("2014_Population_estimate as population", "2015_median_sales_price as label")
display(vdata)

# COMMAND ----------

from pyspark.ml import Pipeline
from pyspark.ml.feature import VectorAssembler

stages = []
assembler = VectorAssembler(inputCols=["population"], outputCol="features")
stages += [assembler]
pipeline = Pipeline(stages=stages)
pipelineModel = pipeline.fit(vdata)
dataset = pipelineModel.transform(vdata)
# Keep relevant columns
selectedcols = ["features", "label"]
display(dataset.select(selectedcols))


# COMMAND ----------

# MAGIC %md ## Scatterplot of the data

# COMMAND ----------

import numpy as np
import matplotlib.pyplot as plt

x = dataset.rdd.map(lambda p: (p.features[0])).collect()
y = dataset.rdd.map(lambda p: (p.label)).collect()

plt.style.use('classic')
plt.rcParams['lines.linewidth'] = 0
fig, ax = plt.subplots()
ax.loglog(x,y)
plt.xlim(1.0e5, 1.0e7)
plt.ylim(5.0e1, 1.0e3)
ax.scatter(x, y, c="blue")

display(fig)

# COMMAND ----------

# MAGIC %md ## Linear Regression
# MAGIC 
# MAGIC **Goal**
# MAGIC * Predict y = 2015 Median Housing Price
# MAGIC * Using feature x = 2014 Population Estimate
# MAGIC 
# MAGIC **References**
# MAGIC * [MLlib LinearRegression user guide](http://spark.apache.org/docs/latest/ml-classification-regression.html#linear-regression)
# MAGIC * [PySpark LinearRegression API](http://spark.apache.org/docs/latest/api/python/pyspark.ml.html#pyspark.ml.regression.LinearRegression)

# COMMAND ----------

# Import LinearRegression class
from pyspark.ml.regression import LinearRegression
# Define LinearRegression algorithm
lr = LinearRegression()

# COMMAND ----------

# Fit 2 models, using different regularization parameters
modelA = lr.fit(dataset, {lr.regParam:0.0})
modelB = lr.fit(dataset, {lr.regParam:100.0})
print(">>>> ModelA intercept: %r, coefficient: %r" % (modelA.intercept, modelA.coefficients[0]))
print(">>>> ModelB intercept: %r, coefficient: %r" % (modelB.intercept, modelB.coefficients[0]))

# COMMAND ----------

# MAGIC %md ## Make predictions
# MAGIC 
# MAGIC Calling `transform()` on data adds a new column of predictions.

# COMMAND ----------

# Make predictions
predictionsA = modelA.transform(dataset)
display(predictionsA)

# COMMAND ----------

predictionsB = modelB.transform(dataset)
display(predictionsB)

# COMMAND ----------

# MAGIC %md ## Evaluate the Model
# MAGIC #### Predicted vs. True label

# COMMAND ----------

from pyspark.ml.evaluation import RegressionEvaluator
evaluator = RegressionEvaluator(metricName="rmse")
RMSE = evaluator.evaluate(predictionsA)
print("ModelA: Root Mean Squared Error = " + str(RMSE))

# COMMAND ----------

predictionsB = modelB.transform(dataset)
RMSE = evaluator.evaluate(predictionsB)
print("ModelB: Root Mean Squared Error = " + str(RMSE))

# COMMAND ----------

# MAGIC %md ## Plot residuals versus fitted values

# COMMAND ----------

display(modelA,dataset)

# COMMAND ----------

# MAGIC %md # Linear Regression Plots

# COMMAND ----------

import numpy as np
from pandas import *

pop = dataset.rdd.map(lambda p: (p.features[0])).collect()
price = dataset.rdd.map(lambda p: (p.label)).collect()
predA = predictionsA.select("prediction").rdd.map(lambda r: r[0]).collect()
predB = predictionsB.select("prediction").rdd.map(lambda r: r[0]).collect()

pydf = DataFrame({'pop':pop,'price':price,'predA':predA, 'predB':predB})

# COMMAND ----------

# MAGIC %md ## View the pandas DataFrame (pydf)

# COMMAND ----------

pydf

# COMMAND ----------

# MAGIC %md ## Display the scatterplot and the two regression models

# COMMAND ----------

fig, ax = plt.subplots()
ax.loglog(x,y)
ax.scatter(x, y)
plt.xlim(1.0e5, 1.0e7)
plt.ylim(5.0e1, 1.0e3)
ax.plot(pop, predA, '.r-')
ax.plot(pop, predB, '.g-')
display(fig)