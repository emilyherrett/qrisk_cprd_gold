cap prog drop pr_get_bclin

capture program drop pr_get_bclin
prog define pr_get_bclin
syntax , variable(string) qof(string) clinicalfile(string) referralfile(string) begin(string) end(string) runin(string) [wide]


preserve

*get all clinical and referral events matching code list
if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'.dta", clear
		}

merge 1:m medcode using `clinicalfile' , nogen keep(match)

tempfile temp
save `temp', replace

if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'.dta", clear
		}

merge 1:m medcode using `referralfile' , nogen keep(match)
append using `temp'

gen b_`variable'=1
keep patid eventdate b_`variable'
tempfile bclin
save `bclin' , replace

*merge with patient file
restore
merge 1:m patid using `bclin', keep(match master)

*keep first event within specified time table
drop if _merge==3 & eventdate>`end'
drop if _merge==3 & eventdate<`begin'-365.25*`runin'
gsort patid -eventdate
duplicates drop patid if eventdate<`begin' & _merge==3 , force

sort patid eventdate
by patid: keep if _n==1

replace b_`variable'=0 if b_`variable'==.

*add record for unexposed time between start of follow-up and first event
expand 2 if eventdate>`begin' & eventdate!=. & patid[_n]!=patid[_n-1]
sort patid eventdate
by patid: replace b_`variable'=0 if _n==1 & eventdate>`begin'
by patid: replace eventdate = `begin' if _n==1 & eventdate>`begin'

drop _merge
rename eventdate `variable'date

*HS - I'm not sure what this loop is meant to do but it doesn't run in this do file
if "`wide'"=="wide" {
by patid: gen b_clin_num=_n

reshape wide b_`variable' `variable'date, i(patid) j(b_clin_num)
}

end



