library(devtools)
library(knitr)
library(pkgdown)

document()
knit("README.Rmd")
build_site()
