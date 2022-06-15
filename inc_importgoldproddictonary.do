
clear
set more off
set linesize 100



*rename variables
import delimited using "$Productdic.txt", clear
drop v2 v12
rename _05 prodcode
rename v3 therapyev
rename v4 productname
rename v5 drugsubstance
rename v6 strength
rename v7 formulation
rename v8 route
rename v9 bnfcode
rename v10 bnfchapter
rename v11 build

sort prodcode


* Make all descriptions lower case
foreach var of varlist productname drugsubstance formulation route bnfchapter {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

order prodcode productname drugsubstance strength formulation route bnfcode bnfchapter build

