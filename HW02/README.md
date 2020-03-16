NCTU SA Homework 02
===

# Introduction
There are two parts in homework 02.
- Part 01: Filesystem Statistics.
- Part 02: Course Registration System.

# Part 01
## Requirements
- Inspect the current directory(“.”) and all sub-directory.
- Calculate the number of directories.
- Do not include ‘.’ and ‘..’.
- Calculate the number of files.
- Calculate the sum of all file size.
- List the top 5 biggest files.
- Only consider the regular file. Do not count in the link, FIFO, block device... etc.

## Restrictions
- Use **one-line** command.
- No temporary file or shell variables.
- No “&&” “||” “>” “>>” “<” “;” “&”, but you can use them in the awk command. Actually, you don’t need them to finish this homework.
- Only pipes are allowed.

## Result
![](https://i.imgur.com/NDe7iwV.png)

# Part 02
## Requirements
- Download timetable from timetable.nctu.edu.tw using curl, do this step only when no data kept at local.
- List all courses, keep recording all selected courses and options (including after program restart). No modification if user select cancel while saving.
- Check time conflict and ask user to solve the conflict by reselect courses.
- Options for display:
  - Course title or classroom number
  - Sat. and Sun.
  - Less important course time, such as NMXY.
- Output aligned chart.
- Display multi-line per grid.
- Display all classroom number in every grid if the course uses multiple classrooms.
- Course for free time (Show all current available courses).
- Course searching
  - Search course name.
    - Input: part of the course name.
    - Output: all courses containing the search word in the course name.
  - Search course time.
    - Input: part of the course time.
    - Output: all courses containing the search time.

## Results
⚠ Only work on FreeBSD ⚠

![](https://i.imgur.com/9P8DK0l.png)
![](https://i.imgur.com/zQiTW0x.png)
