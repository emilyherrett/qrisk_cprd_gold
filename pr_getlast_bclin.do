cap prog drop pr_getlast_bclin

prog define pr_getlast_bclin 
syntax , variable(string) qof(string) clinicalfile(string) referralfile(string) index(string) runin(string)

pause

preserve
if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'.dta", clear
		}
pause
merge 1:m medcode using `clinicalfile' , nogen keep(match)
pause

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
tempfile tempclinb
save `tempclinb' , replace
pause

restore
pause 
merge 1:m patid using `tempclinb', keep(match master)
pause
sort patid eventdate
by patid: replace eventdate=. if _merge==3 & eventdate>`index' & _n==1
by patid: replace b_`variable'=. if _merge==3 & eventdate>`index' & _n==1
drop if _merge==3 & eventdate>`index' & eventdate!=.

by patid: replace b_`variable'=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
by patid: replace eventdate=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
drop if _merge==3 & eventdate<`index'-365.25*`runin'
gsort patid -eventdate
count if  _merge==3 
if `r(N)'>0 {
duplicates drop patid if  _merge==3 , force
}
replace b_`variable'=0 if b_`variable'==.

drop _merge
rename eventdate `variable'date

end


