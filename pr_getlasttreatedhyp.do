cap prog drop pr_getlasttreatedhyp

prog define pr_getlasttreatedhyp 
syntax , therapyfile(string) clinicalfile(string) referralfile(string) index(string) runin(string) commondosage(string)

*updated 2019 to account for CPRD no longer providing ndd - instead use doseageid lookup
preserve
use  "$QRiskCodelistdir\cr_codelist_qof_cod" , clear

keep if variable=="b_treatedhyp"

merge 1:m medcode using `clinicalfile' , nogen keep(match)

tempfile temp
save `temp', replace

use "$QRiskCodelistdir\cr_codelist_qof_cod", clear

keep if variable=="b_treatedhyp"

merge 1:m medcode using `referralfile' , nogen keep(match)
append using `temp'

gen b_hyp_diag=1
keep patid eventdate b_hyp_diag
tempfile hyp_diag
save `hyp_diag' , replace

restore

merge 1:m patid using `hyp_diag', keep(match master)
sort patid eventdate
by patid: replace eventdate=. if _merge==3 & eventdate>`index' & _n==1
by patid: replace b_hyp_diag=. if _merge==3 & eventdate>`index' & _n==1
drop if _merge==3 & eventdate>`index' & eventdate!=.

by patid: replace eventdate=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
by patid: replace b_hyp_diag=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
 drop if _merge==3 & eventdate<`index'-365.25*`runin' 
gsort patid -eventdate b_hyp_diag
count if  _merge==3 
if `r(N)'>0 {
duplicates drop patid if  _merge==3 , force
}

replace b_hyp_diag=0 if b_hyp_diag==.

drop _merge 
rename eventdate hyp_diag_date

/*get whether on prescription*/

preserve
use "$QRiskCodelistdir\cr_codelist_antihypertensives.dta", clear
keep prodcode

/*creates file with eventdate and b_treatedhype variables, 
b_treatedhype = 1 for each prescription and 0 at the end of prescriptions if 
there is a gap between two prescriptions*/
merge 1:m prodcode using `therapyfile' , nogen keep(match)
*merge 1:m prodcode using "Z:\GPRD_GOLD\Emily\qrisk2_test\Therapy_extract_qrisk2_test_1.dta", nogen keep(match)
replace eventdate=sysdate if eventdate==.

*merge with common dosages file if not already complete in raw data
if "`commondosage'" != "merged" {
	merge m:1 dosageid using "$QRiskCodelistdir\common_dosages_`commondosage'.dta"
	drop if _merge==2
	}
	
keep patid eventdate daily_dose numdays qty
replace numdays=qty/daily_dose if numdays==0 & qty!=. & daily_dose!=. & qty!=0 & daily_dose!=0
replace numdays=28 if numdays==0
drop daily_dose qty

sort patid eventdate
gen runoutdate=eventdate+numdays
gen b_treatedhyp=1 
gen order = _n
expand 2 if runoutdate<eventdate[_n+1] & patid==patid[_n+1]
sort order
by order: replace eventdate=runoutdate if _n==2
by order: replace b_treatedhyp=0 if _n==2
drop runoutdate numdays order
tempfile treatedhyp
save `treatedhyp' , replace

restore

merge 1:m patid using `treatedhyp', keep(match master)
/*retains nearest record before index period and after run in period or single row
with missing event date abd b_treatedhyp if there are no records within this period*/
pause
sort patid eventdate
by patid: replace eventdate=. if _merge==3 & eventdate>`index' & _n==1
by patid: replace b_treatedhyp=. if _merge==3 & eventdate>`index' & _n==1
drop if _merge==3 & eventdate>`index' & eventdate!=.
pause
by patid: replace eventdate=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
pause
by patid: replace b_treatedhyp=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
pause
 drop if _merge==3 & eventdate<`index'-365.25*`runin'
 pause
gsort patid -eventdate b_treatedhyp
count if  _merge==3 
if `r(N)'>0 {
duplicates drop patid if  _merge==3 , force
}
pause
*replaces missing b_treatedhyp with 0
replace b_treatedhyp=0 if b_treatedhyp==.

gen treated=1 if b_treatedhyp==1 & b_hyp_diag==1
replace treated=0 if treated!=1
drop b_treatedhyp b_hyp_diag
rename treated b_treatedhyp

drop _merge
rename eventdate treatedhypdate









end


