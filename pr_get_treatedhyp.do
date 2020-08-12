cap prog drop pr_get_treatedhyp

prog define pr_get_treatedhyp 
syntax , therapyfile(string) clinicalfile(string) referralfile(string) begin(string) end(string) runin(string) commondosage(string) [wide]

tempfile dataathand
save `dataathand' , replace

*identify clinical and referral hypertension records
use  "$QRiskCodelistdir\cr_codelist_qof_cod.dta" , clear

keep if variable=="b_treatedhyp"

merge 1:m medcode using `clinicalfile' , nogen keep(match)

tempfile temp
save `temp', replace

use  "$QRiskCodelistdir\cr_codelist_qof_cod.dta" , clear

keep if variable=="b_treatedhyp"

merge 1:m medcode using `referralfile' , nogen keep(match)
append using `temp'

gen b_hyp_diag=1
keep patid eventdate b_hyp_diag
tempfile hyp_diag
save `hyp_diag' , replace

/*merge with patient file, keep hypertension records within specified
time window, and single record for patients with no hypertension records in this
period*/
use `dataathand' , clear

merge 1:m patid using `hyp_diag', keep(match master)

drop if _merge==3 & eventdate>`end'
drop if _merge==3 & eventdate<`begin'-365.25*`runin'
gsort patid -eventdate
duplicates drop patid if eventdate<`begin' & _merge==3 , force


sort patid eventdate
by patid: keep if _n==1

replace b_hyp_diag=0 if b_hyp_diag==.

/*create additional records for patients diagnosed with hypertension after the index rate,
set eventdate to start of follow-up and b_hyp_diag to 0*/
expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
sort patid eventdate
by patid: replace b_hyp_diag=0 if _n==1 & eventdate>`begin'
by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'

drop _merge
rename eventdate treatedhypdate

tempfile hypdiags
save `hypdiags' , replace

/*TREATMENT*/

*Identify hypertension treatment records, event date and runoutdate
use "$QRiskCodelistdir\cr_codelist_antihypertensives.dta", clear
keep prodcode

merge 1:m prodcode using `therapyfile' , nogen keep(match)

replace eventdate=sysdate if eventdate==.

*merge with common dosages file if not already complete in raw data
if "`commondosage'" != "merged" {
	merge m:1 dosageid using "$QRiskCodelistdir\common_dosages_`commondosage'.dta"
	drop if _merge==2
	}

keep patid eventdate daily_dose numdays qty

replace numdays=qty/daily_dose if numdays==0 & qty!=. & daily_dose!=. & qty!=0 & daily_dose!=0
replace numdays=qty if numdays==0 & (daily_dose==0 | daily_dose==.) & qty!=0 & qty!=.
replace numdays=28 if numdays==0

drop daily_dose qty

sort patid eventdate

gen runoutdate=eventdate+numdays

gen b_treatedhyp=1 

/*create an additional record for time between prescriptions where eventdate is 
the runout date of the previous record and b_treated hyp is 0
*/
gen order = _n

expand 2 if runoutdate<eventdate[_n+1] & patid==patid[_n+1]

sort order

by order: replace eventdate=runoutdate if _n==2

by order: replace b_treatedhyp=0 if _n==2

drop runoutdate numdays order
tempfile treatedhyp
save `treatedhyp' , replace

/*merge with patient file, keep events within follow-up period*/
use `dataathand' , clear

merge 1:m patid using `treatedhyp', keep(match master)

drop if _merge==3 & eventdate>`end'
drop if _merge==3 & eventdate<`begin'-365.25*`runin'
duplicates drop patid if eventdate<`begin' & _merge==3 , force

replace b_treatedhyp=0 if b_treatedhyp==.

/*create additional records for patients first prescribed hypertension treatment
 after the index rate, set eventdate to start of follow-up and b_hyp_diag to 0*/ 
 
sort patid eventdate
expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
sort patid eventdate
by patid: replace b_treatedhyp=0 if _n==1 & eventdate>`begin'
by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'


drop _merge
rename eventdate treatedhypdate

/*APPEND HYPERTENSION DIAGNOSIS AND TREATMENT DATA*/
append using `hypdiags' 

/*b_hyp_diag = value for previous record for treatment records
b_treatedhyp = value for previous record for diagnostic records*/
sort patid treatedhypdate
by patid: replace b_hyp_diag=b_hyp_diag[_n-1] if b_hyp_diag==. & _n>1
by patid: replace b_treatedhyp=b_treatedhyp[_n-1] if b_treatedhyp==. & _n>1

/*final b_treatedhyp variable*/
gen treated = 1 if b_hyp_diag==1 & b_treatedhyp==1
replace treated=0 if treated!=1

rename b_treatedhyp b_bp_treatment
rename treated b_treatedhyp
replace b_bp_treatment=0 if b_bp_treatment==.
replace b_hyp_diag=0 if b_hyp_diag==.
duplicates drop

if "`wide'"=="wide" {
by patid: gen smok_rec_num=_n

reshape wide b_treatedhyp treatedhypdate, i(patid) j(smok_rec_num)
}

sort patid treatedhypdate
by patid: drop if b_treatedhyp[_n-1]==b_treatedhyp & b_bp_treatment[_n-1]==b_bp_treatment & b_hyp_diag[_n-1]==b_hyp_diag & _n>1

end



