# set components path
export APPS_DIR=/soft/storage/daos/spark
export DAOS_ROOT=/home/kalfizah/daos-2tb2/install
# HOME directories
# SPARK
export SPARK_HOME=$APPS_DIR/spark-3.1.1-bin-hadoop2.7
# HADOOP
export HADOOP_HOME=$APPS_DIR/hadoop-2.7.6
# JAVA
export JAVA_HOME=$APPS_DIR/java-8

# SPARK worker resources
export SPARK_WORKER_CORES=32
export SPARK_WORKER_MEMORY=160G

[[ -z ${SPARKJOB_OUTPUT_DIR+X} ]] && declare SPARKJOB_OUTPUT_DIR="$(pwd)"
[[ -z ${SPARKJOB_CONFIG_DIR+X} ]] && declare SPARKJOB_CONFIG_DIR="$(pwd)"

export CLASSPATH=$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/rt.jar

export HADOOP_LIB_DIR=${HADOOP_HOME}/lib
export HADOOP_LIBEXEC_DIR=${HADOOP_HOME}/libexec
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export HADOOP_CLASSPATH=${HADOOP_CLASSPATH+}:$SPARKJOB_CONFIG_DIR
export HADOOP_YARN_USER=$USER
export HADOOP_USER_NAME=$USER
# PATH
export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH
# MORE SPARK DIR
export SPARK_WORKER_DIR="/tmp/workers-${USER}"
[[ -z ${SPARKJOB_WORKING_DIR+X} ]] && declare SPARKJOB_WORKING_DIR="$(pwd)"
export SPARK_CONF_DIR="$SPARKJOB_WORKING_DIR/conf"
export SPARK_LOG_DIR="$SPARKJOB_WORKING_DIR/logs"

# TODO: python 2 or 3



# LOAD DAOS and STARTUP DAOS AGENT
export PATH=$DAOS_ROOT/bin:${PATH}
export CPATH=$DAOS_ROOT/include:${CPATH:-}
export LIBRARY_PATH=$DAOS_ROOT/lib64:$DAOS_ROOT/lib:${LIBRARY_PATH:-}
export LD_LIBRARY_PATH=$DAOS_ROOT/lib64:$DAOS_ROOT/lib:${LD_LIBRARY_PATH:-}
export DAOS_LIBRARY_PATH=$LD_LIBRARY_PATH

export CRT_CREDIT_EP_CTX=0

#
# Presque specific settings
#
export CRT_PHY_ADDR_STR="ofi+verbs;ofi_rxm"
export OFI_DOMAIN="mlx5_0"
export OFI_INTERFACE="enp24s0.1029"
export FI_MR_CACHE_MAX_COUNT="0"
export D_LOG_FILE="/tmp/${USER}-daos.log"
export DAOS_AGENT_LOG="/tmp/${USER}-daos-agent.log"
export DAOS_AGENT_CONF="$SPARKJOB_CONFIG_DIR/daos_agent.yml"
export DAOS_AGENT_DIR="/tmp/${USER}-daos_agent"
export DAOS_AGENT_DRPC_DIR=$DAOS_AGENT_DIR

agent_started=$(ps -ef | grep daos_agent | grep -v grep)
if [ -z "$agent_started" ]; then
		mkdir -p $DAOS_AGENT_DIR
		daos_agent -i -d  -o $DAOS_AGENT_CONF -l $DAOS_AGENT_LOG -s ${DAOS_AGENT_DIR} > $DAOS_AGENT_DIR/1.log 2>&1 &
		if (($?!=0)); then
			echo "failed to start daos_agent with config file, $DAOS_AGENT_CONF"
			exit 1
		fi
		sleep .5
		agent_started=$(ps -ef | grep daos_agent | grep -v grep)
		if [ -z "$agent_started" ]; then
			echo "failed to start daos_agent with config file, $DAOS_AGENT_CONF"
			exit 1
		fi
fi
