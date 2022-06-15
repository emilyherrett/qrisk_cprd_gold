clear
capture set more off

global database "GOLD"
global version "2018_07"

if "$database" == "GOLD" {
	global Dictionarydir "J:\EHR Share\3 Database guidelines and info\GPRD_Gold\Medical & Product Browsers\\${version}_Browsers"
	global Productdic "$Dictionarydir\product"
	global Medicaldic "$Dictionarydir\medical"
	}

global Projectdir "J:\EHR-Working\QRISK\qrisk_bundle\codelists\codelist_creation"

global Dodir "$Projectdir\dofiles"
global Logdir "$Projectdir\logfiles\\${database} ${version}"
global Datadir "$Projectdir\datafiles\\${database} ${version}"
global Textdir "$Projectdir\textfiles\\${database} ${version}"
global Sourcedir "$Projectdir\sourcefiles\\"

