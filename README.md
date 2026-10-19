# Family background in longitudinal household data

An independent empirical exploration of adoption, household circumstances and socioeconomic outcomes using the UK Household Longitudinal Study. The repository contains a Stata workflow for building the multiwave person/household data needed to investigate these questions.

**Status:** exploratory data construction.

## Motivation and intended questions

Family background is connected with the resources and circumstances people experience as they grow up. Adoption and stepfamily information offer a way to frame more detailed questions about those environments: how can household circumstances be measured consistently over time, when did a child join a household, and which later outcomes could be studied with the resulting longitudinal records?

The goal of this repository is to prepare a data foundation for investigating those questions. It brings relationship information and household income receipts into a common person-by-wave structure. Following people across survey waves can make the timing of household circumstances visible in a way that a single snapshot cannot.

## Why the data construction matters

Longitudinal surveys distribute information across files and waves. A person's persistent identifier, their household at a particular interview, relationship roster information and income receipts need to be linked at the correct level. Household membership can change even when a person identifier remains the same, and the available adoption fields are not identical in every wave.

The Stata workflow first establishes the core person/household records for each wave, then links adoption and stepchild information using the relevant identifiers. It handles the wave-`n` roster separately and constructs an age-at-joining field where the required year information is present. Income receipts are aggregated to people and then households before waves are appended. This ordering gives later analysis an explicit record of how the family-background variables were assembled.

The resulting file is a starting point for descriptive or causal research, rather than an estimated answer about family background. Adoption is not random assignment to a household, and differences between groups may reflect selection, earlier circumstances and measurement differences. A subsequent study would need to define its outcome, comparison group and identification strategy. This repository concentrates on the earlier task of making the relevant longitudinal information available for that work.

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
