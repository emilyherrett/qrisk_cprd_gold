cap prog drop pr_get_btherapy

prog define pr_get_btherapy 
syntax , variable(string) therapyfile(string) begin(string) end(string) runin(string) time(string) [wide]

/*Time = current: at least two prescriptions, with the most recent one being no more than 28 days
before the date of entry to the cohort
Time = ever: at least one prescription before index*/

tempfile dataathand
save `dataathand' , replace

/*identify all prescriptions of specified drugs*/
use  "$QRiskCodelistdir\cr_codelist_`variable'" , clear
keep prodcode

merge 1:m prodcode using `therapyfile' , nogen keep(match) keepusing(patid eventdate sysdate)

replace eventdate=sysdate if eventdate==.
keep patid eventdate 
duplicates drop

gen b_`variable'=1

tempfile treated
save `treated' , replace

/*merge with patient file, keep events within follow-up period*/
use `dataathand', clear

merge 1:m patid using `treated', keep(match master)

drop if _merge==3 & eventdate>`end'
drop if _merge==3 & eventdate<`begin'-365.25*`runin'

sort patid eventdate

if "`time'" == "ever" {
	/*first eventdate for ever prescriptions*/
	by patid: keep if _n==1
	
	/*create additional records for patients first prescribed treatment
	after the index date, set eventdate to start of follow-up and variable to 0*/ 
	sort patid eventdate
	expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
	sort patid eventdate
	by patid: replace b_`variable'=0 if _n==1 & eventdate>`begin'
	by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'
	}

if "`time'" == "current" {
	/*only keep one pre-baseline record, marked as whether or not 
	meets criteria of current treatment (at least 2 prior prescriptions 
	with most recent no more than 28 days)*/
	gen _28daywindow=1 if eventdate<=`begin' & (`begin'-eventdate) <=28
	by patid: egen _count28daywindow = count(_28daywindow)
	gen _everbeforeindex=1 if eventdate<=`begin'
	by patid: egen _counteverbeforeindex=count(_everbeforeindex)
	replace b_`variable'=0 if (_counteverbeforeindex<2 | _count28daywindow<1) & eventdate<=`begin'
	gen before=1 if eventdate<`begin'
	sort patid before
	by patid before: drop if _n!=_N & before==1
	drop _28daywindow _count28daywindow _everbeforeindex _counteverbeforeindex
	preserve
	keep if before==1
	drop before
	tempfile treatbefore
	save `treatbefore' , replace
	restore
	
	/*all prescription records for current prescriptions after baseline*/
	drop if before==1
	drop before
	gen runoutdate=eventdate+28
	format runoutdate %td
	sort patid eventdate
	gen order = _n
	/*create an additional record for time between prescriptions where eventdate is 
	the runout date of the previous record and b_`variable' is 0
	*/
	expand 2 if runoutdate<eventdate[_n+1] & patid==patid[_n+1]
	sort order
	by order: replace eventdate=runoutdate if _n==2
	by order: replace b_`variable'=0 if _n==2
	drop runoutdate order
	
	/*add in records for patients first prescribed treatment before index date*/
	append using "`treatbefore'"
	
	/*create additional records for patients first prescribed hypertension treatment
	after the index rate, set eventdate to start of follow-up and b_hyp_diag to 0*/ 
	sort patid eventdate
	expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
	sort patid eventdate
	by patid: replace b_`variable'=0 if _n==1 & eventdate>`begin'
	by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'
	}

drop _merge
rename eventdate `variable'date

replace b_`variable'=0 if b_`variable'==.
sort patid `variabledate'

end


