cap prog drop pr_getsbpupdates

program define pr_getsbpupdates
syntax , clinicalfile(string) additionalfile(string)  begin(string) end(string) runin(integer) [limitlow(string) limithigh(string)] [wide]

if "`limitlow'"=="" {
	local limitlow "0"
}

if "`limithigh'"=="" {
	local limithigh "."
}

preserve

use "$QRiskCodelistdir\cr_codelist_qof_cod", clear
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

keep patid eventdate sbp

*keep lowest sbp if more than one measurement on same day
keep patid eventdate sbp
duplicates tag patid eventdate, gen(dup)
bysort patid eventdate (sbp): keep if _n==1

tempfile sbprecs
save `sbprecs' , replace

restore
merge 1:m patid using `sbprecs' ,  keep(match master)

rename eventdate bpdate
drop if (bpdate<`begin'-365.25*`runin' | bpdate>`end') & _merge==3
gsort patid -bpdate
duplicates drop patid if bpdate<`begin', force

sort patid bpdate
by patid: drop if sbp[_n-1]==sbp & _n>1

expand 2 if bpdate>`begin' & bpdate!=. & patid[_n]!=patid[_n-1]
sort patid bpdate
by patid: replace sbp=. if _n==1 & bpdate>`begin'
by patid: replace bpdate=`begin' if _n==1 & bpdate>`begin'



drop _merge
if "`wide'"=="wide" {
by patid: gen sbp_rec_num=_n

reshape wide sbp bpdate, i(patid) j(sbp_rec_num)
}

end

