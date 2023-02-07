/* from Chapter 16 of Learning SAS by Example */

libname learn "/home/s31178890/Learning_SAS_by_Example";
run;

data learn.blood;
infile "/home/s31178890/Learning_SAS_by_Example/blood.txt";
input Subject Gender $ BloodType $ AgeCat $ WBC RBC Cholesterol;
run;

proc sort data = learn.blood out = Blood;
by Gender;
run;
proc means data = Blood n nmiss mean median
min max maxdec = 1;
by Gender;
var RBC WBC;
run;
/* or using class without a proc sort step first: */

proc format;
	value Chol_Group
	low -< 200 = "Low"
	200 - high = "High";
run;
/* proc format first creates buckets with labels for high and low cholesterol*/
proc means data = learn.blood n nmiss mean median
min max maxdec = 1;
class Cholesterol;
	format Cholesterol Chol_Group.;
var RBC WBC;
run;

/* Summary stats as a SAS data set */
proc means data = learn.blood noprint;
var RBC WBC;
output out = My_Summary mean = MeanRBC MeanWBC;
run;
title "Listing of My_Summary";
proc print data = My_Summary noobs;
run;

/* Output other statistics with proc means */
proc means data = learn.blood noprint;
var RBC WBC;
output out = Many_Stats
	mean = 
	n = 
	nmiss = 
	median = /autoname;
run;

/* To use a BY statement in proc means, the data must first be sorted by the same variable*/
proc sort data = learn.blood out = Blood_by_Gender;
by Gender;
run;

proc means data = Blood_by_Gender noprint;
by Gender;
var RBC WBC;
output out = By_Gender
	n =
	mean = /autoname;
run;

/* Same as above but with class statement and no pre-sorting */
proc means data = learn.blood noprint nway; /* use nway after noprint to remove "grand mean" */
class Gender;
var RBC WBC;
output out = By_Gender
	n =
	mean = /autoname;
run;

title "Listing of dataset with Many stats";
proc print data = By_Gender noobs;
run;

/* Two class variables */
proc means data = learn.blood noprint chartype;
class Gender AgeCat;
var RBC WBC;
output out = Summary
	n = 
	mean = /autoname;
run;

title "Using 2 class variables";
proc print data = Summary;
run;

/* use _TYPE_ to select particular group breakdowns */
proc print data = Summary (drop = _freq_) noobs;
where _type_ = "10";
run;

/* using data step to create separate summary data sets */
data Grand(drop = Gender AgeCat)
	By_Gender(drop = AgeCat)
	By_Age(drop = Gender)
	Cellmeans;
set Summary;
drop _type_;
rename _freq_ = Number;
if _type_ = '00' then output Grand;
else if _type_ ='01' then output By_Age;
else if _type_ = '10' then output By_Gender;
else if _type_ = '11' then output Cellmeans;
run;

title "Listing of data set Grand";
proc print data = Grand;
run;
title "Listing of data set By_Gender";
proc print data = By_Gender;
run;
title "Listing of data set By_Age";
proc print data = By_Age;
run;
title "Listing of data set Cellmeans";
proc print data = Cellmeans;
run;

/* Selecting different statistics for each variable */
proc means data = learn.blood noprint nway;
class Gender AgeCat;
output out = Summary(drop = _:) /* _: refers to all variables beginning with "_" */
	mean(RBC WBC) =
	n(RBC WBC Cholesterol)=
	median(Cholesterol)= /autoname;
run;

proc print data = Summary;
run;

/* Printing all possibilities of your class variables */
title "Demonstrating PRINTALLTYPES";
proc means data = learn.blood printalltypes;
class Gender AgeCat;
var RBC WBC Cholesterol;
run;


