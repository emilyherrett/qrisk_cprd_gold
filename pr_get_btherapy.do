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

if "`time'" == "ever" {
	/*first eventdate for ever prescriptions*/
	sort patid eventdate
	by patid: keep if _n==1
	}

if "`time'" == "current" {
	/*all prescription records for current prescriptions*/
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
	}

tempfile treated
save `treated' , replace
	
/*merge with patient file, keep events within follow-up period*/
use `dataathand', clear

merge 1:m patid using `treated', keep(match master)

drop if _merge==3 & eventdate>`end'
drop if _merge==3 & eventdate<`begin'-365.25*`runin'
duplicates drop patid if eventdate<`begin' & _merge==3 , force

replace b_`variable'=0 if b_`variable'==.

/*create additional records for patients first prescribed hypertension treatment
 after the index rate, set eventdate to start of follow-up and b_hyp_diag to 0*/ 

sort patid eventdate
expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
sort patid eventdate
by patid: replace b_`variable'=0 if _n==1 & eventdate>`begin'
by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'

drop _merge
rename eventdate `variable'date

replace b_`variable'=0 if b_`variable'==.
sort patid `variabledate'

if "`wide'"=="wide" {
by patid: gen b_clin_num=_n

reshape wide b_`variable' `variable'date, i(patid) j(b_clin_num)
}

end


