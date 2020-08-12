cap prog drop pr_getlastsmokrec

program define pr_getlastsmokrec
syntax , clinicalfile(string) additionalfile(string)  smokingstatusvar(string) index(string) runin(integer)

preserve

*identify records in the clinial file using readcodes and generate clinical status
use "$QRiskCodelistdir\cr_codelist_qof_cod.dta", clear
keep if variable== "smoke_cat"
*NOTE: EH AMENDED 21/09/2018 - MEDCODE 54, Read code 137..00 "Tobacco consumption" is being removed from the code list as it does not indicate smoking status.
drop if medcode==54
merge 1:m medcode using `clinicalfile', keep(match) nogen

rename value clinstatus
label define clinstatuslab 0 "non-smoker" 1 "ex-smoker" 2 "light smoker" 3 "moderate smoker" 4 "heavy smoker" 234 "smoker amount unknown", replace
label values clinstatus clinstatuslab

*merge with additional file
*main medcodes associated with enttype that are not in the smoking code list = 54 tobacco consumption, 60 current non-smoker, 2111 health education - smoking, 7622 smoking cessation advice
replace adid = -_n if adid==0
merge 1:1 patid adid using `additionalfile'
drop if eventdate == .
drop if _merge == 2 & enttype !=4 /*drop additional files not found using codelist and not in the smoking entity type*/
replace clinstatus = . if _merge == 2
tab medcode _merge, m
tab clinstatus, m

*smoking status using additional clinical details file
gen adstatus = .
replace adstatus = 0 if data1 == 2
replace adstatus = 1 if data1 == 3
replace adstatus = 234 if data1 == 1
label values adstatus clinstatuslab

*update clinical and additional details status using cigarettes per day, where available
rename data2 cigsperday
replace cigsperday = 0 if cigsperday==0
replace cigsperday = 2 if cigsperday<10
replace cigsperday = 3 if cigsperday<20 & cigsperday>9
replace cigsperday = 4 if cigsperday>19 & cigsperday!=.
label values cigsperday clinstatuslab

foreach file in ad clin {
	replace `file'status=2 if inlist(`file'status,234,2,3,4)  & cigsperday==2
	replace `file'status=3 if inlist(`file'status,234,2,3,4) & cigsperday==3
	replace `file'status=4 if inlist(`file'status,234,2,3,4) & cigsperday==4
	gen `file's234 = 1 if `file'status==234
	replace `file'status=3 if `file'status==234 /*assume moderate smoker if no info*/
	*replace status=2 if status==1234
	}

*prioritise clinical status unless missing
tab clinstatus adstatus, m
gen status = clinstatus
replace status = adstatus if clinstatus == .
label values status clinstatuslab 
gen s234 = 1 if clins234 == 1
replace s234 = 1 if clinstatus == .

*duplicates
duplicates drop patid eventdate status, force
duplicates tag patid eventdate, gen(dup)
sort patid eventdate
by patid eventdate: egen counts234 = count(s234)
by patid eventdate: egen minstatus = min(status)
by patid eventdate: egen maxstatus = max(status)

drop if s234 == 1 & counts234 <= dup & dup> 0 & maxstatus > 2 & minstatus > 1 /*keep specified amount if imputed amount on same day*/
drop dup
duplicates tag patid eventdate, gen(dup)
drop if dup > 0 /*drop all remaining records with at least two different smoking status records on the same day*/

keep patid eventdate status

tempfile smokrecs
save `smokrecs' , replace

restore
merge 1:m patid using `smokrecs' ,  keep(match master)
sort patid eventdate
by patid: replace eventdate=. if _merge==3 & eventdate>`index' & _n==1
by patid: replace status=. if _merge==3 & eventdate>`index' & _n==1
drop if eventdate>`index' & _merge==3 & eventdate!=.

by patid: replace eventdate=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
by patid: replace status=. if _merge==3 & eventdate<`index'-365.25*`runin' & _n==_N
drop if eventdate<`index'-365.25*`runin' & _merge==3
gsort patid eventdate -status
by patid: keep if _n==_N

rename eventdate smok_date
rename status `smokingstatusvar'

end

