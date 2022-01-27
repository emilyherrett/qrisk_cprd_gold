capture log close
args sexstr sexval

assert "`sexstr'" == "male" | "`sexstr'" == "female"
assert `sexval' == 1 if "`sexstr'" == "male"
assert `sexval' == 2 if "`sexstr'" == "female"

log using "$Logdir\cr_multipleimputation_`sexstr'.txt", text replace

/*******************************************************************************
CREATE DATASET WITH IMPUTED VALUES FOR MISSING DATA
*******************************************************************************/


/*FROM QRISK3 PUBLICATION
- log transformed values for continuous variables that were not normally distributed 
- Five imputations were carried out
- In the imputation model we included all predictor variables, along with age interaction terms, the Nelson-Aalen estimator of the baseline cumulative hazard, and the outcome indicator. 
*/

use "$Datadir\xxx.dta", clear


keep if sex == `sexval'
count

*replace imputed values that were used to derive qrisk3 with missing values
foreach var in bmi sbp rati sbps5 {
	replace `var' = . if `var'_missing == 1
	}
replace smoke_cat = . if smoke_missing == 1
replace town = . if town == 0

*CATEGORISE ALL CONTINUOUS VARIABLES
local missingvars_c "sbp rati sbps5 town"
local missingvars_fp "bmi_1 bmi_2"
local completevars_fp "age_1 age_2"

/*FROM QRISK3 PUBLICATION
Fractional polynomials35 were used to model non-linear risk relations with 
continuous variables using data from patients with recorded values to derive the
 fractional polynomial terms. FPs below copied from QRISK equation
*/

summ ageindex, d
summ bmi, d

if "`sexstr'" == "female" {
	gen double dage = ageindex
	replace dage=dage/10
	gen double age_1 = dage^(-2)
	gen double age_2 = dage
	gen double dbmi = bmi
	replace dbmi=dbmi/10
	gen double bmi_1 = dbmi^(-2)
	gen double bmi_2 = ln(dbmi)*dbmi^(-2)
	}

if "`sexstr'" == "male" {
	gen double dage = ageindex
	replace dage=dage/10
	gen double age_1 = dage^(-1)
	gen double age_2 = dage^3
	gen double dbmi = bmi
	replace dbmi=dbmi/10
	gen double bmi_2 = ln(dbmi)*dbmi^(-2)
	gen double bmi_1 = dbmi^(-2)
	}
	
summ age_1, d
summ age_2, d
summ bmi_1, d
summ bmi_2, d


/* Centring the continuous variables - using cohort means*/

local cvars "`missingvars_c' `missingvars_fp' `completevars_fp'"

foreach var of local cvars {
	qui summ `var'
	replace `var' = `var' - `r(mean)'
	summ `var', d
	}


/*explore missingness*/
misstable summarize smoke_cat `missingvars_c' `missingvars_fp', gen(M_)
misstable patterns

/*LOG TRANSFORM CONTINUOUS VARIABLES that are not normally distributed in line
with QRISK approach - REGRESSION APPROACH ONLY*/
/*I haven't included fractional polynomial terms*/

/*CHANGE*/
*local missingvars_candageint = "`missingvars_c' `ageinteracvars_out_miss_c' "
*local missingvars_candageint = "`missingvars_c'"


local logmissingvars_c = ""
foreach var of local missingvars_c {
	summarize `var', d
	gen log`var' = log(`var')
	local logmissingvars_c = "`logmissingvars_c' log`var'"
	*qnorm `var', title(`var')
	}
sktest `missingvars_c'
sktest `logmissingvars_c'
}


/*AGE INTERACTIONS
USING JUST ANOTHER VARIABLE APPROACH including interactions with age that are included in the final QRISK3 model
Note - values for derived variables will be implausible at original var and interaction imputed separately
(see https://onlinelibrary.wiley.com/doi/full/10.1002/sim.4067
and https://onlinelibrary.wiley.com/doi/full/10.1002/sim.4067 = supp appendix with stata code for the above

footnote tables 3 and 4 QRISK3 paper: interactions with age for body mass index, 
systolic blood pressure, Townsend score, family history of coronary heart disease, 
treated hypertension, atrial fibrillation, type 1 diabetes, type 2 diabetes, 
chronic kidney disease, and smoking status.

plus additional age interactions for: migraine, corticosteroid use, and erectile dysfunction.
*/

local ageinteracvars_in_miss_c "sbp town" /*no interactions for rati and sbps5*/
local ageinteracvars_in_miss_fp "`missingvars_fp'"
local ageinteracvars_in_reg "fh_cvd b_treatedhyp b_AF b_type1 b_type2 b_renal b_migraine b_corticosteroids"
if "`sexstr'" == "male" local ageinteracvars_in_reg "`ageinteracvars_in_reg' b_impotence2"

foreach vartype in miss_c miss_fp reg {
	di "`vartype'"
	local ageinteracvars_out_`vartype' ""
	foreach var of local ageinteracvars_in_`vartype' {
		di "`var'"
		gen age1`var' = age_1 * `var'
		gen age2`var' = age_2 * `var'
		local ageinteracvars_out_`vartype' "`ageinteracvars_out_`vartype'' age1`var' age2`var'"
		}
	}


di "`ageinteracvars_out_miss_c'"
di "`ageinteracvars_out_logmiss_c'"
di "`ageinteracvars_out_miss_fp'"
di "`ageinteracvars_out_reg'"

*log interactions for continuous vars?
local logageinteracvars_out_miss_c ""
foreach var of local ageinteracvars_out_miss_c {
	gen log`var' = log(`var')
	local logageinteracvars_out_miss_c "`logageinteracvars_out_miss_c' log`var'"
	}
	
di "`logageinteracvars_out_miss_c'"

*Smoke_cat multiply by the indicators that go into the model - generate using the XI command

local ageinteracvars_out_miss_smok ""
forvalues x = 1/2 {
	xi i.smoke_cat*age_`x'
	forvalues i = 1/4 {
		rename _IsmoXage_`x'_`i' age`x'smo`i' /*without this, Stata removes age1 interaction terms
		when age2 interaction terms are created*/
		local ageinteracvars_out_miss_smok "`ageinteracvars_out_miss_smok' age`x'smo`i'"
		}
	}

di "`ageinteracvars_out_miss_smok'"

count
save "$Datadir\cr_preparemodifiedqrisk_multipleimputation_`sexstr'_beforeimputation.dta", replace

	

*nelson-aalen estimator of the baseline hazard function
sts gen na = na
summ na, d

*outcome indicator = _d - added directly below
*= CVD (fatal or nonfatal)
	
local imputvars_c "`logmissingvars_c' `missingvars_fp' `logageinteracvars_out_miss_c' `ageinteracvars_out_miss_fp' `ageinteracvars_out_miss_smok' "
di "`imputvars_c'"
	
local predvars "age_1 age_2 fh_cvd b_treatedhyp b_type1 b_type2 b_ra b_AF"
local predvars "`predvars' b_renal b_migraine b_sle b_semi b_hiv b_atypicalantipsy"
local predvars "`predvars' b_corticosteroids na _d `ageinteracvars_out_reg'" 
if "`sexstr'" == "male" local predvars "`predvars' b_impotence2"


/*add ethrisk within mi register and i.ethrisk in mi impute.*/

mi set flong
/*register variables for imputation*/
mi register imputed `imputvars_c' smoke_cat
/*register predictor variables with complete data as regular*/
mi register regular `predvars' ethrisk
mi register passive `missingvars_c' `ageinteracvars_out_miss_c'


/*run MICE*/
mi impute chained ///
(regress) `imputvars_c' ///
(mlogit) smoke_cat ///
 = `predvars' i.ethrisk , ///
noisily add(5) chaindots rseed(50256) augment /*dryrun*/
	
/*back transform transformed variables in each imputed dataset*/
foreach var of local missingvars_c {
	mi passive: replace `var' = exp(log`var')
	}
		
foreach var of local ageinteracvars_out_miss_c {
	mi passive: replace `var' = exp(log`var')
	}
	
}

	

save "$Datadir\cr_multipleimputation_`sexstr'.dta", replace

capture log close

