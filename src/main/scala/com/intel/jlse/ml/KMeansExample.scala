package com.intel.jlse.ml

import org.apache.spark.ml.clustering.KMeans
import org.apache.spark.ml.evaluation.ClusteringEvaluator
import org.apache.spark.sql.SparkSession

import java.net.URI

/**
 * An example demonstrating k-means clustering.
 * Run with
 * {{{
 * bin/run-example ml.KMeansExample
 * }}}
 */
object KMeansExample {
  val defaultUri = "daos:///jlse/kmeans/kmeans.csv"
  val defaultFormat = "csv";
  val helpMsg = "need below parameters:\n" +
    s"data URI(default: $defaultUri)\n" +
    s"data format (csv, json, orc, parquet or other Spark supported formats, like libsvm), (default: $defaultFormat)\n" +
    "number of clusters(default: 2)\n" +
    "maximum number of iterations(default: 20)\n" +
    "initialization algorithm (random or k-means||) (default: k-means||)\n" +
    "distance measure (cosine or euclidean) (default: euclidean)\n" +
    "Note: The parameters are parsed in order. If later parameter is specified, all its previous " +
    "parameters should be specified and in order too."

  def main(args: Array[String]): Unit = {
    val spark = SparkSession
      .builder
      .appName(s"${this.getClass.getSimpleName}")
      .getOrCreate()

    // $example on$
    try {
      val uriStr = if (args.length < 1) new URI(defaultUri).toString else new URI(args(0)).toString
      val format = if (args.length < 2) defaultFormat else args(1)
      val dataset = format match {
        case "csv" => spark.read.csv(uriStr)
        case "json" => spark.read.json(uriStr)
        case "orc" => spark.read.orc(uriStr)
        case "parquet" => spark.read.parquet(uriStr)
        case _ => spark.read.format(format).load(uriStr)
      }

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
      val evaluator = new ClusteringEvaluator().setDistanceMeasure(kmeans.getDistanceMeasure)

      val silhouette = evaluator.evaluate(predictions)
      println(s"Silhouette with ${kmeans.getDistanceMeasure} = $silhouette")

      // Shows the result.
      println("Cluster Centers: ")
      model.clusterCenters.foreach(println)
      // $example off$
    } catch {
      case e: _ => throw new Exception(helpMsg, e);
    } finally {
      spark.stop()
    }
  }
}
