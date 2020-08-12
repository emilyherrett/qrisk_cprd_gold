cap prog drop pr_get_ED

prog define pr_get_ED 
syntax , clinicalfile(string) referralfile(string) therapyfile(string) begin(string) end(string) runin(string) [wide]

preserve
*first ever diagnosis code
pr_get_bclin, variable(ED) qof(notqof) clinicalfile(`clinicalfile') referralfile(`referralfile') begin(`begin') end(`end') runin(`runin')

tempfile b_ED
save `b_ED', replace

restore
*first ever treatment
pr_get_btherapy, variable(ED_drugs) therapyfile(`therapyfile') begin(`begin') end(`end') runin(`runin') time(ever)

append using `b_ED'

*first of either diagnosis or treatment
replace EDdate = ED_drugsdate if EDdate == .
assert EDdate !=.

replace b_ED = b_ED_drugs if b_ED == .
assert b_ED !=.

drop ED_drugs b_ED_drugs
bysort patid EDdate: keep if _n==1

end
