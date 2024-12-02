*do file to prepare survey and census data for poverty mapping
**Before running the codes, make sure you install the following packages
/*
ssc install sae
ssc install groupfunction
*/

*You also need to copy and paste fhsae.ado and sp_groupfunction.ado to your folders ado/plus/f and ado/plus/s, respectively, to run the rest of the codes.
********************************************************************************
*This dofile does the following:
/*
1) Prepare PECS2023 and census data for SAE
2) Compute direct estimates of poverty and std. errors
*/
********************************************************************************
clear all
set more off

version 14
*set data path
run "00.set_path.do"

*set global macros to define outcome variables to be predicted, population weights, psu, poverty line, etc.
gl dv "fgt0 fgt0_2" //fgt0 = poverty; fgt0_2 = vulnerability rate
gl popwt "popwt" //weights
gl psu "psu" //PSU
gl welfare "gall_ae" //consumption per adult equivalent
gl pline "pline_g" //poverty line
gl adm1 "region" //region 
gl hhsize "F_hhsize" //hosuehold size
gl sae_level "location_id location_id2" //level at which poverty rate will be estimated
gl svy "pecs_2023" //survey data label
gl s_list "gov localityid location_id location_id2" //list of aggregation levels for which direct estimates and census aggregates are computed

gl census_list "F_hhsize F_hhsize2 F_hhsizeM F_spousenumber F_children0to17 F_adult18plus F_equivn C_female C_regrefug C_nonregrefug C_noregrefug C_senior66plus C_adult30to65 C_young14to29 C_nevermarried C_married C_widow C_divorsepar C_more1spouse C_married0spouse F_lnhhsize E_maxattainment E_attainspouse E_hhenrolled E_hhenrolledleft E_hhenrolledgradu E_hhenrollednever E_hhilliterat E_hhreadwrite E_hhelemtenta E_hhpreparato E_hhsecondary E_hhintermedi E_hhbachelor E_hhhigherdip E_hhmaster E_hhphd E_hhtypeabroad L_minoremploy L_spouseemploy L_nemployed L_employed_ratio L_num0to14hw L_num15to34hw L_hhemployed L_hhempfulltime L_hhunemployed L_hhemployer L_hhselfemplo L_hhunpfamwrk L_hhwagedempy L_hhirwagedemp L_hhsecnational L_hhseclocautho L_hhsecprivates L_hhsecunforngo L_hhplcathome L_hhplcsameloc L_hhplcsamegov L_hhplcothegov L_hhplcisrsett I_allmemhaveins I_chronratio I_nonediff I_atleastonegd I_greatdifratio I_hhhasinsurance I_hhinsgovernonly I_hhinsurnwaonly I_hhinsprivatonly I_hhinsgovurnwa I_hhinsisraeli I_hhhaschrondis I_hhnodifficult I_hhgreatdifficul H_dwelltype1 H_dwelltype2 H_dwelltype3 H_dwelltype4 H_dwelltype5 H_dwelltype6 H_tenure1 H_tenure2 H_tenure3 H_rooms H_bedroom H_water_piped H_water_bottled H_protected_well H_unprotected_well H_rainwater H_tanker H_electricity1 H_electricity2 H_electricity3 H_toilet1 H_toilet2 H_toilet3 H_toilet4 H_waste1 H_waste2 H_waste3 H_waste4 H_cooking1 H_cooking2 H_cooking3 H_cooking4 H_heating1 H_heating2 H_heating3  D_private_car D_refrigerator D_tv_ledlcd D_solar_boiler D_satellite D_computer D_smartphone D_ipatablet D_stove D_phone_line D_cellnotsmart D_dishwasher D_freezer D_central_heating D_home_library D_waterfilter D_air_conditioner D_centralAC D_tv_reg D_vacuum_cleaner D_dryer D_microwave D_electric_fan D_washing_mach" //list of census variables used for analysis

gl census_pcbs "povrate_2017 share_refugee share_dependants unemployment_rate funemployment_rate munemployment_rate employment_rate memployment_rate femployment_rate share_OLF share_mOLF share_fOLF share_employer share_selfemployed share_irregularwage share_unpaidfamily_worker share_youth_unempl share_neet share_natprivate share_unrwa share_natgov share_empl_home share_empl_samegov share_empl_othergov share_empl_abroad share_disabled share_outof_school share_educ_basic share_educ_second share_educ_abovesecond share_meduc_basic share_meduc_second share_meduc_abovesecond share_feduc_basic share_feduc_second share_feduc_abovesecond share_kids_outkinder share_internet share_computer share_foreign share_empl_israel share_disease share_regularwage" //list of census variables available from PCBS dashboard database

**get new locality IDs from PCBS Dashboard Dataset (https://www.pcbs.gov.ps/site/lang__en/1220/default.aspx)
tempfile temp
use "${github}/wb_sae_training/04.Data/PCBS Dashboard Dataset.dta", clear
*keep if Region_name=="West Bank"
drop if missing(loc_code)
keep loc_code location_id //loc_code = original locality code; location_id = merged localities
duplicates drop
save `temp', replace

**get survey and census data
use "${github}/wb_sae_training/04.Data/300_PalestinePovmap2023_JointDataSet_PECS2023_Census2017.dta",clear
codebook region 
drop loc_code
gen str10 loc_code = substr(string(localityid), 2, 7)
destring loc_code, replace force
merge m:1 loc_code using `temp'
run "auxi/merge.do" //generate location_id2 by merging locations with zero poverty

save "${github}/wb_sae_training/04.Data/300_PalestinePovmap2023_JointDataSet_PECS2023_Census2017_location_ID.dta", replace //save merged IDs: location_id2
********************************************************************************

use "${github}/wb_sae_training/04.Data/300_PalestinePovmap2023_JointDataSet_PECS2023_Census2017_location_ID.dta", clear
keep if pecs==1 /*& region == 1*/

********************************************************************************
*now notice that localityid is the original locality ID and locality_id2 is the merged version
egen strata = group(gov) //id01*10+loctype
svyset ${psu} [pw=${popwt}], strata(strata)
povdeco ${welfare} [pw=popwt] , varpline(${pline})
gen fgt0 = (${welfare} < ${pline}) if !missing(${welfare})
gen fgt0_2 = (${welfare} < ${pline}*2) if !missing(${welfare})

foreach v of global dv {
foreach s of global s_list {
preserve
*report mean of `v' and sum of population weight by `s' and PSU
groupfunction [aw=${popwt}], mean(`v') rawsum(${popwt}) by(`s' ${psu})
*report mean of `v' and # of PSU by `s'
groupfunction [aw=${popwt}], mean(`v') count(${psu}) by(`s')
restore

preserve
*get proportion of fgt0 by `s'
svy:proportion `v', over(`s')

*save results in mata
mata: `v' = st_matrix("e(b)")
mata: `v' = `v'[(cols(`v')/2+1)..cols(`v')]'
mata: `v'_var = st_matrix("e(V)")
mata: `v'_var = diagonal(`v'_var)[(cols(`v'_var)/2+1)..cols(`v'_var)]

gen N=1 //Need the number of observation by ${sae_level}...for smoother variance function
gen N_hhsize = ${hhsize}

//Number of EA by ${sae_level}
bysort `s' ${psu}: gen num_ea = 1 if _n==1

groupfunction [aw=${popwt}], mean(`v') rawsum(N ${popwt} N_hhsize num_ea) by(${adm1} `s')

sort `s'
getmata dir_`v' = `v' dir_`v'_var = `v'_var

gen zero = dir_`v' //original variable with direct estimates

replace dir_`v'_var = . if dir_`v'_var==0
replace dir_`v' = . if missing(dir_`v'_var)

save "${github}/wb_sae_training/04.Data/direct_`v'_${svy}_`s'.dta", replace
restore
}
}

*get all the census aggregates
use "${github}/wb_sae_training/04.Data/300_PalestinePovmap2023_JointDataSet_PECS2023_Census2017_location_ID.dta",clear
keep if pecs==0 /*& region == 1*/
foreach s of global s_list {
	preserve
	collapse $census_list (rawsum) pop_2017 = F_hhsize  [aw=F_hhsize ], by(`s')
	save "${github}/wb_sae_training/04.Data/census2017_`s'.dta", replace
	restore
}

/*export codebook*/
use "${github}/wb_sae_training/04.Data/300_PalestinePovmap2023_JointDataSet_PECS2023_Census2017_location_ID.dta", clear
keep C_* E_* F_* I_* D_*
codebookout "${github}/wb_sae_training/04.Data/codebook_census.xls", replace

********************************************************************************
/*Other auxiliary data*/
********************************************************************************
foreach s of global sae_level {
    *local s "location_id"
	*local n 0
*get location IDs
use "${github}/wb_sae_training/04.Data/PCBS Dashboard Dataset.dta", clear 
run "auxi/merge.do" //generate location_id2 by merging locations with zero poverty

*keep if Region_name=="West Bank"
ren poverty_sae povrate_2017 //get poverty rate from 2017

collapse (mean) ${census_pcbs} (rawsum) pop=Population_census [w=Population_census], by(Region_name `s')
drop if missing(`s')
merge 1:1 `s' using "${github}/wb_sae_training/04.Data/zonal_stats_`s'.dta", nogen //get zonal statistics
save "${github}/wb_sae_training/04.Data/FHcensus_`s'.dta", replace
}
