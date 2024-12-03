# Welcome to the Small Area Estimation training for PCBS

This repository contains all the necessary files and instructions to replicate the analytical results for our project: Estimating small area estimates of poverty for Palestine. 

## Replication requirements

To replicate the results, you may first install `sae` and `groupfunction` in STATA. To install them, you simply run the following codes:

```
ssc install sae
ssc install groupfunction
```

You also need the `fhsae` and `sp_groupfunction` packages to replicate the results in this training. You may simply download [the fhsae package](https://github.com/jpazvd/fhsae) and [the sp_groupfunction package](https://github.com/pcorralrodas/sp_groupfunction) and save them into the `àdo/plus/f` and `ado/plus/s` folders on your local laptop, respectively. You can also find these ado files in the `00.AdoFiles` folder.

## Replication scripts

You may run the do files and R scripts in the following order:

1. `01.Codes/FayHerriot/00.set_path.do` - Define paths
2. `01.Codes/FayHerriot/01.SVY_prep.do` - Prepare PECS2023 and the census data for Fay-Harriet estimation
3. `01.Codes/FayHerriot/02.FH_model_select.do` - Perform FH for West Bank only and for both West Bank and Gaza

