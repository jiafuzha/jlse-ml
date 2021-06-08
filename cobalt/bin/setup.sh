# Set the scripts dir if unset.
[[ -z ${SPARKJOB_SCRIPTS_DIR+X} ]] \
        && declare SPARKJOB_SCRIPTS_DIR="$(cd $(dirname "$BASH_SOURCE")&&pwd)"

source "$SPARKJOB_SCRIPTS_DIR/setup-common.sh"

source "$SPARKJOB_SCRIPTS_DIR/env_$SPARKJOB_HOST.sh"
echo "sourced $SPARKJOB_SCRIPTS_DIR/env_$SPARKJOB_HOST.sh"
[[ -s $SPARKJOB_CONFIG_DIR/env_local.sh ]] &&
	source "$SPARKJOB_CONFIG_DIR/env_local.sh"
[[ -s $SPARKJOB_CONFIG_DIR/env_local.sh ]] &&
	echo "sourced $SPARKJOB_CONFIG_DIR/env_local.sh"
