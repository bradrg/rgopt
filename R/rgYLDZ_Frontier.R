
rgYLDZ_Frontier <- function() {

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

    return(data.frame(TO_Target = to_target, TO_Actual = to$getValues() %>% pull(1), Yld = (inc$getValues() %>% pull(1)) / AUM))
  }

  maxTO <- runSolve(1)
  minTO <- runSolve(0)

  minTO_value <- floor((minTO %>% pull(TO_Actual))*2)/2
  maxTO_value <- ceiling((maxTO %>% pull(TO_Actual))*10)/10

  to_values <- c(seq(0, .09, .02), seq(.1, 1, .1))
  r <- map_df(to_values[between(to_values, minTO_value, maxTO_value)], runSolve)

  setSQL(origTO)

  output <- r %>% mutate(runTime = Sys.time())
  rgSqlSave(output, "ROBO", "portYLDZ_OptFrontier", append = F, overwrite = T)


}
