# qrisk_cprd_gold
QRISK2 single index date and time-updating scores updated for CPRD GOLD, and QRISK3 single index date and time-updating versions complete for CPRD GOLD

•	Within these files is a set of programs designed to calculate QRISK2 2015 and QRISK3 2017 scores in CPRD GOLD data using Stata.

•	The programs collate data from a CPRD extract and identify all variables required for calculation of QRISK2 and QRISK3.  They calculate QRISK2 and QRISK3 scores for all patients, irrespective of missingness.

•	The main program file, which draws on the other folder contents, is pr_qrisk.do 

•	The bundle can calculate a one off score on the index date of your choice (single point QRISK), or can update each time one of its components is updated (time updating QRISK).

•	The aim was to try and replicate QRISK2 scores recorded in the data as closely as possible rather than to use best practice definitions of each score component.

•	See "QRISK bundle documentation_v2.0_08_04_20.docx" for a complete explanation of files.


**Note about cr_preparemodifiedqrisk_multipleimputation_FORGITHUB**
The do file uses multiple imputation to create 5 complete case datasets for QRISK3 predictor variables following the process described in Hippisley-Cox et al’s QRISK3 paper (1). The imputation model includes all predictor variables, age interaction terms, the Nelson-Aalen estimator for the baseline cumulative hazard, and the outcome indicator. Continuous variables are modelled using linear regression; fractional polynomials match the published QRISK3 equation, all variables are centred using the cohort means, variables that are not normally distributed are log transformed and the just another variable approach(2) is used to include interactions with age from the QRISK3 model. Rubin’s rules are used to combine the results across the imputed datasets.
 
1.          Hippisley-Cox J, Coupland C, Brindle P. Development and validation of QRISK3 risk prediction algorithms to estimate future risk of cardiovascular disease: prospective cohort study. BMJ. 2017 May 23;357:j2099.
2.          White IR, Royston P, Wood AM. Multiple imputation using chained equations: Issues and guidance for practice. Stat Med. 2011 Feb 20;30(4):377–99.
