#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* .Call calls */
extern SEXP get_region(SEXP);
extern SEXP fisher_exact(SEXP);
extern SEXP pileup(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP scpileup(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
  {".get_region", (DL_FUNC) &get_region, 1},
  {".fisher_exact", (DL_FUNC) &fisher_exact, 1},
  {".pileup",(DL_FUNC)  &pileup, 13},
  {".scpileup",(DL_FUNC) &scpileup, 14},
  {NULL, NULL, 0}
};

void R_init_raer(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
