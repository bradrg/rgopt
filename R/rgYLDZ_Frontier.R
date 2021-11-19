
rgYLDZ_Frontier <- function() {

  rgSqlTrunc("ROBO", "portYLDZ_OptFrontier")

  ampl <- rgAMPL_Init()

  currentSettings <- rgSqlExec("ROBO", "SELECT AUM, Turnover FROM portYLDZ_OptSettings WHERE RECNO = 1")
  AUM <- currentSettings %>% pull(AUM)
  origTO <- currentSettings %>% pull(Turnover)

  optData <- rgSqlExec("ROBO", "EXEC spInternal_p_yldz_opt_build_data")

  setSQL <- function(to_target) {
    upd <- rgSqlExec("ROBO", paste0("SET NOCOUNT ON;UPDATE portYLDZ_OptSettings SET Turnover = ", to_target, " WHERE RECNO = 1; SELECT 1 AS result"))
  }

  runSolve <- function(to_target) {

    setSQL(to_target)
    ampl$read(rgYLDZ_Model())

    inc <- ampl$getVariable("IncomeRcvd")
    to <- ampl$getVariable("turnover_actual")

    result <- data.frame(TO_Target = to_target, TO_Actual = to$getValues() %>% pull(1), Yld = (inc$getValues() %>% pull(1)) / AUM)

    return(result)
  }

  # run and save 0 level
  minTO <- runSolve(0) %>%
    mutate(runTime = Sys.time(),
           finalRun = 0)
  rgSqlSave(minTO, "ROBO", "portYLDZ_OptFrontier", append = T, overwrite = F)

  maxTO <- runSolve(1)
  minTO_value <- floor((minTO %>% pull(TO_Actual))*2)/2
  maxTO_value <- ceiling((maxTO %>% pull(TO_Actual))*5)/5

  to_values <- c(seq(0, .09, .02), seq(.1, 1, .05))
  to_values <- to_values[between(to_values, pmax(minTO_value, .001), maxTO_value)]

  for (i in 1:length(to_values)) {
    #i = 1
    result <- runSolve(to_values[i]) %>%
      mutate(runTime = Sys.time(),
             finalRun = ifelse(i == length(to_values), T, F))
    rgSqlSave(result, "ROBO", "portYLDZ_OptFrontier", append = T, overwrite = F)
  }


  setSQL(origTO)
  ampl$close()

}
