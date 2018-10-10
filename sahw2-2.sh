#!/bin/sh

Online_file="timetable.json"

# Width and height of blank that fill in the course name.
B_width="16"
B_height="5"

User_config="usr_config"
Class="usr_class"
Schedule="usr_schedule"



##################################################
#
# Get timetable if it does not exist.
#
##################################################

if ! [ -e "$Online_file" ] ; then
	curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crs_name=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=*' > $Online_file
fi


##################################################
#
# Parse timetable from json to "time_course"
#
##################################################

if ! [ -e "$Class" ] ; then
	sed -E -e '1,$s/},/\
#\
/g' -e '1,$s/,/\
/g' $Online_file | grep -E "cos_ename|cos_time|#" | tr -d '\n' > $Class
	
	sed -E -e '1,$s/"/:/g' -e '1,$s/#/\
/g' $Class | grep 'cos' | tr -s ':' > tmp && mv tmp $Class

	awk -F ':' '{print $3" - "$5}' $Class > tmp && mv tmp $Class
	sed -i '' -e '1,$s/"//g' $Class
	awk '{print NR" \""$0"\" off"}' $Class > tmp && mv tmp $Class
	sed -i '' -e '1i\
--buildlist "Add Class" 50 100 35' $Class
fi


##################################################
#
# Build class schedule
#
##################################################

if ! [ -e "$Schedule" ] ; then
	# Build x-label: Monday ~ Sunday
	echo -n 'x  ' >> $Schedule
	for i in '.Mon' '.Tue' '.Wed' '.Thu' '.Fri' '.Sat' '.Sun' ; do 
		echo -n $i >> $Schedule ;
		seq -s ' ' $(( $B_width - 4 )) | tr -d "[:digit:]" >> $Schedule
	done
	echo >> $Schedule

	# Build blanks that fill in course name.
	for time in 'M' 'N' 'A' 'B' 'C' 'D' 'X' 'E' 'F' 'G' 'H' 'Y' 'I' 'J' 'K' 'L' ; do
		tmp="|x."
		echo -n "$time  " >> $Schedule
		for i in `seq -s ' ' 7` ; do
			echo -n "$tmp" >> $Schedule
			seq -s ' ' $(( $B_width - ${#tmp} )) | tr -d "[:digit:]" >> $Schedule
		done
		echo >> $Schedule

		tmp="|."
		for lines in `seq -s ' ' $(( $B_height - 2 ))` ; do
			echo -n ".  " >> $Schedule
			for i in `seq -s ' ' 7` ; do
				echo -n "$tmp" >> $Schedule
				seq -s ' ' $(( $B_width - ${#tmp} )) | tr -d "[:digit:]" >> $Schedule
			done
			echo >> $Schedule
		done

		echo -n "=  " >> $Schedule
		for i in `seq -s ' ' 7` ; do
			seq -s= $(( $B_width - 2 )) | tr -d "[:digit:]" >> $Schedule
			echo -n "  " >> $Schedule
		done
		echo >> $Schedule
	done

fi


##################################################
#
# Main process.
#
##################################################

Add_class="0"
Options="3"
Exit="2"

# Check collision.
IsCollision() {
	for i in `seq 7` ; do
		if [ $i == 1 ] ; then
			echo $i"MNABCDXEFGHYIJKL" > table
		else 
			echo $i"MNABCDXEFGHYIJKL" >> table
		fi
	done

	# Cancel out the time which already has class.
	#no_time=`awk -F '"' '/on$/{print $2}' $Class | cut -d '-' -f 1`
	#for i in $no_time ; do
	#	j=`echo $i | sed -e 's/\(.\)/\1 /g'`
	#	for k in $j ; do
	#		case $k in
	#			[1-7])
	#				now_line=$k
	#			;;
	#			*)
	#				sed -i '' -e "${now_line} s/$k//g" table
	#			;;
	#		esac
	#	done
	#done

	# Check collision
	for i in `seq 7` ; do
		if [ $i == 1 ] ; then
			echo $i "MNABCDXEFGHYIJKL" > bang
		else
			echo $i "MNABCDXEFGHYIJKL" >> bang
		fi
	done
	for i in $get_class ; do
		time=`cat $Class | grep -E "^$i " | awk -F '"' '{print $2}' | cut -d '-' -f 1 | sed -e 's/\(.\)/\1 /g'`
		for j in $time ; do
			case $j in
				[1-7])
					now_line=$j
				;;
				*)
					# Collision happened.
					if [ "`cat table | grep -E "^$now_line" | grep $j`" = "" ] ; then
						#if [ "`echo $bang | grep -E "^$i$|^$i | $i$| $i "`" = "" ] ; then 
						#	bang="$bang$i "
						#fi
						sed -i '' -e "${now_line} s/$j/ /g" bang
					# No collision.
					else
						sed -i '' -e "${now_line} s/$j/ /g" table
						if [ "`cat table | grep -E "^${now_line}" | grep -E " $i$| $i "`" = "" ] ; then
							sed -i '' -e "${now_line} s/$/ $i/g" table
						fi
					fi
				;;
			esac
		done
	done
	
	# Output collision message

}

while true ; do 
	dialog --clear \
		--ok-label "Add Schedule" \
		--extra-button --extra-label "Options" \
		--help-button --help-label "Exit" \
		--textbox $Schedule 100 100
	
	case $? in
		$Add_class)
			exec 3>&1
			get_class=$(dialog --clear --file $Class 2>&1 1>&3)
			IsCollision
		;;
		$Options)

		;;
		$Exit)
			break
		;;
	esac

done


