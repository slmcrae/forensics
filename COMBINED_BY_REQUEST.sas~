/* Leap data by offence and finyear
off (offence category) is formatted as $GROUP. with informat $2.  to change this
first chang format to character $30.*//* format $off_cat created to deal with the $GROUP. format which was like a key:value dictionary */

/* the custom format is then applied to a new column called off_2 which reformats the offence category */
proc format;
	value $off_cat
	"A"="HOMICIDE"
	"B"="RAPE"
	"C"="SEX (NON RAPE)"
	"D"="ROBBERY"
	"E"="ASSAULT"
	"G"="ABDUCTION / KIDNAP"
	"H"="ARSON"
	"I"="PROPERTY DAMAGE"
	"J"="BURGLARY (AGGRAVATED)"
	"K"="BURGLARY (RESIDENTIAL)"
	"KB"="BURGLARY (OTHER)"
	"L"="DECEPTION"
	"M"="HANDLE STOLEN GOODS"
	"N"="THEFT FROM MOTOR VEHICLE"
	"O"="THEFT (SHOPSTEAL)"
	"P"="THEFT OF MOTOR VEHICLE"
	"Q"="THEFT (BICYCLE)"
	"R"="THEFT (OTHER)"
	"S"="DRUGS (CULT / MANUF / TRAFF)"
	"T"="DRUGS (POSSESS / USE)"
	"WA"="GOING EQUIPPED TO STEAL"
	"XA"="JUSTICE PROCEDURES"
	"XB"="REGULATED PUBLIC ORDER"
	"XC"="WEAPONS / EXPLOSIVES"
	"XD"="HARASSMENT"
	"XG"="BEHAVIOUR IN PUBLIC"
	"XH"="OTHER";
run;
proc sql;
create table crime1 as
select *, off format=$30.as off_code
from forensic.combine_crimestats;
quit;
data crime1;
set crime1;
off_2=put(off_code, $off_cat.);
run;

data crime1;
set crime1;
if off_2='BURGLARY (OTHER)' THEN do;
	off_2='BURGLARY (RESIDENTIAL)';
	off_code='K';
end;
run;

proc sql;
create table crime2 as
select distinct create_d, off_2, sum(totals) as leapTotal
from crime1
group by create_d, off_2;
quit;




/* Now prepping the PALM SUMMARY data 
first sorting by request date to make it easier to join with palm_summary_offence data */
proc sort data=forensic.palm_summary out=palm;
by request_start_date_sas;
run;

/* create new table with specific variables of interest and join with offence data */
proc sql;
create table palm_stats as 
select ps.container, ps.item, ps.profile_request_type, ps.request_start_date, 
ps.request_start_date_sas, ps.police_division, ps.unit, off.*
from palm ps LEFT JOIN forensic.palm_summary_offence off
on ps.container EQ off.container AND ps.item EQ off.item AND
ps.profile_request_type EQ off.profile_request_type
where request_start_date_sas ge 1435795200;
quit;
/* date convert steps to get finanical year as month. format doesn't work here.
first format sas date as datetime21.*/
proc sql;
create table date_convert as
select *, request_start_date_sas as datetime format=datetime21.,
	datepart(datetime)as date
from palm_stats;
quit;
/* convert to month 'buckets' and format the results as year.
be sure to have "beginning" because this will ensure that it matches the crimestats data */
proc sql;
create table month_added as
select *, Intnx("month", date, 0, "beginning")as month format=MONYY.
from date_convert;
quit;

/* Clean up missing offence_categories after first step*/
data palm_offence;
set month_added;
if missing(offence_category)THEN do;
		if unit='Botany Branch' OR unit='Drug Analysis Unit' OR unit='Drug Exhibit Management' OR
			unit ='Clandestine Laboratory' OR unit='Chemical Drug Intelligence' THEN do;
			offence_category='DRUGS (POSSESS / USE)';
		end;
end;
if offence_category='DRUGS (USE)' THEN do;
	offence_category='DRUGS (POSSESS / USE)';
end;
run;

/* Adding 'ENQUIRY' as separate column */
proc sql;
create table palm_total as 
select po.*, pe.*
from palm_offence po LEFT JOIN forensic.palm_summary_enquiry pe
ON po.container EQ pe.container AND po.item EQ pe.item AND
po.profile_request_type EQ pe.profile_request_type;
quit;

/* fill offence_category that has enquiry filled */
data palm_all_cleaned;
set palm_total;
if missing(offence_category) AND ~missing(enquiry) then do;
offence_category= 'ENQUIRY FORENSIC';
end;
if missing(offence_category) AND missing(enquiry)then do;
	if unit="Fire & Explosion" then offence_category="ARSON";
end;
if missing(offence_category) AND missing(enquiry)then do;
	if profile_request_type='Fingerprint Examination - Clan Lab' then
		offence_category="DRUGS (CULT / MANUF / TRAFF)";
end;
if missing(offence_category) AND missing(enquiry)then do;
	if unit="Ballistics Unit" AND profile_request_type="Ballistics Service" then
		offence_category="WEAPONS/EXPLOSIVES";
end;
run;

/*grouping by month and offence category */
proc sql;
create table total_offences as
select distinct month, offence_category, count(*) as total
from palm_all_cleaned
group by month, offence_category;
quit;

/* group by month order by offence category.  Can probably merge this into total_offences table*/
proc sql;
create table crime_sorted as
select create_d, off_2, leapTotal
from crime2
order by create_d, off_2;
quit;

/* the creation of the master table with palm and leap data merged, 
grouped by month and offence category */
proc sql;
create table OFFENCES_TIME_SERIES as
select t.month, t.offence_category, t.total, c.create_d, c.off_2, c.leapTotal, t.total/c.leapTotal as utilization
from crime_sorted c LEFT JOIN total_offences t
ON  t.offence_category=c.off_2 AND t.month=c.create_d;
quit;

data MASTER_OFFENCES_TIME_SERIES;
set OFFENCES_TIME_SERIES;
if missing(month)then do;
	month=create_d;
	offence_category=off_2;
	total=0;
	utilization=0;
end;
run;

proc sql;
create table overall_prep_request as
select distinct month, sum(total) as palm_total, sum(leapTotal) as combo_total
from MASTER_OFFENCES_TIME_SERIES
group by month;
quit;

proc sql;
create table overall_request as
select *, palm_total/combo_total as utilization
from overall_prep_request;
quit;


proc sql;
create table HOMICIDE_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="HOMICIDE";
quit;

proc sql;
create table DRUGS_CULT_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="DRUGS (CULT / MANUF / TRAFF)";
quit;

proc sql;
create table DRUGS_POSS_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="DRUGS (POSSESS / USE)";
quit;

proc sql;
create table ASSAULT_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="ASSAULT";
quit;

proc sql;
create table BURGLARY_AGG_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="BURGLARY (AGGRAVATED)";
quit;
proc sql;
create table BURGLARY_RES_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="BURGLARY (RESIDENTIAL)";
quit;
proc sql;
create table ARSON_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="ARSON";
quit;
proc sql;
create table RAPE_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="RAPE";
quit;
proc sql;
create table WEAPONS_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="WEAPONS / EXPLOSIVES";
quit;
proc sql;
create table THEFT_of_CAR_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="THEFT OF MOTOR VEHICLE";
quit;
proc sql;
create table THEFT_from_CAR_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="THEFT FROM MOTOR VEHICLE";
quit;
proc sql;
create table THEFT_SHOPSTEAL_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="THEFT (SHOPSTEAL)";
quit;
proc sql;
create table THEFT_OTHER_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="THEFT (OTHER)";
quit;
/*  -------------------- 12 offences --------------------------- */

proc sql;
create table SEX_NON_RAPE_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="SEX (NON RAPE)";
quit;
proc sql;
create table ROBBERY_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="ROBBERY";
quit;
proc sql;
create table REGULATED_PUBLIC_ORDER_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="REGULATED PUBLIC ORDER";
quit;
proc sql;
create table PROPERTY_DAMAGE_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="PROPERTY DAMAGE";
quit;
proc sql;
create table OTHER_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="OTHER";
quit;
proc sql;
create table JUSTICE_PROCEDURES_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="JUSTICE PROCEDURES";
quit;
proc sql;
create table HARASSMENT_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="HARASSMENT";
quit;
proc sql;
create table HANDLE_STOLEN_GOODS_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="HANDLE STOLEN GOODS";
quit;
proc sql;
create table GOING_EQUIP_TO_STEAL_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="GOING EQUIPPED TO STEAL";
quit;
proc sql;
create table DECEPTION_TIME_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="DECEPTION";
quit;
proc sql;
create table BEHAVIOUR_IN_PUBLIC_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="BEHAVIOUR IN PUBLIC";
quit;
proc sql;
create table ABDUCTION_KIDNAP_SERIES as
select *
from MASTER_OFFENCES_TIME_SERIES
where offence_category="ABDUCTION / KIDNAP";
quit;