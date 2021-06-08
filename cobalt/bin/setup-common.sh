# This file can be sourced multiple times

# Set the working dir if unset, requires JOBID
if [[ -z ${SPARKJOB_WORKING_DIR+X} ]];then
        if [[ -z ${SPARKJOB_JOBID+X} ]];then
                echo "Error: SPARKJOB_JOBID required for setup.sh"
                exit 1
        else
                declare SPARKJOB_WORKING_DIR="$SPARKJOB_OUTPUT_DIR/$SPARKJOB_JOBID"
        fi
fi
export SPARKJOB_WORKING_DIR

export SPARKJOB_WORKING_ENVS="$SPARKJOB_WORKING_DIR/.spark-env"

[[ -z ${SPARKJOB_HOST+X} ]] && declare -x SPARKJOB_HOST=skylake
