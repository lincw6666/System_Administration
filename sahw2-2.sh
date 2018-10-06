#!/bin/sh

Online_file="timetable.json"
Course_file="time_course"

# Variables for class schedule.
Class="usr_class"
# Width and height of blank that fill in the course name.
B_width="16"
B_height="5"

User_config="usr_config"

# Get timetable if it does not exist.
if ! [ -e "$Online_file" ] ; then
	curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crs_name=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=*' > $Online_file
fi

# Parse timetable from json to "time_course".
if ! [ -e "$Course_file" ] ; then
	sed -E -e '1,$s/},/\
#\
/g' -e '1,$s/,/\
/g' $Online_file | grep -E "cos_ename|cos_time|#" | tr -d '\n' > $Course_file
	
	sed -E -e '1,$s/"/:/g' -e '1,$s/#/\
/g' $Course_file | grep 'cos' | tr -s ':' > tmp && mv tmp $Course_file

	awk -F ':' '{print $3" - "$5}' $Course_file > tmp && mv tmp $Course_file
	sed -i '' -e '1,$s/"//g' $Course_file
fi

# Build class schedule
if ! [ -e "$Class" ] ; then
	# Build x-label: Monday ~ Sunday
	echo -n 'x  ' >> $Class
	for i in '.Mon' '.Tue' '.Wed' '.Thu' '.Fri' '.Sat' '.Sun' ; do 
		echo -n $i >> $Class ;
		seq -s ' ' $(( $B_width - 4 )) | tr -d "[:digit:]" >> $Class
	done
	echo >> $Class

	# Build blanks that fill in course name.
	for time in 'M' 'N' 'A' 'B' 'C' 'D' 'X' 'E' 'F' 'G' 'H' 'Y' 'I' 'J' 'K' 'L' ; do
		tmp="|x."
		echo -n "$time  " >> $Class
		for i in `seq -s ' ' 7` ; do
			echo -n "$tmp" >> $Class
			seq -s ' ' $(( $B_width - ${#tmp} )) | tr -d "[:digit:]" >> $Class
		done
		echo >> $Class

		tmp="|."
		for lines in `seq -s ' ' $(( $B_height - 2 ))` ; do
			echo -n ".  " >> $Class
			for i in `seq -s ' ' 7` ; do
				echo -n "$tmp" >> $Class
				seq -s ' ' $(( $B_width - ${#tmp} )) | tr -d "[:digit:]" >> $Class
			done
			echo >> $Class
		done

		echo -n "=  " >> $Class
		for i in `seq -s ' ' 7` ; do
			seq -s= $(( $B_width - 2 )) | tr -d "[:digit:]" >> $Class
			echo -n "  " >> $Class
		done
		echo >> $Class
	done

fi

# Create textbox.
dialog --textbox $Class 100 100

