cap prog drop pr_getlast_btherapy

prog define pr_getlast_btherapy 
syntax , variable(string) therapyfile(string) index(string) time(string) /*runin(string)*/

/*Time = current: at least two prescriptions, with the most recent one being no more than 28 days
before the date of entry to the cohort
Time = ever: at least one prescription before index*/

preserve

*create temporary file with patids / event dates for all prescriptions of the specified drugs
use  "$QRiskCodelistdir\cr_codelist_`variable'" , clear
keep prodcode

merge 1:m prodcode using `therapyfile' , nogen keep(match) keepusing(patid eventdate sysdate)

replace eventdate=sysdate if eventdate==.
keep patid eventdate 
duplicates drop

tempfile ther_data
save `ther_data' , replace

*restore patient file to date and merge with prescription records
restore

merge 1:m patid using `ther_data', keep(match master)
sort patid eventdate

gen _everbeforeindex = 1 if eventdate <= `index'
by patid: egen _counteverbeforeindex = count(_everbeforeindex)

gen _28daywindow = 1 if eventdate <= `index' & (`index' - eventdate) <= 28
bysort patid: egen _count28daywindow = count(_28daywindow)

gen b_`variable' = 0
if "`time'" == "current" {
	replace b_`variable' = 1 if _counteverbeforeindex >= 2 & _count28daywindow >= 1
	}
if "`time'" == "ever" {
	replace b_`variable' = 1 if _counteverbeforeindex >= 1
	}
	
drop _* eventdate
duplicates drop


end


