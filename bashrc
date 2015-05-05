
if [ -d "/opt/stack" ] ; then
    echo "Devstack installed"
    cd ~/devstack
    . openrc
else
    echo "Installing Devstack"
    cd /home/stack/devstack
    ./stack.sh
    echo ""
    devstart=`head -n 1 /opt/stack/logs/stack.sh.log | awk '{ print $2 }' | cut -d . -f 1`
    devstop=`tail -n 9 /opt/stack/logs/stack.sh.log | grep -m1 2015 | awk '{ print $2 }' | cut -d . -f 1`
    startdate=$(date -u -d "$devstart" +"%s")
    enddate=$(date -u -d "$devstop" +"%s")
    runtime=`date -u -d "0 $enddate sec - $startdate sec" +"%H:%M:%S"`

    echo " -----------------------------"
    echo " | DEVSTACK START:  $devstart |"
    echo " | DEVSTACK STOP:   $devstop |"
    echo " -----------------------------"
    echo " | TOTAL RUN TIME:  $runtime |"
    echo " -----------------------------"
    echo ""
    . openrc
fi
