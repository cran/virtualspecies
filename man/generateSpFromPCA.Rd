% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generateSpFromPCA.R
\name{generateSpFromPCA}
\alias{generateSpFromPCA}
\title{Generate a virtual species distribution with a PCA of environmental variables}
\usage{
generateSpFromPCA(
  raster.stack,
  rescale = TRUE,
  niche.breadth = "any",
  axes = c(1, 2),
  means = NULL,
  sds = NULL,
  pca = NULL,
  sample.points = FALSE,
  nb.points = 10000,
  plot = TRUE
)
}
\arguments{
\item{raster.stack}{a SpatRaster object, in which each layer represent an
 environmental 
variable.}

\item{rescale}{\code{TRUE} or \code{FALSE}. Should the output suitability 
raster be
rescaled between 0 and 1?}

\item{niche.breadth}{\code{"any"}, \code{"narrow"} or \code{"wide"}. This 
parameter
defines how tolerant is the species regarding environmental conditions by
adjusting
the standard deviations of the gaussian functions. See details.}

\item{axes}{a vector of values. Which axes would you like to keep in your 
PCA? 
At least 2 axes should be included (Only 1 axis currently not supported)}

\item{means}{a vector containing as many numeric values as axes. Will be 
used to define
the means of the gaussian response functions to the axes of the PCA.}

\item{sds}{a vector containing as many numeric values as axes. Will be 
used to define
the standard deviations of the gaussian response functions to the axes of 
the PCA.}

\item{pca}{a \code{dudi.pca} object. You can provide a pca object that you 
computed yourself with \code{\link[ade4]{dudi.pca}}}

\item{sample.points}{\code{TRUE} of \code{FALSE}. If you have a large
raster file then use this parameter to sample a number of points equal to
\code{nb.points}.}

\item{nb.points}{a numeric value. Only useful if \code{sample.points = TRUE}.
The number of sampled points from the raster, to perform the PCA. A too small
value may not be representative of the environmental conditions in your 
raster.}

\item{plot}{\code{TRUE} or \code{FALSE}. If \code{TRUE}, the generated 
virtual species will be plotted.}
}
\value{
a \code{list} with 3 elements:
\itemize{
\item{\code{approach}: the approach used to generate the species, 
\emph{i.e.}, \code{"pca"}}
\item{\code{details}: the details and parameters used to generate 
the species}
\item{\code{suitab.raster}: the virtual species distribution, as a 
SpatRaster object containing the
environmental suitability}
}
The structure of the virtualspecies object can be seen using \code{str()}
}
\description{
This functions generates a virtual species distribution by computing a
PCA among environmental variables, and simulating the response of the species
along the two first axes of the PCA. The response to axes of the PCA is 
determined with gaussian functions.
}
\details{
\href{http://borisleroy.com/virtualspecies_tutorial/03-PCA.html}{Online 
tutorial for this function}


This function proceeds in 3 steps:
\enumerate{
\item{A PCA of environmental conditions is generated}
\item{Gaussian responses to the first two axes are computed}
\item{These responses are multiplied to obtain the final environmental 
suitability}}

If \code{rescale = TRUE}, the final environmental suitability is rescaled 
between 0 and 1,
with the formula (val - min) / (max - min).

The shape of gaussian responses can be randomly generated by the function or
 defined manually by choosing
\code{means} and \code{sds}. The random generation is constrained
by the argument \code{niche.breadth}, which controls the range of possible 
standard deviation values. This range of values is based on
a fraction of the axis:
\itemize{
\item{\code{"any"}: the standard deviations can have values from 1\% to 
50\% of axes' ranges. For example if the first axis of the PCA ranges from 
-5 to +5,
then sd values along this axis can range from 0.1 to 5.
}
\item{\code{"narrow"}: the standard deviations are limited between 1\% and 
10\% of axes' ranges. For example if the first axis of the PCA ranges from 
-5 to +5,
then sd values along this axis can range from 0.1 to 1.
}
\item{\code{"wide"}: the standard deviations are limited between 10\% and 
50\% of axes' ranges. For example if the first axis of the PCA ranges from 
-5 to +5,
then sd values along this axis can range from 1 to 5.
}
}
}
\note{
To perform the PCA, the function has to transform the raster into a matrix.
This may not be feasible if the raster is too large for the 
computer's memory.
In this case, you should perform the PCA on a sample of your raster with
set \code{sample.points = TRUE} and choose the number of points to sample 
with
\code{nb.points}.
}
\examples{
# Create an example stack with four environmental variables
a <- matrix(rep(dnorm(1:100, 50, sd = 25)), 
            nrow = 100, ncol = 100, byrow = TRUE)
env <- c(rast(a * dnorm(1:100, 50, sd = 25)),
             rast(a * 1:100),
             rast(a * logisticFun(1:100, alpha = 10, beta = 70)),
             rast(t(a)))
names(env) <- c("var1", "var2", "var3", "var4")
plot(env) # Illustration of the variables





# Generating a species with the PCA

generateSpFromPCA(raster.stack = env)

# The top part of the plot shows the PCA and the response functions along
# the two axes.
# The bottom part shows the probabilities of occurrence of the virtual
# species.





# Defining manually the response to axes

generateSpFromPCA(raster.stack = env,
           means = c(-2, 0),
           sds = c(0.6, 1.5))
           
# This species can be seen as occupying intermediate altitude ranges of a
# conic mountain.


# Beyond the first two axes
generateSpFromPCA(raster.stack = env,
                  axes = c(1, 3))
                  
sp <- generateSpFromPCA(raster.stack = env,
                  axes = 1:3)
plotResponse(sp, axes = c(1, 2))
plotResponse(sp, axes = c(1, 3))
plotResponse(sp, axes = c(2, 3))
           
}
\seealso{
\code{\link{generateSpFromFun}} to generate a virtual species with
the responses to each environmental variables.
}
\author{
Boris Leroy \email{leroy.boris@gmail.com}

with help from C. N. Meynard, C. Bellard & F. Courchamp
}
