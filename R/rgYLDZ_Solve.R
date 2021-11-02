
rgYLDZ_Solve <- function() {

  ampl <- rgAMPL_Init()
  optData <- rgSqlExec("ROBO", "EXEC spInternal_p_yldz_opt_build_data")
  trunc <- rgSqlExec("ROBO", "SET NOCOUNT ON;TRUNCATE TABLE portYLDZ_OptSoln; SELECT 1 AS result")
  opt_msg <- capture.output(ampl$read(rgYLDZ_Model()))
  ampl$writeTable("RES")
  ampl$close()
  return(opt_msg)
}
