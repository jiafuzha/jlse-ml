#! /bin/bash
set -u

# Set the directory containing our scripts if unset.
[[ -z ${SPARKJOB_SCRIPTS_DIR+X} ]] && \
	declare SPARKJOB_SCRIPTS_DIR="$(cd $(dirname "$0")&&pwd)"

declare -r configdir="$(pwd)"
declare -r version='COBALT JLSE  v1.0.1'
declare -r usage="$version"'

Usage:
	submit-spark.sh [options] JOBFILE [arguments ...]

JOBFILE can be:
	script.py			pyspark scripts
	run-example examplename		run Spark examples, like "SparkPi"
	--class classname example.jar	run Spark job "classname" wrapped in example.jar
	shell-script.sh			when option "-s" is specified

Required options:  
	-t WALLTIME		Max run time in minutes
	-n NODES		Job node count
	-q QUEUE		Queue name

Optional options:
	-e			mark flag to end option parsing which may wrongly consume job parameters otherwise
	-A PROJECT		Allocation name
	-o OUTPUTDIR		Directory for COBALT output files (default: current dir)
	-s			Enable script mode
	-m			Master uses a separate node
	-I			Start an interactive ssh session
	-w WAITTIME		Time to wait for prompt in minutes (default: 30)
	-h			Print this help messages
Example:
	submit-spark.sh -t 60 -n 2 -q presque_debug kmeans_example.py daos:///jlse/kmeans/ukmeans.csv csv 10
	submit-spark.sh -t 30 -n 1 -q presque_debug -o output-dir run-example SparkPi
	submit-spark.sh -I -t 30 -n 2 -q presque_debug -e --class com.intel.jlse.ml.KMeansExample example/jlse-ml-1.0-SNAPSHOT.jar daos:///jlse/kmeans/ukmeans.csv csv 10
	submit-spark.sh -t 30 -n 1 -q presque_debug -s example/test_script.sh job.log
'

while getopts hmseIA:t:n:q:w:p:o: OPT; do
	case $OPT in
	A)	declare -r	allocation="$OPTARG";;
	t)	declare -r	time="$OPTARG";;
	s)	declare -ir	scriptMode=1;;
	n)	declare -r	nodes="$OPTARG";;
	q)	declare -r	queue="$OPTARG";;
	o)	declare -r	outputdir="$OPTARG";;
	m)	declare -ir	separate_master=1;;
	w)	declare -ir	waittime=$((OPTARG*60));;
	e)	break;;
	I)	declare -ir	interactive=1;;
	h)	echo "$usage"; exit 0;;
	?)	echo "$usage"; exit 1;;
	esac
done

[[ -z ${waittime+X} ]] && declare -ir waittime=$((30*60))
[[ -z ${scriptMode+X} ]] && declare -ir scriptMode=0
[[ -z ${outputdir+X} ]] && declare -r outputdir=.
[[ -z ${separate_master+X} ]] && declare -ir separate_master=0

if [[ -z ${time+X} || -z ${nodes+X} || -z ${queue+X} ]];then
	echo "$usage"
	exit 1
fi

shift $((OPTIND-1))

declare -a scripts=()

if (($#>0));then
	[[ -z ${interactive+X} ]] && declare -ir interactive=0
	scripts=( "$@" )
	echo "# Submitting job: ${scripts[@]}"
else
	[[ -z ${interactive+X} ]] && declare -ir interactive=1
	echo "Submitting an interactive job and wait for at most $waittime sec."
fi

if [[ ! -d $outputdir ]];then
	if ! mkdir "$outputdir";then
		echo "Cannot create directory: $outputdir"
		exit 1
	fi
fi

declare SPARKJOB_OUTPUT_DIR="$(cd $outputdir&&pwd)"
declare SPARKJOB_CONFIG_DIR=$configdir
declare SPARKJOB_INTERACTIVE=$interactive
declare SPARKJOB_SCRIPTMODE=$scriptMode
declare SPARKJOB_SEPARATE_MASTER=$separate_master

declare -i SPARKJOB_JOBID=0
mysubmit() {
	# Options to pass to qsub
	local -a opt=(
		--attrs 'enable_ssh=1'
		-n $nodes -t $time -q $queue
		--env "SPARKJOB_SCRIPTS_DIR=$SPARKJOB_SCRIPTS_DIR"
		--env "SPARKJOB_CONFIG_DIR=$SPARKJOB_CONFIG_DIR"
		--env "SPARKJOB_INTERACTIVE=$SPARKJOB_INTERACTIVE"
		--env "SPARKJOB_SCRIPTMODE=$SPARKJOB_SCRIPTMODE"
		--env "SPARKJOB_OUTPUT_DIR=$SPARKJOB_OUTPUT_DIR"
		--env "SPARKJOB_SEPARATE_MASTER=$SPARKJOB_SEPARATE_MASTER"
		-O "$SPARKJOB_OUTPUT_DIR/\$jobid"
		"$SPARKJOB_SCRIPTS_DIR/start-spark.sh"
	)

	if ((${#scripts[@]}>0));then
		opt+=("${scripts[@]}")
	fi
	[[ ! -z ${allocation+X} ]] && opt=(-A $allocation "${opt[@]}")

	SPARKJOB_JOBID=$(qsub "${opt[@]}")
	if ((SPARKJOB_JOBID > 0));then
		echo "# Submitted"
		echo "SPARKJOB_JOBID=$SPARKJOB_JOBID"
	else
		echo "# Submitting failed."
		exit 1
	fi
}

if ((interactive>0)); then
	cleanup(){ ((SPARKJOB_JOBID>0)) && qdel $SPARKJOB_JOBID; }
	trap cleanup 0
	mysubmit
	declare -i mywait=1 count=0
	source "$SPARKJOB_SCRIPTS_DIR/setup-common.sh"
	echo "Waiting for Spark to launch..."
	for ((count=0;count<waittime;count+=mywait));do
		[[ ! -s $SPARKJOB_WORKING_ENVS ]] || break
		sleep $mywait
	done
	if [[ -s $SPARKJOB_WORKING_ENVS ]];then
		source "$SPARKJOB_WORKING_ENVS"
		echo "# Spark is now running (SPARKJOB_JOBID=$SPARKJOB_JOBID) on:"
		column "$SPARK_CONF_DIR/slaves" | sed 's/^/# /'
		declare -p SPARK_MASTER_URI
		declare -ar sshmaster=(ssh -o ControlMaster=no -t $MASTER_HOST)
		declare -r runbash="exec bash --rcfile <(
			echo SPARKJOB_JOBID=\'$SPARKJOB_JOBID\';
			echo SPARKJOB_SCRIPTS_DIR=\'$SPARKJOB_SCRIPTS_DIR\';
			echo SPARKJOB_INTERACTIVE=\'$SPARKJOB_INTERACTIVE\';
			echo SPARKJOB_SCRIPTMODE=\'$SPARKJOB_SCRIPTMODE\';
			echo SPARKJOB_OUTPUT_DIR=\'$SPARKJOB_OUTPUT_DIR\';
			echo SPARKJOB_SEPARATE_MASTER=\'$SPARKJOB_SEPARATE_MASTER\';
			echo source ~/.bashrc;
			echo source \'$SPARKJOB_SCRIPTS_DIR/setup.sh\';
			echo cd \'\$SPARKJOB_OUTPUT_DIR\'; ) -i"
		echo "# Spawning bash on host: $MASTER_HOST"

		"${sshmaster[@]}" "$runbash"	
	else
		echo "Spark failed to launch within $((waittime/60)) minutes."
	fi
else
	mysubmit
fi
