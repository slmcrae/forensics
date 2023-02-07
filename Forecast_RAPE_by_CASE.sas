/*RAPE FORECAST BY CASE */
data monthly;
set work.rape_time_series_case;
dtotal=dif(total);
dutil=dif(utilization);
logutil=log(utilization);
dlogutil=dif(logutil);
boxcox_transform=((utilization**-0.5) - 1)/(-0.5);
dboxcox=dif(boxcox_transform);
run;

title "Month vs. PALM total";
proc sgplot data=monthly;
	series x=month y=total;
run;
title "Month vs. utilization";
proc sgplot data=monthly;
	series x=month y=utilization;
run;
title "Month vs. log(util)";
proc sgplot data=monthly;
	series x=month y=logutil;
run;
title "";
title "Box Cox tranformed utilization vs. month";
proc sgplot data=monthly;
	series x=month y=boxcox_transform;
run;
title "";
title "Month vs. dif(utilization)";
proc sgplot data=monthly;
	series x=month y=dutil;
run;
title "";

title "Dif(logutil) vs. Month";
proc sgplot data=monthly;
	series x=month y=dlogutil;
run;
title "";

title "dif(Box Cox tranformed utilization) vs. month";
proc sgplot data=monthly;
	series x=month y=dboxcox;
run;
title "";

ods graphics on;

title "Box Cox Lambda Test";
%boxcoxar(monthly, utilization);
title "";
ods graphics on;
   
title2 'Box Cox Lambda Test';
   
proc transreg data=monthly test plots=(transformation(dependent) observedbypredicted);
	model BoxCox(utilization/ alpha=0.05) = identity(month);
run;
/*
title "Utilization ARIMA model: scan";
proc arima data=monthly;
	identify var=utilization scan stationarity=(adf=1);
run;

title "Utilization ARIMA model: estimates";
proc arima data=monthly;
	identify var=logutil stationarity=(adf=1);
	estimate p=1 q=1;/*kernel not great, clear outliers in QQ, residuals white noise*
	estimate p=2 ;/*mu not sig, residuals FAIL*
	estimate p=3 q=1;/*none sig residuals great*
	estimate p=1;/*residuals fail, ar2 and 3 not sig*
	estimate q=1;/*total fail*
run;

title "Utilization ARIMA model: estimates";
proc arima data=monthly;
	identify var=utilization stationarity=(adf=1);
	estimate p=1 q=1;/*not normal, residuals great, AIC great*
	estimate p=2 ;/*residuals FAIL, not normal*
	estimate q=2;/*lag fail, not normal*
	estimate p=1;/*lag fail not normal*
	estimate q=1;/*total fail*
run;*/

title "Rape Utilization Model Forecast";
proc arima data=monthly plots=(residual(smooth)forecast(all));
	identify var=utilization(1) stationarity=(adf=2) minic;
	estimate q=1 noint outstat=rape_stat;
	outlier;
	forecast back=10 lead= 34 interval=month id=month out=rape_util_forecast;
run;

proc print data=rape_stat;
run;
/* Convert log values back to original *
data arson_util_forecast;
set arson_util_forecast;
utilization=exp(logutil);
L95 = exp( L95 );
U95 = exp( U95 );
FORECAST = exp(FORECAST + std*std/2);
run;
*/
proc print data=rape_util_forecast (firstobs=150);
run;
title "Rape Utilization Rates Forecast";
proc sgplot data=rape_util_forecast;
band x=month lower=L95 upper=U95;
series x=month y=FORECAST;
scatter x=month y=utilization;
refline '01Aug2018'd/ axis=x lineattrs=(pattern=20);
refline '01May2019'd/ axis=x lineattrs=(pattern=20);
run;
title "";
data rape_util_forecast;
set rape_util_forecast;
row=_n_;
run;
proc print data=rape_util_forecast;
run;

proc sql;
create table accuracy as
select *, abs((utilization-FORECAST)/utilization) as mape,
	(FORECAST-utilization)**2 as RMSE, count(*) as count
from rape_util_forecast
where utilization~=. AND FORECAST~=.;
quit;

proc print data=accuracy (obs=20);
run;

proc sql;
create table model_accuracy as
select (sum(mape)/(count-34))*100 as MAPE_SCORE, sqrt(sum(RMSE)/(count-34)) as RMSE_SCORE
from accuracy
where row<(count-34);
quit;


proc print data=model_accuracy (obs=1);
run;
/* nb: count is replaced with 10 in select row when forecast is for 10 */
proc sql;
create table forecast_accuracy as
select (sum(mape)/10)*100 as MAPE_SCORE, sqrt(sum(RMSE)/10) as RMSE_SCORE
from accuracy
where row>=(count-34) and row <(count-24) ;
quit;


proc print data=forecast_accuracy (obs=1);
run;
