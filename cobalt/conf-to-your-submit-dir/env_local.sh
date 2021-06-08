# This file must be compatible with bash(1) on the system.
# It should be alright to source this file multiple times.

# Because you can change SPARK_CONF_DIR in this file, the main
# scripts only create the directory after sourcing this file.  Since
# we need the directory to create the spark-defaults.conf file, we
# create the directory here.
[[ -d $SPARK_CONF_DIR ]] || mkdir -p "$SPARK_CONF_DIR"

# The created spark-defaults.conf file will only affect spark
# submitted under the current directory where this file resides.
# The parameters here may require tuning depending on the machine and workload.
[[ -s $SPARK_CONF_DIR/spark-defaults.conf ]] ||
	cat > "$SPARK_CONF_DIR/spark-defaults.conf" <<EOF
spark.executor.cores        10
spark.driver.memory        10g
spark.executor.memory        72g
spark.driver.extraJavaOptions        -XX:+UseG1GC
spark.executor.extraJavaOptions        -XX:+UseG1GC

spark.executor.extraClassPath	$SPARKJOB_CONFIG_DIR
spark.driver.extraClassPath   $SPARKJOB_CONFIG_DIR

spark.shuffle.manager=org.apache.spark.shuffle.daos.DaosShuffleManager
spark.shuffle.daos.pool.uuid		19e06d18-e0dc-4168-9871-9c12b97170ec
spark.shuffle.daos.container.uuid	e6960e6b-2f73-4476-bddd-bcaa8f312e26
EOF

# TODO: python 2 or 3

# On cooley, interactive spark jobs setup ipython notebook by
# defaults.  You can change it here, along with setting up your
# other python environment.
unset PYSPARK_DRIVER_PYTHON
unset PYSPARK_DRIVER_PYTHON_OPTS
