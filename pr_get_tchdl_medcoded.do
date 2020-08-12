cap prog drop pr_get_tchdl_updates
program define pr_get_tchdl_updates
syntax, testfile(string) begin(string) end(string) runin(integer) [wide cutoff(string)]

if "`cutoff'"=="" {
	local cutoff "."
}

preserve

use `testfile' , clear

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
tempfile tempura
save `tempura' , replace
restore
merge 1:m patid using `tempura' , nogen keep(match master)

drop if (TC_HDLdate<`begin'-365.25*`runin' | TC_HDLdate>`end') & TC_HDLdate!=.
gsort patid -TC_HDLdate
duplicates drop patid if TC_HDLdate<`begin', force

sort patid TC_HDLdate TC_HDLratio
expand 2 if TC_HDLdate>`begin' & TC_HDLdate!=. & patid[_n]!=patid[_n-1]
sort patid TC_HDLdate
by patid: replace TC_HDLratio=. if _n==1 & TC_HDLdate>`begin'
by patid: replace TC_HDLdate=`begin' if _n==1 & TC_HDLdate>`begin'


if "`wide'"=="wide" {
by patid: gen TC_HDLnum=_n
reshape wide TC_HDLratio TC_HDLdate, i(patid) j(TC_HDLnum)
}


end


