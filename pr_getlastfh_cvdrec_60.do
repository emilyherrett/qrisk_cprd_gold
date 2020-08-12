cap prog drop pr_getlastfh_cvdrec
program define pr_getlastfh_cvdrec
syntax, clinicalfile(string) index(string) runin(integer)

preserve

use `clinicalfile' , clear
merge m:1 medcode using  "$QRiskCodelistdir\cr_codelist_fh_cvd_60" , nogen keep(match)
rename eventdate fh_date
keep fh_date patid

tempfile tempura
save `tempura' , replace

restore
merge 1:m patid using `tempura', keep(match master)

gen before=1 if   fh_date>`index' & _merge==3
sort patid before fh_date 
by patid: keep if _n==_N
drop _merge before

gen fh_cvd=1 if fh_date!=.
replace fh_cvd=0 if fh_cvd==. | fh_date<`index'-365.25*`runin'

end
