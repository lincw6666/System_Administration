#!/bin/sh -x

Online_file="timetable.json"

# Width and height of blank that fill in the course name.
B_width="16"
B_height="6"

User_config="usr_config"
Class="usr_class"
Base_Schedule="base_schedule"
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

##################################################
#
# Parse timetable from json to "time_course"
#
##################################################

if ! [ -e "$Class" ] ; then
	sed -E -e '1,$s/},/\
#\
/g' -e '1,$s/","/"\
"/g' $Online_file | grep -E "cos_ename|cos_time|#" | tr -d '\n' > $Class
	
	sed -E -e '1,$s/"/:/g' -e '1,$s/#/\
/g' $Class | grep 'cos' | tr -s ':' > tmp && mv tmp $Class

	awk -F ':' '{print $3" - "$5}' $Class > tmp && mv tmp $Class
	sed -i '' -e '1,$s/"//g' $Class
	awk '{print NR" \""$0"\" off"}' $Class > tmp && mv tmp $Class
	sed -i '' -e '1i\
--buildlist "Add Class" 50 100 35' $Class
fi

##################################################

##################################################
#
# Build class schedule
#
##################################################

if ! [ -e "$Base_Schedule" ] ; then
	# Build x-label: Monday ~ Sunday
	echo -n 'x  ' > $Base_Schedule
	for i in '.Mon' '.Tue' '.Wed' '.Thu' '.Fri' '.Sat' '.Sun' ; do 
		echo -n $i >> $Base_Schedule ;
		seq -s ' ' $(( $B_width - 4 )) | tr -d "[:digit:]" >> $Base_Schedule
	done
	echo >> $Base_Schedule

	# Build blanks that fill in course name.
	for time in 'M' 'N' 'A' 'B' 'C' 'D' 'X' 'E' 'F' 'G' 'H' 'Y' 'I' 'J' 'K' 'L' ; do
		tmp="|x."
		echo -n "$time  " >> $Base_Schedule
		for i in `seq -s ' ' 7` ; do
			echo -n "$tmp" >> $Base_Schedule
			seq -s ' ' $(( $B_width - ${#tmp} )) | tr -d "[:digit:]" >> $Base_Schedule
		done
		echo >> $Base_Schedule

		tmp="|."
		for lines in `seq -s ' ' $(( $B_height - 2 ))` ; do
			echo -n ".  " >> $Base_Schedule
			for i in `seq -s ' ' 7` ; do
				echo -n "$tmp" >> $Base_Schedule
				seq -s ' ' $(( $B_width - ${#tmp} )) | tr -d "[:digit:]" >> $Base_Schedule
			done
			echo >> $Base_Schedule
		done

		echo -n "=  " >> $Base_Schedule
		for i in `seq -s ' ' 7` ; do
			seq -s= $(( $B_width - 2 )) | tr -d "[:digit:]" >> $Base_Schedule
			echo -n "  " >> $Base_Schedule
		done
		echo >> $Base_Schedule
	done

fi

##################################################

##################################################
#
# Build option dialog.
#
##################################################

if ! [ -e "$User_config" ] ; then
	echo '--checklist "Options" 25 50 20' > $User_config
	echo '1 "Show course name" on' >> $User_config
	echo '2 "Show classroom" off' >> $User_config
	echo '3 "Show Saturday and Sunday" off' >> $User_config
	echo '4 "Show NMXY" off' >> $User_config
fi

##################################################

############################################################################
#                                                                          #
#                            Main process start                            #
#                                                                          #
############################################################################

Add_class="0"
Options="3"
Exit="2"

GetCourse() {
	local retval
	
	retval=`cat $Class | grep -E "^$1 " | awk -F '"' '{print $2}'`
	
	echo $retval
}

GetTime() {
	local get_course retval

	get_course=`GetCourse $1`
	retval=`echo $get_course | awk -F '- ' '{print $1}' | sed -E "1,$ s/-[^, ]*[, ]//g"`
	
	echo $retval
}

GetName() {
	local get_course retval

	get_course=`GetCourse $1`
	retval=`echo $get_course | awk -F ' - ' '{print $2}' | sed -E -e "1,$ s/ /./g" -e "1,$ s/$/./g" | tr -s "."`

	echo $retval
}

GetClassRoom() {
	local get_course retval

	get_course=`GetCourse $1`
	retval=`echo $get_course | awk -F ' - ' '{print $1}' | sed -E -e "1,$ s/[0-9][^,]*-//g" -e "1,$ s/$/./g" | tr ',' ' ' | xargs -n1 | sort -u | xargs | tr ' ' ','`

	echo $retval
}

##################################################
#
# Functions deal with class collision.
#
##################################################

BuildChooseClass() {
	local select
	
	select=`echo $1 | sed -e '1,$ s/ / |^/g'`
	cat $Class | grep -E "^$select " | awk -F '"' '{print $2}' | cut -d '-' -f 1,3 | sed -e "1,$ s/- /-/g" > $2
} # End BuildChooseClass

BuildCollisionClass() {
	local day 

	> $1
	for i in `cat bang` ; do
		case $i in
			[0-7])
				day=$i
			;;
			*)
				for j in M N A B C D X E F G H Y I J K L ; do
					# Collision happened.
					if [ "`cat bang | grep $day | grep $j`" = "" ] ; then
						echo "Collision: $day$j" >> $1
						cat $2 | grep -E "$day[MNABCDXEFGHYIJKL]*$j" | awk -F '-' '{print $2}' >> $1
						echo "" >> $1
					fi
				done
			;;
		esac
	done
} # End VuildCollisionClass

IsCollision() {
	local time now_line Choose_class Collision_class select

	# Create base time table. Cancel out the time which has class.
	> table
	for i in `seq 7` ; do
		echo $i"MNABCDXEFGHYIJKL" >> table
	done

	# Check collision
	> bang
	for i in `seq 7` ; do
		echo $i "MNABCDXEFGHYIJKL" >> bang
	done

	for i in $1 ; do
		time=`GetTime $i | sed -e '1,$ s/\(.\)/\1 /g'`
		for j in $time ; do
			case $j in
				[1-7])
					now_line=$j
				;;
				*)
					# Collision happened.
					if [ "`cat table | grep -E "^$now_line" | grep $j`" = "" ] ; then
						sed -i '' -e "${now_line} s/$j//g" bang
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
	Choose_class="tmp_class"
	Collision_class="collision_class"
	BuildChooseClass "$1" $Choose_class
	BuildCollisionClass $Collision_class $Choose_class

	rm -f table bang $Choose_class

	if [ "`cat $Collision_class`" != "" ] ; then
		dialog --clear --msgbox "************ Collision!! ************

`cat $Collision_class`" 20 100
		rm -f $Collision_class
		return 1
	else
		rm -f $Collision_class
		return 0
	fi
} # End IsCollision

##################################################

GetOption() {
	local retval
	
	retval=""
	for i in `seq 4` ; do
		if [ "`cat $User_config | grep -E "^$i " | grep -E " on$"`" != "" ] ; then
			retval=$(($retval$i))
		fi
	done

	echo $retval
} # End GetOption

CourseOutputFormat() {
	local retval

	if [ "`echo $option | grep "1"`" != "" ] && [ "`echo $option | grep "2"`" != "" ] ; then
		retval=`GetName $1 && GetClassRoom $1`
	elif [ "`echo $option | grep "1"`" != "" ] ; then
		retval=`GetName $1`
	else
		retval=`GetClassRoom $1`
	fi

	echo $retval
}

FillClass() {
	base_str="`seq -s ' ' $(($B_width-1)) | tr -d "[:digit:]"`"

	now="1"
	now_line=`cat $Schedule | grep -nr "^$3" | cut -d ":" -f 1`
	while [ $now -le ${#1} ] ; do
		sub_name=`echo $1 | cut -c $now-$(($now+$B_width-4))`
		sub_name=`echo "$base_str" | sed -E "s/^.{${#sub_name}}/$sub_name/"`
		awk -v row=$now_line -v col=$(($2+1)) -v sub_str="$sub_name" -F '|' 'BEGIN {OFS="|"} { if( row == NR ) $col=sub_str}1' $Schedule > tmp && mv tmp $Schedule
		now=$(($now+$B_width-3))
		now_line=$(($now_line+1))
	done
} # End FillClass

while true ; do
	# Get user options.
	option=`GetOption`

	# Fill course name into schedule.
	cp $Base_Schedule $Schedule
	usr_course_id=`cat $Class | grep -E " on$" | awk -F ' ' '{print $1}'`
	for i in $usr_course_id ; do
		# Output course name or classroom or both.
		cos_output=`CourseOutputFormat $i | tr -d ' '`

		cos_time=`GetTime $i | sed -e '1,$ s/\(.\)/\1 /g'`
		for j in $cos_time ; do
			case $j in
				[0-7])
					day=$j
				;;
				*)
					FillClass $cos_output $day $j
				;;
			esac
		done
	done 

	# Delete Sat. and Sun. according to user configuration.
	if [ "`echo $option | grep "3"`" = "" ] ; then
		
	fi

	# Delete NMXY rows according to user configuration.
	if [ "`echo $option | grep "4"`" = "" ] ; then
		
	fi

	dialog --clear \
		--ok-label "Add Schedule" \
		--extra-button --extra-label "Options" \
		--help-button --help-label "Exit" \
		--textbox $Schedule 100 100
	
	case $? in
		$Add_class)
			# "origin" stores classes which are already on.
			origin=`cat $Class | grep -E "on$" | awk -F ' ' '{print $1}'`
			
			exec 3>&1
			while true ; do
				get_class=$(dialog --clear --file $Class 2>&1 1>&3)
				if [ "$get_class" = "" ] ; then
					# Restore class when cancel add class.
					sed -i '' -e "/on$/ s/on$/off/g" $Class
					for i in $origin ; do
						sed -i '' -e "/^$i / s/off$/on/g" $Class
					done
					break
				fi

				# Write selected selected class from off to on. Even it has collision.
				sed -i '' -e "/on$/ s/on$/off/g" $Class
				for i in $get_class ; do
					sed -i '' -e "/^$i / s/off$/on/g" $Class
				done

				# Check collision
				IsCollision "$get_class"
				if [ $? -eq 0 ] ; then
					break
				fi
			done
		;;
		$Options)
			while true ; do
				exec 3>&1
				get_option=$(dialog --clear --file $User_config 2>&1 1>&3)
				# Exit when select "cancel".
				if [ $? == 1 ] ; then
					break
				fi
				# Must select "show name" or "show class".
				if [ "`echo $get_option | grep -E "[12]"`" = "" ] ; then
					dialog --clear --msgbox 'Must select one of "Show course name" or "Show class room" !!' 10 60
				else
					# Write user option into file.
					get_option=`echo $get_option | tr -d ' '`
					sed -i '' "1,$ s/ on$/ off/g" $User_config
					sed -i '' "/^[$get_option] / s/ off$/ on/g" $User_config
					break
				fi
			done
		;;
		$Exit)
			break
		;;
	esac

done


