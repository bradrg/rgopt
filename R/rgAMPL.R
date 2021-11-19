
rgAMPL_Init <- function(amplPath = "F:/AMPL/ampl.mswin64") {
  env <- new(Environment, amplPath)
  ampl <- new(AMPL, env)
  return(ampl)
}



