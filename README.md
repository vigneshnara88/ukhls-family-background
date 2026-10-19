# Family background in longitudinal household data

An independent empirical exploration of adoption, household circumstances and socioeconomic outcomes using the UK Household Longitudinal Study. The repository contains a Stata workflow for building the multiwave person/household data needed to investigate these questions.

**Status:** exploratory data construction.

## Workflow

`do_files/adoption.do` loops over waves `a`–`n` and:

1. Standardises person identifiers, household identifiers, age and sex from each wave's `indall` file.
2. Links adoption/stepchild information, including a separate wave-`n` roster path.
3. Constructs a joining-age field where the relevant year information is available.
4. Aggregates income receipts first to people and then households.
5. Appends the waves into `ukhls_allwaves_child_adopt_ses.dta`.

## Data and use

Stata 16 or later and authorised access to the relevant UKHLS files are required. Data are not redistributed here.

Place the required wave files in an untracked `UKHLS/` directory at the repository root, or edit the `UKHLS` global at the top of the do-file to point to your local extract. Keep the source filenames and wave prefixes expected by the script.

From the repository root in Stata:

```stata
do do_files/adoption.do
```

The do-file writes its assembled dataset under the configured `UKHLS` directory. Use a working copy of the data; the final output is replaced if it already exists.

## Interpretation

This workflow prepares variables rather than establishing a causal effect of adoption or family background. Relationship codes need to be interpreted against the documentation for the exact release. Missing information, sample selection and the timing of household changes all matter for subsequent analysis.

The household receipt total is a constructed socioeconomic measure; it should not automatically be treated as an official equivalised income measure. A separate outcome analysis would need to specify the sample, weights, missingness rules and estimand.
