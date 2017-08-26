library(devtools)
library(knitr)
library(pkgdown)
library(poissqlite)

document()
knit("README.Rmd")
build_site()
knit("README.Rmd") # necessary because build_site messes with README.md
