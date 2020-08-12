cap prog drop pr_getlastsbpvariability

program define pr_getlastsbpvariability 
syntax , clinicalfile(string) additionalfile(string)   index(string) runin(integer) [limitlow(string) limithigh(string)]

if "`limitlow'"=="" {
	local limitlow "0"
}

if "`limithigh'"=="" {
	local limithigh "."
}
preserve

use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
keep if variable=="sbp"
merge 1:m medcode using  `clinicalfile' , keep(match) nogen

replace adid = -_n if adid==0
rename value sbp
merge 1:1 patid adid using `additionalfile',  keep(match master)

replace sbp=data2 if data2!=.

drop if eventdate == .
drop if sbp==.
drop if sbp==1
drop if sbp >`limithigh'
drop if sbp <`limitlow'

*keep lowest sbp if more than one measurement on same day
keep patid eventdate sbp
duplicates tag patid eventdate, gen(dup)
bysort patid eventdate (sbp): keep if _n==1

keep patid eventdate sbp

tempfile sbprecs
save `sbprecs' , replace


restore
merge 1:m patid using `sbprecs' ,  keep(match master)
sort patid eventdate


*identify all sbp measurements recorded in the five years before study entry
gen _diff = `index' - eventdate
gen _sbp5yr = 1 if _diff < (365.25*5) & _diff >= 0
by patid: egen _countsbp5yr = count(_sbp5yr)

*calculate standard deviation where there are two or more recorded values
by patid: egen sbp_sd = sd(sbp) if _sbp5yr == 1 & _countsbp5yr >= 2
keep patid sbp_sd
keep if sbp_sd !=.
duplicates drop
isid patid

end

