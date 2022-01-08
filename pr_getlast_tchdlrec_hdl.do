cap prog drop pr_getlast_tchdlrec
program define pr_getlast_tchdlrec
syntax, testfile(string) index(string) runin(integer) [cutoff(string)]


if "`cutoff'"=="" {
	local cutoff "."
}

preserve

use `testfile' , clear

tab medcode if enttype == 338, sort
tab enttype if medcode==14371 | medcode==14372 | medcode==14108, sort

*14371 = 44IF.00 Serum cholesterol/HDL ratio
*14372 = 44PF.00 Total cholesterol:HDL ratio
*14108 = HDL: total cholesterol ratio
*NOT USING - 14369 = HDL: LDL ratio 

keep if medcode==14371 | medcode==14372 | medcode==14108
keep if data3==0 | data3==1 | data3==151 | data3==161
drop if data2>`cutoff'
drop if data2==0
rename data2 TC_HDLratio
rename eventdate TC_HDLdate
drop if TC_HDLdate == .

*HDL:LDL ratios recorded on same date
keep patid TC_HDLratio TC_HDLdate
duplicates drop
duplicates tag patid TC_HDLdate, gen(dup)
drop if dup > 0 /*Different lab tests on same day indicative of error?*/

keep patid TC_HDLratio TC_HDLdate
pause 
tempfile tempura
save `tempura' , replace
restore
merge 1:m patid using `tempura' ,  keep(match master)
pause
pause off
sort patid TC_HDLdate
by patid: replace TC_HDLdate=. if _merge==3 & TC_HDLdate>`index' & _n==1
by patid: replace TC_HDLratio=. if _merge==3 & TC_HDLdate>`index' & _n==1
drop if TC_HDLdate>`index' & _merge==3 & TC_HDLdate!=.

by patid: replace TC_HDLratio=. if TC_HDLdate<`index'-365.25*`runin' &  _merge==3 & _n==_N
by patid: replace TC_HDLdate=. if TC_HDLdate<`index'-365.25*`runin' &  _merge==3 & _n==_N
by patid: drop if TC_HDLdate<`index'-365.25*`runin' &  _merge==3 
sort patid TC_HDLdate TC_HDLratio
by patid: keep if _n==_N
drop _merge

end


