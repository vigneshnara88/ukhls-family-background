/****************************************************************************************
UKHLS ALL WAVES (a–n) — core + adopt/step + HH SES from income receipts
FIX: do NOT pre-create hh_ses before merge; coalesce if Stata creates hh_ses_using
****************************************************************************************/

clear all
set more off
version 16
global UKHLS "UKHLS"

local uk_waves "a b c d e f g h i j k l m n"

tempfile ALL CORE ADOPTLINK HHSES
save `ALL', emptyok replace

foreach w of local uk_waves {

    di as txt "=== Processing UKHLS wave `w' ==="

    /******************************************************
    * 1) CORE (w_indall)
    ******************************************************/
    use "${UKHLS}/`w'_indall.dta", clear
    keep pidp `w'_hidp `w'_pno `w'_age_dv `w'_sex_dv

    rename `w'_hidp hidp
    rename `w'_pno  pno
    rename `w'_age_dv age_dv
    rename `w'_sex_dv sex_dv

    gen str1 wave = "`w'"
    gen byte adopted   = 0
    gen byte stepchild = 0
    gen int  join_age  = .

    * IMPORTANT: do NOT gen hh_ses here (avoid merge name collision)

    save `CORE', replace


    /******************************************************
    * 2) ADOPTION / STEPCHILD (w_adopt)
    ******************************************************/
    capture confirm file "${UKHLS}/`w'_adopt.dta"
    if !_rc {

        * ---- Wave n special case: no lascst, use adopt roster ----
        if "`w'"=="n" {
            use "${UKHLS}/n_adopt.dta", clear
            keep n_hidp n_lacno n_lacyb4 n_lacby4
            rename n_hidp  hidp
            rename n_lacno pno

            mvdecode n_lacyb4 n_lacby4, mv(-9 -8 -7 -6 -5 -4 -3 -2 -1)

            gen byte adopted_u = 1
            gen int join_age_u = n_lacyb4 - n_lacby4 ///
                if inrange(n_lacyb4,1900,2100) & inrange(n_lacby4,1900,2100)

            keep hidp pno adopted_u join_age_u
            bys hidp pno: keep if _n==1
            save `ADOPTLINK', replace

            use `CORE', clear
            merge m:1 hidp pno using `ADOPTLINK', nogen

            replace adopted  = adopted_u if !missing(adopted_u)
            replace adopted  = 0 if missing(adopted)
            replace join_age = join_age_u if !missing(join_age_u)

            drop adopted_u join_age_u
            save `CORE', replace
        }
        else {
            use "${UKHLS}/`w'_adopt.dta", clear

            capture ds *_hidp
            local v_hidp : word 1 of `r(varlist)'

            capture ds *lacno*
            local v_lacno : word 1 of `r(varlist)'

            capture ds *lascst*
            local v_lascst : word 1 of `r(varlist)'

            capture ds *adoptno*
            local v_adoptno : word 1 of `r(varlist)'

            capture ds *lacyb4*
            local v_lacyb4 : word 1 of `r(varlist)'

            capture ds *lacby4*
            local v_lacby4 : word 1 of `r(varlist)'

            if "`v_hidp'"=="" | "`v_lacno'"=="" {
                di as error "Wave `w': adopt file present but hidp/lacno not found; skipping adopt merge."
            }
            else {
                keep `v_hidp' `v_lacno' `v_lascst' `v_adoptno' `v_lacyb4' `v_lacby4'
                rename `v_hidp'  hidp
                rename `v_lacno' pno

                if "`v_lascst'"!="" rename `v_lascst' lascst_raw
                else gen lascst_raw = .

                if "`v_adoptno'"!="" rename `v_adoptno' adoptno_raw
                else gen adoptno_raw = .

                if "`v_lacyb4'"!="" rename `v_lacyb4' lacyb4_raw
                else gen lacyb4_raw = .

                if "`v_lacby4'"!="" rename `v_lacby4' lacby4_raw
                else gen lacby4_raw = .

                mvdecode lascst_raw adoptno_raw lacyb4_raw lacby4_raw, mv(-9 -8 -7 -6 -5 -4 -3 -2 -1)

                bys hidp pno: egen lascst_u = max(lascst_raw)
                bys hidp pno: egen adoptno_u = max(adoptno_raw)
                bys hidp pno: egen lacyb4_u = max(lacyb4_raw)
                bys hidp pno: egen lacby4_u = max(lacby4_raw)

                keep hidp pno lascst_u adoptno_u lacyb4_u lacby4_u
                bys hidp pno: keep if _n==1

                gen byte adopted_u = .
                gen byte stepchild_u = .

                * primary: lascst (wave a confirmed 1=step, 2=adopted)
                replace adopted_u   = (lascst_u==2) if !missing(lascst_u)
                replace stepchild_u = (lascst_u==1) if !missing(lascst_u)

                * fallback: adoptno present => adopted
                replace adopted_u   = 1 if missing(adopted_u) & !missing(adoptno_u)
                replace stepchild_u = 0 if missing(stepchild_u) & !missing(adoptno_u)

                replace adopted_u   = 0 if missing(adopted_u)
                replace stepchild_u = 0 if missing(stepchild_u)

                gen int join_age_u = lacyb4_u - lacby4_u ///
                    if inrange(lacyb4_u,1900,2100) & inrange(lacby4_u,1900,2100)

                keep hidp pno adopted_u stepchild_u join_age_u
                save `ADOPTLINK', replace

                use `CORE', clear
                merge m:1 hidp pno using `ADOPTLINK', nogen

                replace adopted   = adopted_u
                replace stepchild = stepchild_u
                replace join_age  = join_age_u if !missing(join_age_u)

                drop adopted_u stepchild_u join_age_u
                save `CORE', replace
            }
        }
    }


    /******************************************************
* 3) HOUSEHOLD SES FROM w_income (person×source receipts)
******************************************************/
capture confirm file "${UKHLS}/`w'_income.dta"
if !_rc {

    use "${UKHLS}/`w'_income.dta", clear

    capture ds *_hidp
    local v_hidp2 : word 1 of `r(varlist)'

    capture confirm variable pidp
    if _rc {
        capture confirm variable idp
        if !_rc rename idp pidp
    }

    capture ds *frmnthimp_dv*
    local v_imp : word 1 of `r(varlist)'

    capture ds *frmnth_dv*
    local v_all "`r(varlist)'"
    local v_rawlist : list v_all - v_imp
    local v_raw : word 1 of `v_rawlist'

    if "`v_hidp2'"=="" | ("`v_imp'"=="" & "`v_raw'"=="") {
        di as error "Wave `w': income vars not found; skipping hh_ses."
        use `CORE', clear
        gen double hh_ses = .
        save `CORE', replace
    }
    else {
        keep `v_hidp2' pidp `v_imp' `v_raw'
        rename `v_hidp2' hidp

        if "`v_imp'"!="" mvdecode `v_imp', mv(-9 -8 -7 -6 -5 -4 -3 -2 -1)
        if "`v_raw'"!="" mvdecode `v_raw', mv(-9 -8 -7 -6 -5 -4 -3 -2 -1)

        gen double inc_src = .
        if "`v_imp'"!="" replace inc_src = `v_imp'
        if "`v_raw'"!="" replace inc_src = `v_raw' if missing(inc_src)

        * receipts -> person -> household (THIS SECOND COLLAPSE IS THE KEY)
        collapse (sum) inc_person = inc_src, by(hidp pidp)
        collapse (sum) hh_ses = inc_person, by(hidp)

        save `HHSES', replace

        use `CORE', clear
        merge m:1 hidp using `HHSES', nogen keep(master match)

        * if hh_ses somehow not created, create it
        capture confirm variable hh_ses
        if _rc gen double hh_ses = .

        save `CORE', replace
    }
}
else {
    use `CORE', clear
    gen double hh_ses = .
    save `CORE', replace
}


    /******************************************************
    * 4) APPEND WAVE
    ******************************************************/
    use `CORE', clear
    keep wave pidp hidp pno age_dv sex_dv adopted stepchild join_age hh_ses
    compress

    append using `ALL'
    save `ALL', replace
}

use `ALL', clear
save "${UKHLS}/ukhls_allwaves_child_adopt_ses.dta", replace
di as result "Saved: ${UKHLS}/ukhls_allwaves_child_adopt_ses.dta"









