import delimited using "$Medicaldic.txt", clear

drop in 1

rename _05 medcode
rename v2 readcode
rename v3 clinev
rename v4 immunev
rename v5 refev
rename v6 testev
rename v7 readterm
rename v8 build

sort medcode


* Make all descriptions lower case
foreach var of varlist readterm {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

