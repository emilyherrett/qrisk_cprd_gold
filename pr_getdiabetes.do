cap prog drop pr_get_diabetes

capture program drop pr_get_diabetes
prog define pr_get_diabetes
syntax , clinicalfile(string) referralfile(string) begin(string) end(string) runin(string) [wide]


preserve

*get all clinical and referral events matching code list
use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
keep if variable == "b_type1" | variable == "b_type2"

merge 1:m medcode using `clinicalfile' , nogen keep(match)

tempfile temp
save `temp', replace

use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
keep if variable == "b_type1" | variable == "b_type2"

merge 1:m medcode using `referralfile' , nogen keep(match)
append using `temp'

gen diabetes = 1 if variable == "b_type1"
replace diabetes = 2 if variable == "b_type2"
keep patid eventdate diabetes

tempfile bdiab
save `bdiab' , replace

*merge with patient file
restore
merge 1:m patid using `bdiab', keep(match master)

*keep records within specified timetable
drop if _merge==3 & eventdate>`end'
drop if _merge==3 & eventdate<`begin'-365.25*`runin'
gsort patid -eventdate
duplicates drop patid if eventdate<`begin' & _merge==3 , force

sort patid eventdate
*by patid: keep if _n==1

replace diabetes=0 if diab==.

*if sequential records are for the same diabetes type, keep the first record
by patid: gen drop = 1 if patid[_n]==patid[_n-1] & diab[_n] == diab[_n-1]
drop if drop == 1
drop drop

*add record for unexposed time between start of follow-up and first event
expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
sort patid eventdate
by patid: replace diab=0 if _n==1 & eventdate>`begin'
by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'

/*at each record, set the recorded type to 1 and the other to 0
i.e. diabetes is defined by the latest record and patients cannot have
type 1 and type 2 diabetes at the same time*/
gen b_type1 = 0
gen b_type2 = 0
replace b_type1 = 1 if diab == 1
replace b_type2 = 1 if diab == 2

gen type1date = eventdate
gen type2date = eventdate
format type1date type2date %dD/N/CY
drop eventdate diabetes

if "`wide'"=="wide" {
by patid: gen b_clin_num=_n

reshape wide b_`variable' `variable'date, i(patid) j(b_clin_num)
}

end



