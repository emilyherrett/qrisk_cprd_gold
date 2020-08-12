cap prog drop pr_getbmiupdates

program define pr_getbmiupdates 
syntax , clinicalfile(string) additionalfile(string)   begin(string) end(string) runin(integer) [bmi_cutoff(string) wide]

preserve

use `clinicalfile' , clear
keep if medcode==2
tempfile tempest
save `tempest' , replace

use "$QRiskCodelistdir\cr_codelist_qof_cod", clear
keep if variable=="bmi"
merge 1:m medcode using  `clinicalfile' , keep(match) nogen

append using `tempest'

replace adid = -_n if adid==0
rename value bmi


merge 1:1 patid adid using `additionalfile'

tab enttype if _merge == 3
keep if enttype == 13
drop _merge

replace bmi=data3 if data3!=.
replace bmi=. if bmi>`bmi_cutoff'
drop if bmi==.

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
pause

restore
merge 1:m patid using `bmirecs' ,  keep(match master)
pause
rename eventdate bmidate
drop if (bmidate<`begin'-365.25*`runin' | bmidate>`end') & _merge==3
pause
gsort patid -bmidate
duplicates drop patid if bmidate<=`begin', force

sort patid bmidate
by patid: drop if bmi[_n-1]==bmi & _n>1

expand 2 if bmidate>`begin' & bmidate!=. & patid[_n]!=patid[_n-1]
sort patid bmidate
by patid: replace bmi=. if _n==1 & bmidate>`begin'
by patid: replace bmidate=`begin' if _n==1 & bmidate>`begin'



drop _merge
if "`wide'"=="wide" {
by patid: gen bmi_rec_num=_n

reshape wide bmi bmidate, i(patid) j(bmi_rec_num)
}

end

