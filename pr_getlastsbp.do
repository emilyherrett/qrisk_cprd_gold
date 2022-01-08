cap prog drop pr_getlastsbp

program define pr_getlastsbp 
syntax , clinicalfile(string) additionalfile(string) index(string) runin(integer) [limitlow(string) limithigh(string)]

if "`limitlow'"=="" {
	local limitlow "0"
}

if "`limithigh'"=="" {
	local limithigh "."
}
preserve

use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
keep if variable=="sbp"
merge 1:m medcode using `clinicalfile', keep(match) nogen

replace adid = -_n if adid==0
rename value sbp
merge 1:1 patid adid using `additionalfile'
count if _merge == 2 & enttype == 1 /*tiny fraction of additional records not captured through code list
- mainly diastolic bp codes and 24 hour blood pressure reading code*/
summ data2 if _merge == 3 & data2 !=0, d /*very few of the above values are within the normal range - ok to drop*/
drop if _merge == 2
drop _merge

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

tempfile sbprecs
save `sbprecs' , replace


restore
merge 1:m patid using `sbprecs' ,  keep(match master)

sort patid eventdate

*if first sbp record is after index, sets sbp and eventdate to missing for this record
by patid: replace eventdate=. if _merge==3 & eventdate>`index' & _n==1
by patid: replace sbp=. if _merge==3 & eventdate>`index' & _n==1

*drop remaining eventdates that are after the indexdate
drop if eventdate>`index' & _merge==3 & eventdate!=.

*if last sbp is before the run in period, sets sbp and eventdate to missing for this record
by patid: replace sbp=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
by patid: replace eventdate=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N

*drop remaining eventdates that are before the run in period
drop if _merge==3 & eventdate<`index'-365.25*`runin' 

*keeps last event of sbp records that are within the specified period (i.e. event nearest to index)
gsort patid -eventdate sbp
count if  _merge==3 
if `r(N)'>0 {
duplicates drop patid if  _merge==3 , force
}

rename eventdate bpdate


end

