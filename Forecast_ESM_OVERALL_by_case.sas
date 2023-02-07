/* ESM forecasts by CASE */

ods graphics on;

proc sql;
create table overall as
select *, utilization+1 as pos_utilization
from work.overall_case
where month < '01May2019'd;
quit;

proc esm data=overall outfor=overall_forecast back=10 lead=34
	plot=all
	print=(estimates forecasts statistics performance);
	id month interval=month;
	forecast pos_utilization/ transform=log model=winters;
run;

proc esm data=work.burglary_agg_time_series_case outfor=burglary_agg_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=linear;
run;

proc esm data=work.drugs_poss_time_series_case outfor=drugs_poss_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=addwinters;
run;

proc esm data=work.burglary_res_time_series_case outfor=burglary_res_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=linear;
run;

proc esm data=work.homicide_time_series_case outfor=homicide_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=addwinters;
run;

proc esm data=work.theft_from_car_series_case outfor=theft_from_car_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=linear;
run;
proc sql;
create table drugs_cult as
select *, utilization+1 as pos_util_drugs
from work.drugs_cult_time_series_case;
quit;
proc esm data=drugs_cult outfor=drugs_cult_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast pos_util_drugs / transform=boxcox(0.5) model=addwinters;
run;

proc esm data=work.assault_time_series_case outfor=assault_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=addwinters;
run;

proc esm data=work.arson_time_series_case outfor=arson_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=linear;
run;

proc esm data=work.rape_time_series_case outfor=rape_esm back=10 lead=34
	plot=all
	print=(statistics performance);
	id month interval=month;
	forecast utilization/ model=linear;
run;

title "Manual Forecast plot";
proc sgplot data=arson_esm;
band x=month lower=lower upper=upper;
series x=month y=predict;
scatter x=month y=actual;
run;
title "";
