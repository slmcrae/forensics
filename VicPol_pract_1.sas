/* This is code to test SAS capabilities: */

libname testLib"/home/s31178890/ecprg193";

proc print data = testLib.qtr1_2007;
run;

proc sql;
create table deliveries as
select Order_ID, Order_Type, Customer_ID, (delivery_date - order_date) as delivery_time
from testLib.qtr1_2007
where Order_Type eq 1 or Order_Type eq 3
;
quit;

proc means data = deliveries;
var delivery_time;

run;

proc print data= deliveries;
where delivery_time > 2.5;
run;

proc means data = deliveries;
class Order_Type;
var delivery_time;
run;

proc ttest data = deliveries;
class Order_Type;
var delivery_time;
run;

proc ttest data = deliveries h0=3;
var delivery_time;
run;

/* SAS LOOPS */

/* This code creates a new column called total and specifies what it should contain. */
data donations;
   infile "/home/s31178890/ecprg193/donation.dat"; 
   input Employee_ID Qtr1 Qtr2 Qtr3 Qtr4;
   Total=sum(Qtr1,Qtr2,Qtr3,Qtr4);
run;

proc print data = donations;
run;
/* nods gives contents list without details of each dataset */
proc contents data = testLib._ALL_ nods;
run;

proc print data = testlib.customer_type;
run;

proc print data = customers;
run;

proc sql;
create table customers as
select 
(case when Customer_Type = "Orion Club members inactive" then "1010"
when Customer_Type = "Orion Club members low activity" then "1020"
when Customer_Type = "Orion  Club members medium activity" then "1030"
when Customer_Type = "Orion  Club members high activity" then "1040"
when Customer_Type = "Orion Club Gold members low activity" then "2010"
when Customer_Type = "Orion Club Gold members medium activity" then "2020"
when Customer_Type = "Orion Club Gold members high activity" then "2030"
when Customer_Type = "Internet/Catalog Customers" then "3010"
else ""
END) as Customer_Type_ID, *
from testLib.customer_dim;
QUIT;

proc sql;
create table Customer_Types as
select Customer_Type_ID
from customers;
QUIT;

proc print data = customers;
run;

proc univariate data = customers;
histogram Customer_Age;
run;

proc freq data = customers;
table Customer_Gender * Customer_Type_ID / norow nocol;
run;
