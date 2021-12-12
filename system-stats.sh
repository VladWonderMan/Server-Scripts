#!/bin/bash

#cpu use threshold(%)
cpu_threshold='80'
#mem idle threshold(Mb)
mem_threshold='100'
#disk use threshold(%)
disk_threshold='90'
#network use threshold(Gb)
network_threshold='10'

print_help () {

	hv=(
	   "\n-==Resource monitoring script.==-\n"

	    "-p,  --proc         - manipulating /proc directory"
	    "-c,  --cpu          - managing cpu"
	    "-m,  --memory       - managing memory"
	    "-d,  --disks        - managing disks"
	    "-n,  --network      - managing network"
	    "-as, --allstats     - cpu, memory, disk, network stats"
	    "-la, --loadaverage  - output of system load avarage"	
	    "-t,  --task         - add task to cron"

            "-k,  --kill         - send a signal to a processes\n"
            "-o,  --output       - save a result on a drive"
	    "                      /tmp/system-stats-Output.txt\n"

            "-os, --outputstats  - save all stats output to a log file"
	    "                      /var/log/system-stats.log\n"

            "-h,  --help         - description of script commands and examples\n"

	    "-==Second Parameter for Commands:==-\n"

		"-p cpuinfo          - detailed info about cpu"
		"-p meminfo          - detailed info about system memory\n"
		
		"-c state            - cpu load in percentage"
		"-c pslist           - list of processes running in the system\n"
		
		"-m state            - show available memory in MB\n"
		
		"-d state            - show main disk usage in percentage\n"
		
		"-n state            - total network usage for a day"
		"-n realtime         - network speed stats in real time\n"
		
		"-t remove           - remove task from cron.hourly"
		"                      and remove logfile(/var/log/system-stats.log)\n"
							   
		"-k 'PIDnumber'      - specify PID number to kill a process\n"

		"-==Examples:==-\n"

		"system-stats.sh -p cpuinfo -o    - save output to /tmp/system-stats-output.txt\n"
		
		"system-stats.sh -t               - create a copy of a script in /etc/cron.hourly"
		"                                   with option -os. A log file will be available"
		"                                   in /var/log/system-stats.log\n"

	)

	for i in "${hv[@]}"; do
		echo -e "$i"
	done
	
}

bintest (){

	packname=$1

	if [[ $1 == mpstat  ||  $1 == pidstat ]]; then
			packname="sysstat"
	fi

	if [ ! -f $2 ]; then
		echo "Package $packname is not installed!!"
		return 1
	fi

}

exitscript(){
	if [ $? -eq 1 ]; then
		exit
	fi
}

cpu_usage () {
	cpu_idle=`top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/"|cut -f 1 -d "."`
	cpu_use=`expr 100 - $cpu_idle`
 	echo "CPU Utilization: $cpu_use%"
	if [ $cpu_use -gt $cpu_threshold ] ; then
        echo "CPU Warning!"
	fi
}

mem_usage () {
	#MB units
	mem_free=`free -m | grep "Mem" | awk '{print $4+$6}'`
	echo "Memory Space Available : $mem_free MB"
	if [ $mem_free -lt $mem_threshold ] ; then
			echo "MEM Warning!"
	fi
}

disk_usage () {
	disk_use=`df -P | grep "/$" | awk '{print $5}' | cut -f 1 -d "%"`
	echo "Disk Usage : $disk_use%" 
	if [ $disk_use -gt $disk_threshold ] ; then
			echo "Disk Warning!"
	fi
}

network_usage (){
		data_use=`vnstat --oneline | awk -F ";" '{print $6}'`
		if [ -z "$data_use" ]; then
			data_use="Not enough data available yet."
		fi
		echo "Total Data Usage(Today): $data_use"

		measure=`vnstat --oneline | awk -F ";" '{print $6}'| cut -d " "  -f2`
		if [ "$measure" == "GiB" ]; then

			data_use_number=`echo $data_use | cut -d " "  -f1| cut -d "." -f1`
			if [ $data_use_number -gt $network_threshold ]; then
			 echo "Data Use Warning!"
			fi

		fi
		
}

#Output in to a log file
if [ "$1" == '-os' ] || [ "$1" == '--outputstats' ] ; then

	bintest vnstat /usr/bin/vnstat
	bintest ifstat /usr/bin/ifstat
	bintest pidstat /usr/bin/pidstat
	exitscript

	formated_date=$(date +%d.%m.%Y" "%H:%M:%S)
	log_file="/var/log/system-stats.log"

	if [ ! -f $log_file ]; then
		touch $log_file
	fi

	cpu_idle=`top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/"|cut -f 1 -d "."`
	cpu_use=`expr 100 - $cpu_idle`
	mem_free=`free -m | grep "Mem" | awk '{print $4+$6}'`
	data_use=`vnstat --oneline | awk -F ";" '{print $6}'`
	measure=`vnstat --oneline | awk -F ";" '{print $6}'| cut -d " "  -f2`
	net_speed=`ifstat 2 1 | tail -1`
	net_speed_in=`echo $net_speed | awk '{print $1}'`
	net_speed_out=`echo $net_speed | awk '{print $2}'`

	if [ -z "$data_use" ]; then
		data_use="Not enough data available yet."
	fi

	echo "$formated_date CPU Utilization: $cpu_use%  Memory Space Available: $mem_free MB  Total Data Usage: $data_use  Network Activity: KB/s in $net_speed_in KB/s out $net_speed_out" >> $log_file

	if [ $cpu_use -gt $cpu_threshold ] ; then
        echo "$formated_date CPU Warning!" >> $log_file
	fi
	
	if [ $mem_free -lt $mem_threshold ] ; then
		echo "$formated_date MEM Warning!" >> $log_file
	fi

	if [ "$measure" == "GiB" ]; then
		data_use_number=`echo $data_use | cut -d " "  -f1| cut -d "." -f1`
		if [ $data_use_number -gt $network_threshold ]; then
			echo "$formated_date Data Use Warning!" >> $log_file
		fi

	fi	
fi

#help
if [ -z $1 ] || [ "$1" == '-h' ] || [ "$1" == '--help' ] ; then
	print_help

	bintest vnstat /usr/bin/vnstat
	bintest ifstat /usr/bin/ifstat
	bintest pidstat /usr/bin/pidstat

	exitscript
fi

#Output
for i in $@ ; do

	if [ "$i" == '-o' ] || [ "$i" == '--output' ] ; then
		exec > /tmp/system-stats-output.txt
		break		
	fi
done


#proc directory
if [ "$1" == '-p' ] || [ "$1" == '--proc' ] ; then

	if [ $# -gt 1 ]; then

		case "$2" in
		
		cpuinfo) 
		cat /proc/cpuinfo
		;;

		meminfo)
		cat /proc/meminfo
		;;

		esac

	else
		ls --color=auto /proc
	fi
fi

#cpu info                                                  
if [ "$1" == '-c' ] || [ "$1" == '--cpu' ] ; then
	
	bintest pidstat /usr/bin/pidstat
	exitscript

	if [ $# -gt 1 ]; then

		case "$2" in

		state) cpu_usage
		;;
		
		pslist) pidstat
		;;

		esac

	else
		top -n 1 | head -3 | tail -2
	fi
fi

#disks info
if [ "$1" == '-d' ] || [ "$1" == '--disks' ] ; then

	if [ "$2" == 'state' ]; then
		disk_usage
	else
		df -h
	fi
		
fi



#memory info
if [ "$1" == '-m' ] || [ "$1" == '--memory' ] ; then
	
	if [ "$2" == 'state' ]; then
		mem_usage
	else
		free -h
	fi
fi

#avarage load
if [ "$1" == '-la' ] || [ "$1" == '--loadaverage' ] ; then
	uptime | awk '{print $8,$9,$10,$11,$12}'	
fi

#network load
if [ "$1" == '-n' ] || [ "$1" == '--network' ] ; then

	bintest vnstat /usr/bin/vnstat
	bintest ifstat /usr/bin/ifstat

	exitscript
	
	if [ "$2" == 'state' ]; then
		network_usage
	elif [ "$2" == 'realtime' ]; then

		ifstat -zntS

	else
		ifstat 2 1
	fi
				
fi

#kill PID
if [ "$1" == '-k' ] || [ "$1" == '--kill' ] ; then
	kill $2			
fi


#all main stats
if [ "$1" == '-as' ] || [ "$1" == '--allstats' ] ; then

	func=("cpu_usage" "mem_usage" "disk_usage")
	for (( i=1; i<=3; i++ )); do
	${func[$i]}
	done

	# cpu_usage
	# mem_usage
	# disk_usage

	bintest vnstat /usr/bin/vnstat
	bintest ifstat /usr/bin/ifstat
	exitscript

	network_usage
	ifstat 2 1

fi

#add task to cron.hourly
if [ "$1" == '-t' ] || [ "$1" == '--task' ] ; then

	bintest vnstat /usr/bin/vnstat
	bintest ifstat /usr/bin/ifstat
	bintest pidstat /usr/bin/pidstat

	exitscript

	if [ "`id -u`" != "0" ]; then
		echo "This option must be run as root"
		exit 1
	fi

	if [ "$2" == 'remove' ]; then
		rm -f /etc/cron.hourly/system-stats
		rm -f /var/log/system-stats.log
		echo "Task removed successfully"
	else
	  task_file="/etc/cron.hourly/system-stats"

	  cp "$(readlink -f $0)" $task_file
	  chmod +x $task_file
	  sed -i '183,$d' $task_file
	  sed -i '/"$1" ==/c if [ -z $1 ] ; then' $task_file

	  echo "Task created in /etc/cron.hourly/system-stats successfully"

	fi 
fi
