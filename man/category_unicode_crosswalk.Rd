% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{category_unicode_crosswalk}
\alias{category_unicode_crosswalk}
\title{Emoji category, Unicode crosswalk}
\format{
A data frame with 10 rows and 2 columns:
\describe{
  \item{category}{Emoji category (10 categories only)}
  \item{unicodes}{The Unicodes string of Emojis belonging to category per
  se.}
}
}
\source{
The raw data set \code{emojis} comes from the
\code{emoji} package, and it is processed by the author for the specific
needs of \code{tidyEmoji}.
}
\usage{
category_unicode_crosswalk
}
\description{
A data set containing each Emoji category (such as Activities), its
respective Unicodes string separated by \code{|}.
}
\keyword{datasets}
