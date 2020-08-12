cap prog drop pr_getlastbmi

program define pr_getlastbmi 
syntax , clinicalfile(string) additionalfile(string)   index(string) runin(integer) bmi_cutoff(string)

preserve

use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
keep if variable=="bmi"
merge 1:m medcode using  `clinicalfile' , keep(2 3)
keep if _merge == 3 | medcode == 2
drop _merge

replace adid = -_n if adid==0
rename value bmi
merge 1:1 patid adid using `additionalfile' 

tab enttype if _merge == 3 /*all entype 13 except 6 out of 720 552 observations in test dataset*/
keep if enttype == 13
drop _merge
drop if eventdate == . /*drop is event date is missing*/

replace bmi=data3 if data3!=.

replace bmi=. if bmi>`bmi_cutoff'
replace bmi=. if bmi<10

*use average bmi if more than one measurement on same day and <= 5kg/m2 difference
duplicates tag patid eventdate, gen(dup)
sort patid eventdate
by patid eventdate: egen minbmi = min(bmi)
by patid eventdate: egen maxbmi = max(bmi)
by patid eventdate: egen avbmi = mean(bmi)
gen diff = maxbmi - minbmi
drop if diff > 5
replace bmi = avbmi if dup > 0

keep patid eventdate bmi

tempfile bmirecs
save `bmirecs' , replace


restore
merge 1:m patid using `bmirecs' ,  keep(match master)
sort patid eventdate
by patid: replace eventdate=. if _merge==3 & eventdate>`index' & _n==1
by patid: replace bmi=. if _merge==3 & eventdate>`index' & _n==1
drop if eventdate>`index' & _merge==3 & eventdate!=.

by patid: replace eventdate=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
by patid: replace bmi=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
drop if eventdate<`index'-365.25*`runin' &  _merge==3
gsort patid eventdate bmi
by patid: keep if _n==_N
rename eventdate bmidate


end

