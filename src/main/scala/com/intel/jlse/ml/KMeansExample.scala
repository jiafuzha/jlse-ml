package com.intel.jlse.ml

import org.apache.spark.ml.clustering.KMeans
import org.apache.spark.ml.evaluation.ClusteringEvaluator
import org.apache.spark.sql.functions.col
import org.apache.spark.sql.SparkSession
import java.net.URI

import org.apache.spark.ml.feature.VectorAssembler

/**

 */
object KMeansExample {

  val columnsToDrop = Array("caseid", "dAge", "dAncstry1","dAncstry2","iAvail","iCitizen","iClass","dDepart","iDisabl1",
    "iDisabl2","iEnglish","iFeb55","iFertil","dHispanic","dHour89","dHours","iImmigr","dIncome1","dIncome2","dIncome3",
    "dIncome4","dIncome5","dIncome6","dIncome7","dIncome8","dIndustry","iKorean","iLang1","iLooking","iMarital",
    "iMay75880","iMeans","iMilitary","iMobility","iMobillim","dOccup","iOthrserv","iPerscare","dPOB","dPoverty",
    "dPwgt1","iRagechld","dRearning","iRelat1","iRelat2","iRemplpar","iRiders","iRlabor","iRownchld","dRpincome",
    "iRPOB","iRrelchld","iRspouse","iRvetserv","iSchool","iSept80","iSex","iSubfam1","iSubfam2","iTmpabsnt","dTravtime",
    "iVietnam","dWeek89","iWork89","iWorklwk","iWWII","iYearsch","iYearwrk","dYrsserv")

  val defaultUri = "daos:///jlse/kmeans/kmeans.csv"
  val defaultFormat = "csv"
  val helpMsg = "\nneed below parameters:\n" +
    s"1. data URI(default: $defaultUri)\n" +
    s"2. data format (csv, json, orc, parquet or other Spark supported formats, like libsvm), (default: $defaultFormat)\n" +
    "3. number of clusters(default: 2)\n" +
    "4. maximum number of iterations(default: 20)\n" +
    "5. initialization algorithm (random or k-means||) (default: k-means||)\n" +
    "6. distance measure (cosine or euclidean) (default: euclidean)\n" +
    "Note: The parameters are parsed in order. If later parameter is specified, all its previous " +
    "parameters should be specified and in order too.\n"

  def main(args: Array[String]): Unit = {
    val spark = SparkSession
      .builder
      .appName(s"${this.getClass.getSimpleName}")
      .getOrCreate()

    // $example on$
    try {
      val uriStr = if (args.length < 1) new URI(defaultUri).toString else new URI(args(0)).toString
      val format = if (args.length < 2) {
        val idx = uriStr.lastIndexOf('.')
        if (idx >= 0 && idx < uriStr.length - 1) {
          uriStr.substring(idx + 1)
        } else {
          defaultFormat
        }
      } else {
        args(1)
      }

      var dataset = format match {
        case "csv" => spark.read.option("header", true).csv(uriStr)
        case "json" => spark.read.json(uriStr)
        case "orc" => spark.read.orc(uriStr)
        case "parquet" => spark.read.parquet(uriStr)
        case _ => spark.read.format(format).load(uriStr)
      }

      dataset = dataset.select(dataset.columns.map {case c => col(c).cast("Double").as(c)}: _*)

      val assembler = new VectorAssembler().setInputCols(Array("iCitizen","iClass","dIncome1")).setOutputCol("features")
      dataset = assembler.transform(dataset)
      dataset = dataset.drop(columnsToDrop: _*)

      val kmeans = new KMeans()
      for (i <- args.indices if i > 1) {
        i match {
          case 2 => kmeans.setK(args(i).toInt)
          case 3 => kmeans.setMaxIter(args(i).toInt)
          case 4 => kmeans.setInitMode(args(i))
          case 5 => kmeans.setDistanceMeasure(args(i))
          case _ => throw new IllegalArgumentException("unexpected parameter: " + args(i))
        }
      }

      val model = kmeans.fit(dataset)

      // Make predictions
      val predictions = model.transform(dataset)

      // Evaluate clustering by computing Silhouette score
      val evaluator = new ClusteringEvaluator().setDistanceMeasure(
        if (kmeans.getDistanceMeasure != "cosine") "squaredEuclidean" else "cosine")

      val silhouette = evaluator.evaluate(predictions)
      println(s"Silhouette with ${kmeans.getDistanceMeasure} = $silhouette")

      // Shows the result.
      println("Cluster Centers: ")
      model.clusterCenters.foreach(println)
      // $example off$
    } catch {
      case e: Throwable => throw new Exception(helpMsg, e);
    } finally {
      spark.stop()
    }
  }
}
