library(tibble)
library(lubridate)

# derive_param_tte ----
## Test 1: new observations with analysis date are derived correctly ----
test_that("derive_param_tte Test 1: new observations with analysis date are derived correctly", {
  adsl <- tribble(
    ~USUBJID, ~DTHFL, ~DTHDT,            ~LSTALVDT,         ~TRTSDT,           ~TRTSDTF,
    "03",     "Y",    ymd("2021-08-21"), ymd("2021-08-21"), ymd("2021-08-10"), NA,
    "04",     "N",    NA,                ymd("2021-05-24"), ymd("2021-02-03"), NA
  ) %>%
    mutate(STUDYID = "AB42")

  death <- event_source(
    dataset_name = "adsl",
    filter = DTHFL == "Y",
    date = DTHDT,
    set_values_to = vars(
      EVENTDESC = "DEATH",
      SRCDOM = "ADSL",
      SRCVAR = "DTHDT"
    )
  )

  lstalv <- censor_source(
    dataset_name = "adsl",
    date = LSTALVDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "LAST KNOWN ALIVE DATE",
      SRCDOM = "ADSL",
      SRCVAR = "LSTALVDT"
    )
  )

  expected_output <- tribble(
    ~USUBJID, ~ADT,              ~CNSR, ~EVENTDESC,              ~SRCDOM, ~SRCVAR,
    "03",     ymd("2021-08-21"), 0L,    "DEATH",                 "ADSL",  "DTHDT",
    "04",     ymd("2021-05-24"), 1L,    "LAST KNOWN ALIVE DATE", "ADSL",  "LSTALVDT"
  ) %>%
    mutate(
      STUDYID = "AB42",
      PARAMCD = "OS",
      PARAM = "Overall Survival"
    ) %>%
    left_join(select(adsl, USUBJID, STARTDT = TRTSDT, STARTDTF = TRTSDTF), by = "USUBJID")

  actual_output <- derive_param_tte(
    dataset_adsl = adsl,
    start_date = TRTSDT,
    event_conditions = list(death),
    censor_conditions = list(lstalv),
    source_datasets = list(adsl = adsl),
    set_values_to = vars(
      PARAMCD = "OS",
      PARAM = "Overall Survival"
    )
  )

  expect_dfs_equal(
    actual_output,
    expected_output,
    keys = c("USUBJID", "PARAMCD")
  )
})

## Test 2: new parameter with analysis datetime is derived correctly ----
test_that("derive_param_tte Test 2: new parameter with analysis datetime is derived correctly", {
  adsl <- tibble::tribble(
    ~USUBJID, ~DTHFL, ~DTHDT,            ~TRTSDTM,                       ~TRTSDTF, ~TRTSTMF,
    "01",     "Y",    ymd("2021-06-12"), ymd_hms("2021-01-01 00:00:00"), "M",      "H",
    "02",     "N",    NA,                ymd_hms("2021-02-03 10:24:00"), NA,       NA,
    "03",     "Y",    ymd("2021-08-21"), ymd_hms("2021-08-10 00:00:00"), NA,       "H",
    "04",     "N",    NA,                ymd_hms("2021-02-03 10:24:00"), NA,       NA,
    "05",     "N",    NA,                ymd_hms("2021-04-05 11:22:33"), NA,       NA
  ) %>%
    mutate(STUDYID = "AB42")

  adrs <- tibble::tribble(
    ~USUBJID, ~AVALC, ~ADTM,                          ~ASEQ,
    "01",     "SD",   ymd_hms("2021-01-03 10:56:00"), 1,
    "01",     "PR",   ymd_hms("2021-03-04 11:13:00"), 2,
    "01",     "PD",   ymd_hms("2021-05-05 12:02:00"), 3,
    "02",     "PD",   ymd_hms("2021-02-03 10:56:00"), 1,
    "04",     "SD",   ymd_hms("2021-02-13 10:56:00"), 1,
    "04",     "PR",   ymd_hms("2021-04-14 11:13:00"), 2,
    "04",     "CR",   ymd_hms("2021-05-15 12:02:00"), 3
  ) %>%
    mutate(STUDYID = "AB42", PARAMCD = "OVR")

  pd <- event_source(
    dataset_name = "adrs",
    filter = AVALC == "PD",
    date = ADTM,
    set_values_to = vars(
      EVENTDESC = "PD",
      SRCDOM = "ADRS",
      SRCVAR = "ADTM",
      SRCSEQ = ASEQ
    )
  )

  death <- event_source(
    dataset_name = "adsl",
    filter = DTHFL == "Y",
    date = DTHDT,
    set_values_to = vars(
      EVENTDESC = "DEATH",
      SRCDOM = "ADSL",
      SRCVAR = "DTHDT"
    )
  )

  lastvisit <- censor_source(
    dataset_name = "adrs",
    date = ADTM,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "LAST TUMOR ASSESSMENT",
      SRCDOM = "ADRS",
      SRCVAR = "ADTM"
    )
  )

  start <- censor_source(
    dataset_name = "adsl",
    date = TRTSDTM,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "TREATMENT START",
      SRCDOM = "ADSL",
      SRCVAR = "TRTSDTM"
    )
  )

  # nolint start
  expected_output <- tribble(
    ~USUBJID, ~ADTM,                          ~CNSR, ~EVENTDESC,              ~SRCDOM, ~SRCVAR,   ~SRCSEQ,
    "01",     ymd_hms("2021-05-05 12:02:00"), 0L,    "PD",                    "ADRS",  "ADTM",    3,
    "02",     ymd_hms("2021-02-03 10:56:00"), 0L,    "PD",                    "ADRS",  "ADTM",    1,
    "03",     as_datetime(ymd("2021-08-21")), 0L,    "DEATH",                 "ADSL",  "DTHDT",   NA,
    "04",     ymd_hms("2021-05-15 12:02:00"), 1L,    "LAST TUMOR ASSESSMENT", "ADRS",  "ADTM",    NA,
    "05",     ymd_hms("2021-04-05 11:22:33"), 1L,    "TREATMENT START",       "ADSL",  "TRTSDTM", NA
  ) %>%
    # nolint end
    mutate(
      STUDYID = "AB42",
      PARAMCD = "PFS",
      PARAM = "Progression Free Survival"
    ) %>%
    left_join(
      select(adsl, USUBJID, STARTDTM = TRTSDTM, STARTDTF = TRTSDTF, STARTTMF = TRTSTMF),
      by = "USUBJID"
    )

  actual_output <- derive_param_tte(
    dataset_adsl = adsl,
    start_date = TRTSDTM,
    event_conditions = list(pd, death),
    censor_conditions = list(lastvisit, start),
    source_datasets = list(adsl = adsl, adrs = adrs),
    create_datetime = TRUE,
    set_values_to = vars(
      PARAMCD = "PFS",
      PARAM = "Progression Free Survival"
    )
  )

  expect_dfs_equal(
    actual_output,
    expected_output,
    keys = c("USUBJID", "PARAMCD")
  )
})

## Test 3: error is issued if DTC variables specified for date ----
test_that("derive_param_tte Test 3: error is issued if DTC variables specified for date", {
  adsl <- tibble::tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tibble::tribble(
    ~USUBJID, ~AESTDTC,           ~AESEQ,
    "01",     "2021-01-03T10:56", 1,
    "01",     "2021-03-04",       2,
    "01",     "2021",             3
  ) %>%
    mutate(STUDYID = "AB42")

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDTC,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  expect_error(
    derive_param_tte(
      dataset_adsl = adsl,
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = "TTAE",
        PARAM = "Time to First Adverse Event"
      )
    ),
    regexp = "`AESTDTC` in dataset `ae` is not a date or datetime variable but is a character vector" # nolint
  )
})

## Test 4: by_vars parameter works correctly ----
test_that("derive_param_tte Test 4: by_vars parameter works correctly", {
  adsl <- tibble::tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tibble::tribble(
    ~USUBJID, ~AESTDTC,     ~AESEQ, ~AEDECOD,
    "01",     "2021-01-03", 1,      "Flu",
    "01",     "2021-03-04", 2,      "Cough",
    "01",     "2021-01-01", 3,      "Flu"
  ) %>%
    mutate(
      STUDYID = "AB42",
      AESTDT = ymd(AESTDTC)
    )

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDT,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  # nolint start
  expected_output <- tibble::tribble(
    ~USUBJID, ~ADT,              ~CNSR, ~EVENTDESC,     ~SRCDOM, ~SRCVAR,   ~SRCSEQ, ~PARCAT2, ~PARAMCD,
    "01",     ymd("2021-01-01"), 0L,    "AE",           "AE",    "AESTDTC", 3,       "Flu",    "TTAE2",
    "02",     ymd("2021-02-03"), 1L,    "END OF STUDY", "ADSL",  "EOSDT",   NA,      "Flu",    "TTAE2",
    "01",     ymd("2021-03-04"), 0L,    "AE",           "AE",    "AESTDTC", 2,       "Cough",  "TTAE1",
    "02",     ymd("2021-02-03"), 1L,    "END OF STUDY", "ADSL",  "EOSDT",   NA,      "Cough",  "TTAE1"
  ) %>%
    # nolint end
    mutate(
      STUDYID = "AB42",
      PARCAT1 = "TTAE",
      PARAM = paste("Time to First", PARCAT2, "Adverse Event")
    ) %>%
    left_join(select(adsl, USUBJID, STARTDT = TRTSDT), by = "USUBJID")

  expect_dfs_equal(
    derive_param_tte(
      dataset_adsl = adsl,
      by_vars = vars(AEDECOD),
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = paste0("TTAE", as.numeric(as.factor(AEDECOD))),
        PARAM = paste("Time to First", AEDECOD, "Adverse Event"),
        PARCAT1 = "TTAE",
        PARCAT2 = AEDECOD
      )
    ),
    expected_output,
    keys = c("USUBJID", "PARAMCD")
  )
})

## Test 5: an error is issued if some of the by variables are missing ----
test_that("derive_param_tte Test 5: an error is issued if some of the by variables are missing", {
  adsl <- tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tribble(
    ~USUBJID, ~AESTDTC,     ~AESEQ, ~AEDECOD,
    "01",     "2021-01-03", 1,      "Flu",
    "01",     "2021-03-04", 2,      "Cough",
    "01",     "2021-01-01", 3,      "Flu"
  ) %>%
    mutate(
      STUDYID = "AB42",
      AESTDT = ymd(AESTDTC)
    )

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDT,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  expect_error(
    derive_param_tte(
      dataset_adsl = adsl,
      by_vars = vars(AEBODSYS, AEDECOD),
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = paste0("TTAE", as.numeric(as.factor(AEDECOD))),
        PARAM = paste("Time to First", AEDECOD, "Adverse Event"),
        PARCAT1 = "TTAE",
        PARCAT2 = AEDECOD
      )
    ),
    regexp = "^Only AEDECOD are included in source dataset.*"
  )
})

## Test 6: errors if all by vars are missing in all source datasets ----
test_that("derive_param_tte Test 6: errors if all by vars are missing in all source datasets", {
  adsl <- tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tibble::tribble(
    ~USUBJID, ~AESTDTC,     ~AESEQ, ~AEDECOD,
    "01",     "2021-01-03", 1,      "Flu",
    "01",     "2021-03-04", 2,      "Cough",
    "01",     "2021-01-01", 3,      "Flu"
  ) %>%
    mutate(
      STUDYID = "AB42",
      AESTDT = ymd(AESTDTC)
    )

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDT,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  expect_error(
    derive_param_tte(
      dataset_adsl = adsl,
      by_vars = vars(AEBODSYS),
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = paste0("TTAE", as.numeric(as.factor(AEDECOD))),
        PARAM = paste("Time to First", AEDECOD, "Adverse Event"),
        PARCAT1 = "TTAE",
        PARCAT2 = AEDECOD
      )
    ),
    regexp = "The by variables (AEBODSYS) are not contained in any of the source datasets.",
    fixed = TRUE
  )
})

## Test 7: errors if PARAMCD and by_vars are not one to one ----
test_that("derive_param_tte Test 7: errors if PARAMCD and by_vars are not one to one", {
  adsl <- tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tribble(
    ~USUBJID, ~AESTDTC,     ~AESEQ, ~AEDECOD,
    "01",     "2021-01-03", 1,      "Flu",
    "01",     "2021-03-04", 2,      "Cough",
    "01",     "2021-01-01", 3,      "Flu"
  ) %>%
    mutate(
      STUDYID = "AB42",
      AESTDT = ymd(AESTDTC)
    )

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDT,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  expect_error(
    derive_param_tte(
      dataset_adsl = adsl,
      by_vars = vars(AEDECOD),
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = "TTAE",
        PARCAT2 = AEDECOD
      )
    ),
    regexp = paste0(
      "For some values of PARAMCD there is more than one value of AEDECOD.\n",
      "Call `get_one_to_many_dataset()` to get all one to many values."
    ),
    fixed = TRUE
  )
})

## Test 8: errors if set_values_to contains invalid expressions ----
test_that("derive_param_tte Test 8: errors if set_values_to contains invalid expressions", {
  adsl <- tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tribble(
    ~USUBJID, ~AESTDTC,     ~AESEQ, ~AEDECOD,
    "01",     "2021-01-03", 1,      "Flu",
    "01",     "2021-03-04", 2,      "Cough",
    "01",     "2021-01-01", 3,      "Flu"
  ) %>%
    mutate(
      STUDYID = "AB42",
      AESTDT = ymd(AESTDTC)
    )

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDT,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  expect_error(
    derive_param_tte(
      dataset_adsl = adsl,
      by_vars = vars(AEDECOD),
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = paste0("TTAE", as.numeric(as.factor(AEDECOD))),
        PARAM = past("Time to First", AEDECOD, "Adverse Event"),
        PARCAT1 = "TTAE",
        PARCAT2 = AEDECOD
      )
    ),
    regexp = paste0(
      "Assigning new variables failed!\n",
      "set_values_to = \\(\n",
      "  PARAMCD = paste0\\(\"TTAE\", as.numeric\\(as.factor\\(AEDECOD\\)\\)\\)\n",
      "  PARAM = past\\(\"Time to First\", AEDECOD, \"Adverse Event\"\\)\n",
      "  PARCAT1 = TTAE\n",
      "  PARCAT2 = AEDECOD\n",
      "\\)\n",
      "Error message:\n",
      "  .*"
    )
  )
})

## Test 9: error is issued if parameter code already exists ----
test_that("derive_param_tte Test 9: error is issued if parameter code already exists", {
  adsl <- tribble(
    ~USUBJID, ~TRTSDT,           ~EOSDT,
    "01",     ymd("2020-12-06"), ymd("2021-03-06"),
    "02",     ymd("2021-01-16"), ymd("2021-02-03")
  ) %>%
    mutate(STUDYID = "AB42")

  ae <- tribble(
    ~USUBJID, ~AESTDTC,     ~AESEQ, ~AEDECOD,
    "01",     "2021-01-03", 1,      "Flu",
    "01",     "2021-03-04", 2,      "Cough",
    "01",     "2021-01-01", 3,      "Flu"
  ) %>%
    mutate(
      STUDYID = "AB42",
      AESTDT = ymd(AESTDTC)
    )

  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDT,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )

  eos <- censor_source(
    dataset_name = "adsl",
    date = EOSDT,
    censor = 1,
    set_values_to = vars(
      EVENTDESC = "END OF STUDY",
      SRCDOM = "ADSL",
      SRCVAR = "EOSDT"
    )
  )

  expected_output <- tibble::tribble(
    ~USUBJID, ~ADT,              ~CNSR, ~EVENTDESC,     ~SRCDOM, ~SRCVAR,   ~SRCSEQ,
    "01",     ymd("2021-01-01"), 0L,    "AE",           "AE",    "AESTDTC", 3,
    "02",     ymd("2021-02-03"), 1L,    "END OF STUDY", "ADSL",  "EOSDT",   NA
  ) %>%
    mutate(
      STUDYID = "AB42",
      PARAMCD = "TTAE",
      PARAM = "Time to First Adverse Event"
    ) %>%
    left_join(select(adsl, USUBJID, STARTDT = TRTSDT), by = "USUBJID")

  expect_error(
    derive_param_tte(
      expected_output,
      dataset_adsl = adsl,
      start_date = TRTSDT,
      event_conditions = list(ttae),
      censor_conditions = list(eos),
      source_datasets = list(adsl = adsl, ae = ae),
      set_values_to = vars(
        PARAMCD = "TTAE",
        PARAM = "Time to First Adverse Event"
      )
    ),
    regexp = "^The parameter code 'TTAE' does already exist in `dataset`.$"
  )
})

# print.tte_source ----
## Test 10: tte_source` objects are printed as intended ----
test_that("`print.tte_source Test 10: tte_source` objects are printed as intended", {
  ttae <- event_source(
    dataset_name = "ae",
    date = AESTDTC,
    set_values_to = vars(
      EVENTDESC = "AE",
      SRCDOM = "AE",
      SRCVAR = "AESTDTC",
      SRCSEQ = AESEQ
    )
  )
  expected_print_output <- c(
    "<tte_source> object",
    "dataset_name: \"ae\"",
    "filter: NULL",
    "date: AESTDTC",
    "censor: 0",
    "set_values_to:",
    "  EVENTDESC: \"AE\"",
    "  SRCDOM: \"AE\"",
    "  SRCVAR: \"AESTDTC\"",
    "  SRCSEQ: AESEQ"
  )
  expect_identical(capture.output(print(ttae)), expected_print_output)
})
