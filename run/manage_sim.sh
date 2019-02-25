#!/bin/bash


SESSION=gazebo_sim
YARPSERVER=yarpserver
GAZEBO_ICUB_DIR=${HOME}/opt


GAZEBO_WORLD="$GAZEBO_ICUB_DIR/icub-gazebo/worlds/icub_fixed_light.world"
ICUBSIM_EXEC="icub"
GAZEBO_EXEC="gazebo $GAZEBO_WORLD"
GAZEBO_EXEC_WEBSERVER="gzserver $GAZEBO_WORLD"
YARP_ROBOT_INTERFACE="yarprobotinterface --context simCartesianControl"
GAZE_CONTROLLER="iKinGazeCtrl --robot icubSim --from configSim.ini"
CARTESIAN_SOLVER="iKinCartesianSolver --context simCartesianControl --part right_arm"


# -------------------------------------------------------------------------------------------

# waits for process to end
# :paran $1: pid of the process
wait_proc() {
    pid=$1
    while [[ ! -z "$(ps -e| grep "^$1")" ]]; do sleep 0.1; done
}

# kills all current $SESSION sessions
kill_session() { 
    
    sessions=$(count_sessions)      
    
    echo "killing previous sessions..."
   
    #close gazebo
    gazebo=$(ps -e| grep "\<[g]azebo\>" | awk '{print $1}')
    [[ ! -z "$gazebo" ]] && (kill $gazebo; wait_proc $gazebo)

    #close yarprobotinterface
    yarprobotinterface=$(ps -e| grep "\<[y]arprobotinterface\>" | awk '{print $1}')
    [[ ! -z "$yarprobotinterface" ]] && (kill $yarprobotinterface; wait_proc $yarprobotinterface)

    #close gazecontroller
    ikingazectrl=$(ps -e| grep "\<[i]KinGazeCtrl\>" | awk '{print $1}')
    [[ ! -z "$ikingazectrl" ]] && (kill $ikingazectrl; wait_proc $ikingazectrl)

    #TODO close cartesiancontroller
    ikincartesiansolver=$(ps -e| grep "\<[i]KinCartesianSolver\>" | awk '{print $1}')
    [[ ! -z "$ikincartesiansolver" ]] && (kill $ikincartesiansolver; wait_proc $ikincartesiansolver)

        
    for ses in $sessions;    
    do      
        echo "   killing session $ses" 
       
            screen -S "${SESSION}" -X quit &> /dev/null   
    done;
    screen -wipe &> /dev/null 
    echo "Done."
}

# init the screen session
init_screen() {
    kill_session  
    sleep 3
    screen -dmS $SESSION
}

# :param $1: title of the window
prepare_window() {
    title=$1
    
    screen -S $SESSION -X screen
    sleep 0.1
    screen -S $SESSION -X title $title 
    sleep 0.1
    screen -S $SESSION -X -p $title stuff "touch /tmp/${title}_prepared;\n"
    while [[ ! -f "/tmp/${title}_prepared" ]]; do echo "Opening window for ${title}..."; sleep 0.1; done
    rm -f /tmp/${title}_prepared
}

# :param $@: list of the windows to display in the current terminal
display_windows() {
    while [[ -z "$(screen -ls| grep $SESSION)" ]]; do sleep 0.1; done
    for w in "$@"; do
       screen -S $SESSION -X focus 
       screen -S $SESSION -X select $w 
       screen -S $SESSION -X split 
    done
    screen -S $SESSION -X focus 
    screen -S $SESSION -X remove 
}

# :param $1: title of the window
# :param $2: command to be executed
# :param $3: sleep interval after command (default 1)
exec_on_window() {
    title=$1
    comm=$2
    interval=${3:-1}
    screen -S $SESSION -p $title -X stuff "${comm} 2>&1|tee ${title}_log \n"
    sleep $interval
}

# return the list of session pids
count_sessions() {
    echo -n "$(screen -ls | \
            grep "$SESSION"| \
            grep -o '^\s\+[0-9]\+'|\
            sed 's/^\s\+\([0-9]\+\)[\.].*/\1/')" 
}

# -------------------------------------------------------------------------------------------

# Manage arguments
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

usage()
{
    cat <<EOF

    usage: $0 options

    This script runs a gazebo simulation 

    OPTIONS:
    -r --run         Starts the simulation
    -k --close       Closes all processes
    -w --web         Stats a remote simulation (uses gzweb)
    -h --help        Show this help menu 
EOF
}


RUN=false
CLOSE=false
WEB=false

# getopt
GOTEMP="$(getopt -o "rkwh" -l "run,close,web,help"  -n '' -- "$@")"

if [[ -z "$(echo -n $GOTEMP |sed -e"s/\-\-\(\s\+.*\|\s*\)$//")" ]]; then
    usage; exit;
fi

eval set -- "$GOTEMP"

while true ;
do
    case "$1" in
        -k | --close)
            CLOSE=true
            break ;;
        -r | --run)
            RUN=true
            shift;;
        -w | --web)
            WEB=true
            shift;;
        -h | --help)
            echo "on help"
            usage; exit;
            shift;
            break;;
        --) shift ;
            break ;;
    esac
done

# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

if [[ "$RUN" == true ]]; then
    echo run 

    # prepare screen session
    init_screen
    echo ----

    prepare_window yarp
    prepare_window gazebo
    prepare_window interface
    prepare_window gaze
    prepare_window cartesian
    [[ $WEB == true ]] && prepare_window web

    sleep 1
    while [ "$(count_sessions)" -lt 4 ]; do sleep 0.1;  done     

    if [[ $WEB == false ]]; then
        # open terminal with all session windows
        x-terminal-emulator -e "screen -rdS $SESSION"
        display_windows yarp gazebo interface gaze cartesian
    fi

    # start simulation
    echo "starting yarp ..."
    exec_on_window yarp "$YARPSERVER"
    sleep 2
    echo "starting gazebo ..."
    if [[ $WEB == false ]]; then
        exec_on_window gazebo "$GAZEBO_EXEC"
    elif [[ $WEB == true ]]; then
        exec_on_window gazebo "$GAZEBO_EXEC_WEBSERVER"
        sleep 0.1
        exec_on_window web "cd $GAZEBO_ICUB_DIR/gzweb && ./start_gzweb.sh"
    fi
    sleep 5
    echo "starting interface ..."
    exec_on_window interface "$YARP_ROBOT_INTERFACE"
    sleep 1
    echo "starting gaze ..."
    exec_on_window gaze "$GAZE_CONTROLLER"
    sleep 1
    echo "starting cartesian ..."
    exec_on_window cartesian "$CARTESIAN_SOLVER"

elif [[ "$CLOSE" == true ]]; then
    echo close
    kill_session
fi




