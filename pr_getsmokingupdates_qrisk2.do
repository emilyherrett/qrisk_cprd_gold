cap prog drop pr_getsmokingupdates

program define pr_getsmokingupdates 
syntax , clinicalfile(string) additionalfile(string)  smokingstatusvar(string) begin(string) end(string) runin(integer) [wide]

preserve

use "$QRiskCodelistdir\cr_codelist_qof_cod", clear
keep if variable== "smoke_cat"
*NOTE: EH AMENDED 21/09/2018 - MEDCODE 54, Read code 137..00 "Tobacco consumption" is being removed from the code list as it does not indicate smoking status.
drop if medcode==54
merge 1:m medcode using  `clinicalfile' , keep(match) nogen

replace adid = -_n if adid==0
rename value status
merge 1:1 patid adid using `additionalfile',  keep(match master)
rename data2 cigsperday
replace status=2 if status==2 & cigsperday<10
replace status=3 if status==2 & cigsperday<20 & cigsperday>9
replace status=4 if status==2 & cigsperday>19 & cigsperday!=.

replace status=3 if status==234
replace status=2 if status==1234

keep patid eventdate status

tempfile smokrecs
save `smokrecs' , replace

restore
merge 1:m patid using `smokrecs' ,  keep(match master)

rename eventdate smoke_update
drop if (smoke_update<`begin'-365.25*`runin' | smoke_update>`end') & _merge==3
gsort patid -smoke_update
duplicates drop patid if smoke_update<`begin', force

sort patid smoke_update
by patid: drop if status[_n-1]==status & _n>1

expand 2 if smoke_update>`begin' & smoke_update!=. & patid[_n]!=patid[_n-1]
sort patid smoke_update
by patid: replace status=. if _n==1 & smoke_update>`begin'
by patid: replace smoke_update=`begin' if _n==1 & smoke_update>`begin'

rename status `smokingstatusvar'
drop _merge
if "`wide'"=="wide" {
by patid: gen smok_rec_num=_n

reshape wide `smokingstatusvar' smoke_update, i(patid) j(smok_rec_num)
}

end

