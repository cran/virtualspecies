#' Visualise the response of the virtual species to environmental variables
#' 
#' This function plots the relationships between the virtual species and the environmental variables.
#' It requires either the output from \code{\link{generateSpFromFun}}, \code{\link{generateSpFromPCA}}, 
#' \code{\link{generateRandomSp}},
#' or a manually defined set of environmental variables and response functions.
#' 
#' @param x the output from \code{\link{generateSpFromFun}}, \code{\link{generateSpFromPCA}}, 
#' \code{\link{generateRandomSp}}, or
#' a raster layer/stack of environmental variables (see details for the latter).
#' @param parameters in case of manually defined response functions, a list 
#' containing the associated parameters. See details.
#' @param approach in case of manually defined response functions, the chosen
#' approach: either \code{"response"} for a per-variable response approach, or
#' \code{"pca"} for a PCA approach.
#' @param rescale \code{TRUE} or \code{FALSE}. If \code{TRUE}, individual response
#' plots are rescaled between 0 and 1.
#' @param axes.to.plot a vector of 2 values listing the two axes of the PCA to plot.
#' Only useful for a PCA species.
#' @param no.plot.reset \code{TRUE} or \code{FALSE}. If \code{FALSE}, the plot window
#' will be reset to its initial state after the response has been plotted. 
#' @param rescale.each.response \code{TRUE} or \code{FALSE}. If \code{TRUE}, 
#' the individual responses to
#' each environmental variable are rescaled between 0 and 1.
#' @param ... further arguments to be passed to \code{plot}. See 
#' \code{\link[graphics]{plot}} and \code{\link[graphics]{par}}.
#' @details
#' If you provide the output from \code{\link{generateSpFromFun}}, \code{\link{generateSpFromPCA}} or
#' \code{\link{generateRandomSp}}
#' then the function will automatically make the appropriate plots.
#' 
#' Otherwise, you can provide a raster layer/stack of environmental variables to
#'  \code{x} and a list of functions to \code{parameters} to perform the plot.
#' In that case, you have to specify the \code{approach}: \code{"reponse"} or
#' \code{"PCA"}:
#' \itemize{
#' \item{if \code{approach = "response"}: Provide to \code{parameters} a 
#' \code{list} exactly as defined in \code{\link{generateSpFromFun}}:\cr
#' \code{list(
#'            var1 = list(fun = 'fun1', args = list(arg1 = ..., arg2 = ..., etc.)),
#'            var2 = list(fun = 'fun2', args = list(arg1 = ..., arg2 = ..., etc.)))}\cr
#' 
#' }
#' \item{if \code{approach = "PCA"}: Provide to \code{parameters} a
#' \code{list} containing the following elements:
#' \itemize{
#' \item{\code{pca}: a \code{dudi.pca} object computed  with 
#' \code{\link[ade4]{dudi.pca}}}
#' \item{\code{means}: a vector containing two numeric values. Will be used to define
#' the means of the gaussian response functions to the axes of the PCA.}
#' \item{\code{sds} a vector containing two numeric values. Will be used to define
#' the standard deviations of the gaussian response functions to the axes of 
#' the PCA.}}
#' }
#' }
#' @export
#' @import terra
#' @author
#' Boris Leroy \email{leroy.boris@@gmail.com}
#' 
#' with help from C. N. Meynard, C. Bellard & F. Courchamp
#' @examples
#' # Create an example stack with four environmental variables
#' a <- matrix(rep(dnorm(1:100, 50, sd = 25)), 
#'             nrow = 100, ncol = 100, byrow = TRUE)
#' env <- c(rast(a * dnorm(1:100, 50, sd = 25)),
#'          rast(a * 1:100),
#'          rast(a * logisticFun(1:100, alpha = 10, beta = 70)),
#'          rast(t(a)))
#' names(env) <- c("var1", "var2", "var3", "var4")
#' 
#' # Per-variable response approach:
#' parameters <- formatFunctions(var1 = c(fun = 'dnorm', mean = 0.00012,
#'                                        sd = 0.0001),
#'                               var2 = c(fun = 'linearFun', a = 1, b = 0),
#'                               var3 = c(fun = 'quadraticFun', a = -20, b = 0.2, 
#'                                        c = 0),
#'                               var4 = c(fun = 'logisticFun', alpha = -0.001, 
#'                                        beta = 0.002))
#' sp1 <- generateSpFromFun(env, parameters, plot = TRUE)
#' plotResponse(sp1)
#' 
#' # PCA approach:
#' sp2 <- generateSpFromPCA(env, plot = FALSE)
#' par(mfrow = c(1, 1))
#' plotResponse(sp2)
#' 

plotResponse <- function(x, parameters = NULL, approach = NULL, rescale = NULL,
                         axes.to.plot = NULL, no.plot.reset = FALSE, 
                         rescale.each.response = NULL, ...)
{
  if(inherits(x, "Raster")) {
    x <- rast(x)
  }
  if(inherits(x, "SpatRaster")) 
  {
    # if(any(is.na(maxValue(x, warn = FALSE))))
    # {
    #   x <- setMinMax(x)
    # }
    if (length(approach) > 1) {
      stop("Only one approach can be plotted at a time")
    }
    if (approach == "response") {
      if (!is.list(parameters))
      {
        stop("If you choose the response approach please provide the parameters")
      }
      if(nlyr(x) != length(parameters)) 
      {
        stop("Provide as many layers in x as functions on parameters")
      }
      if(any(!(names(parameters) %in% names(x)) | !(names(x) %in% names(parameters))))
      {
        stop("Layer names and names of parameters must be identical")
      }
      for (var in names(x))
      {
        parameters[[var]]$min <- global(x[[var]], "min", na.rm = TRUE)[1, 1]
        parameters[[var]]$max <- global(x[[var]], "max", na.rm = TRUE)[1, 1]
      }
      if(!is.null(rescale.each.response)){
        if(rescale.each.response) {
          rescale <- TRUE
        } else if (!rescale.each.response) {
          rescale <- FALSE
        } else {
          stop("rescale.each.response must be TRUE or FALSE")
        }
      } else {
        message("No default value was defined for rescale.each.response, ",
                "setting rescale.each.response = TRUE")
        rescale <- TRUE # We use rescale for the rest of the code 
        # but it corresponds to rescale.each.response here
      }
      
    } else if (approach == "pca")
    {
      if(any(!(parameters$variables %in% names(x))))
      {
        stop("The PCA does not seem to have been computed with the same variables
             as in x.")
      }
      if(!is.list(parameters)) {stop("Please provide an appropriate list of parameters to draw the plots
                                   (see the help for details)")}
      if(!all(class(parameters$pca) %in% c("pca", "dudi"))) 
      {stop ("Please provide an appropriate pca.object (output of dudi.pca()) to make the pca plot.\n
           If you don't know how to obtain the pca, try to first run generateSpFromPCA()
           and provide the output to plotResponse()")}
      if(!(is.numeric(parameters$means)) | !(is.numeric(parameters$sds)))
      {stop ("Please provide appropriate means & standard deviations to elements 'means' and 'sds' of parameters.
           If you don't know how to provide these, try to first run generateSpFromPCA() 
           to responsePlot()")
      }
      if(is.null(rescale)) {
        rescale <- TRUE
        message("Argument rescale was not specified, so it was automatically ",
                "defined to TRUE. Verify that this is what you want.")
      } 
      details <- parameters
    } else 
      if (approach == "bca") {
      if(any(!(parameters$variables %in% names(x))))
      {
        stop("The BCA does not seem to have been computed with the same variables
             as in x.")
      }
      if (!is.list(parameters))
      {
        
        stop("Please provide an appropriate list of parameters to draw the plots
                                     (see the help for details)")
      }
      if (!all(class(parameters$bca) %in% c("between", "dudi"))) 
      {
        stop ("Please provide an appropriate bca.object (output of bca()) to make the between component analysis plot.\n
             If you don't know how to obtain the between, try to first run generateSpFromPCA()
             and provide the output to plotResponse()")
      }
      if(!(is.numeric(parameters$means)) | !(is.numeric(parameters$sds)))
      {
        stop ("Please provide appropriate means & standard deviations to elements 'means' and 'sds' of parameters.
             If you don't know how to provide these, try to first run generateSpFromPCA() 
             to responsePlot()")
      }
      details <- parameters
    } else if (is.null(approach))
    {
      stop("Please choose the approach: 'response' or 'pca'.")
    }
    if(!is.null(rescale.each.response)){
      if(rescale.each.response) {
        rescale <- TRUE
      } else if (!rescale.each.response) {
        rescale <- FALSE
      } else {
        stop("rescale.each.response must be TRUE or FALSE")
      }
    } else {
      message("No default value was defined for rescale.each.response, ",
              "setting rescale.each.response = TRUE")
      rescale <- TRUE # We use rescale for the rest of the code 
      # but it corresponds to rescale.each.response here
    }
  } else if (inherits(x, "virtualspecies"))
  {
    if (any(!(c("approach", "details", "suitab.raster") %in% names(x)))) 
    {
      if(!length(grep("suitab.raster", names(x))))
      {
      stop("x does not seem to be a valid object:
                Either provide an output from functions	generateSpFromFun(),", 
           " generateSpFromPCA(), generateSpFromBCA() or generateRandomSp() or", 
           " a raster object")
      }
    }
    approach <- x$approach
    details <- x$details
    if (x$approach == "response") {
      rescale <- details$rescale.each.response
    } else if (x$approach == "pca") {
      rescale <- details$rescale
    }
    if("parameters" %in% names(details))
    {
      parameters <- x$details$parameters
    } else 
    {
      parameters <- NULL
    }
  } else
  {
    stop("x does not seem to be a valid object:
                Either provide an output from functions	generateSpFromFun(), generateSpFromPCA(), generateSpFromBCA() or generateRandomSp() or a raster object")
  }
  if (approach == "response")
  {
    mfrow <- c(floor(sqrt(length(parameters))),
               ceiling(sqrt(length(parameters))))
    if (prod(mfrow) < length(parameters)) {mfrow[1] <- mfrow[1] + 1}
    if(!no.plot.reset)
    {
      op <- graphics::par(no.readonly = TRUE)
    }
    graphics::par(mfrow = mfrow,
                  mar = c(4.1, 4.1, 0.1, 0.1))
    for(i in names(parameters))
    {
      cur.seq <- seq(parameters[[i]]$min,
                     parameters[[i]]$max,
                     length = 1000)
      if(rescale)
      {
        values <- do.call(match.fun(parameters[[i]]$fun), 
                          args = c(list(cur.seq), parameters[[i]]$args))

        values <- (values - min(values)) / (max(values) - min(values))
         
        # Formating plotting arguments
        defaults <- list(x = cur.seq, y = values, type = "l", bty = "l",
                         cex.axis = .7, ylab = "Suitability", xlab = "",
                         las = 1, cex = .5, cex.lab = 1)
        args <- utils::modifyList(defaults, list( ...))
        do.call("plot", args)
        graphics::mtext(side = 1, text = i, line = 2, cex = args$cex.lab)
      } else
      {
        values <- do.call(match.fun(parameters[[i]]$fun), 
                          args = c(list(cur.seq), parameters[[i]]$args))
        # Formating plotting arguments
        defaults <- list(x = cur.seq, 
                         y = values,
                         type = "l", bty = "l",
                         cex.axis = .7, ylab = "Suitability", xlab = "",
                         las = 1, cex = .5, cex.lab = 1)
        args <- utils::modifyList(defaults, list( ...))
        do.call("plot", args)
        graphics::mtext(side = 1, text = i, line = 2, cex = args$cex.lab)
      }
    }    
    if(!no.plot.reset)
    {
      graphics::par(op)
    }
  } else if (approach == "pca")
  {
    pca.object <- details$pca
    axes <- details$axes
    if(is.null(axes.to.plot))
    {
      axes.to.plot <- axes[1:2]
    } else if (length(axes.to.plot) != 2)
    {
      stop("Please provide 2 values in axes.to.plot (plot 3 or more axes at a time is currently unsupported)")
    } else if (any(!(axes.to.plot %in% axes)))
    {
      stop("Please provide axes.to.plot that are included in your PCA virtualspecies")
    }
    means <- details$means
    sds <- details$sds
    probabilities <- apply(pca.object$li[, axes], 1, .prob.gaussian, means = means, sds = sds)
    if(rescale) {
      probabilities <- (probabilities - details$min_prob_rescale) /
        (details$max_prob_rescale - details$min_prob_rescale)
    }

    
    xmin <- min(pca.object$li[, axes.to.plot[1]]) - 0.3 * diff(range(pca.object$li[, axes.to.plot[1]]))
    xmax <- max(pca.object$li[, axes.to.plot[1]])
    ymin <- min(pca.object$li[, axes.to.plot[2]]) - 0.3 * diff(range(pca.object$li[, axes.to.plot[2]]))
    ymax <- max(pca.object$li[, axes.to.plot[2]])
    
    if(!no.plot.reset)
    {
      op <- graphics::par(no.readonly = TRUE)
    }
    graphics::par(mar = c(4.1, 4.1, 4.1, 4.6))
    defaults <- list(x = pca.object$li[, axes.to.plot],
                     col = c(grDevices::grey(.8), rev(viridis::inferno(150)))[
                       match(round(probabilities * 100, 0), 0:100)],
                     xlim = c(xmin, xmax),
                     ylim = c(ymin, ymax),
                     main = paste0("PCA of environmental conditions\nAxes ", 
                                   paste0(axes.to.plot, collapse = " & "), 
                                   " (", length(axes),
                                   " axes included in total)"),
                     bty = "n",
                     las = 1, cex.axis = .7, pch = 16)
    args <- utils::modifyList(defaults, list(...))
    do.call("plot", defaults)
    
    i1 <- which(axes == axes.to.plot[1])
    i2 <- which(axes == axes.to.plot[2])
    
    graphics::polygon(
      sqrt((sds[i1] * cos(seq(0, 2 * pi, length = 100)))^2 +
             (sds[i2] * sin(seq(0, 2 * pi, length = 100)))^2) * 
        cos(atan2(sds[i2] * sin(seq(0, 2 * pi, length = 100)), 
                  sds[i1] * cos(seq(0, 2 * pi, length = 100)))) + means[i1],
      sqrt((sds[i1] * cos(seq(0, 2 * pi, length = 100)))^2 +
             (sds[i2] * sin(seq(0, 2 * pi, length = 100)))^2) * 
        sin(atan2(sds[i2] * sin(seq(0, 2 * pi, length = 100)), 
                  sds[i1] * cos(seq(0, 2 * pi, length = 100)))) + means[i2],
      col = NA, lty = 1, lwd = 1, border = NULL)
    
    graphics::par(xpd = F)
    graphics::segments(x0 = means[i1] - sds[i1], x1 = means[i1] - sds[i1],
                       y0 = ymin - 2 * diff(c(ymin, ymax)), 
                       y1 = means[i2], lty = 3)
    
    graphics::segments(x0 = means[i1] + sds[i1], x1 = means[i1] + sds[i1],
                       y0 = ymin - 2 * diff(c(ymin, ymax)),
                       y1 = means[i2], lty = 3)
    
    graphics::segments(x0 = xmin - 2 * diff(c(xmin, xmax)), 
                       x1 = means[i1],
                       y0 = means[i2] - sds[i2], y1 = means[i2] - sds[i2],
                       lty = 3)
    
    graphics::segments(x0 = xmin - 2 * diff(c(xmin, xmax)), 
                        x1 = means[i1],
                        y0 = means[i2] + sds[i2], y1 = means[i2] + sds[i2],
                        lty = 3)
    cutX <- diff(c(xmin, xmax)) * 2/3 + xmin
    cutY <- diff(c(ymin, ymax)) * 2/3 + ymin
    if(means[i1] <= cutX & means[i2] <= cutY)
    {
      x0 <- xmax - 0.15 * diff(c(xmin, xmax))
      y0 <- ymax - 0.15 * diff(c(ymin, ymax))
      x1 <- pca.object$co[, i1] + x0
      y1 <- pca.object$co[, i2] + y0
    } else if(means[i1] > cutX & means[i2] <= cutY)
    {
      x0 <- xmin + 0.25 * diff(c(xmin, xmax))
      y0 <- ymax - 0.15 * diff(c(ymin, ymax))
      x1 <- pca.object$co[, i1] + x0
      y1 <- pca.object$co[, i2] + y0
    } else if(means[i1] <= cutX & means[i2] > cutY)
    {
      x0 <- xmax - 0.15 * diff(c(xmin, xmax))
      y0 <- ymin + 0.25 * diff(c(ymin, ymax))
      x1 <- pca.object$co[, i1] + x0
      y1 <- pca.object$co[, i2] + y0
    } else if(means[i1] > cutX & means[i2] > cutY)
    {
      x0 <- xmin + 0.25 * diff(c(xmin, xmax))
      y0 <- ymin + 0.25 * diff(c(ymin, ymax))
      x1 <- pca.object$co[, i1] + x0
      y1 <- pca.object$co[, i2] + y0
    }
    
    graphics::par(xpd = T)
    x1y1 <- cbind(x1, y1)
    apply(x1y1, 1, FUN = function(x, a = x0, b = y0)
      {
        .arrows(x0 = a, y0 = b, x1 = x[1], y1 = x[2])
      })

    .arrowLabels(x = x1, y = y1,
                 label = rownames(pca.object$co), clabel = 1,
                 origin = c(x0, y0))

    graphics::legend(title = "Pixel\nsuitability", "topright", 
                     inset = c(-0.1, 0),
                     legend = c(1, 0.8, 0.6, 0.4, 0.2, 0),
                     pch = 16, col = c(viridis::inferno(150)[c(1, 38, 75, 
                                                               113, 150)],
                                       grDevices::grey(.8)), bty = "n")
    
    
    graphics::par(new = T)
    
    valY <- stats::dnorm(seq(xmin,
                             xmax, 
                             length = 1000), 
                         mean = means[i1], 
                         sd = sds[i1])
    valY <- 0.15 * (valY - min(valY))/(max(valY) - min(valY))
    valX <- seq(xmin, 
                xmax, 
                length = 1000)
    
    plot(valY ~ valX,
         col = grDevices::grey(.7),
         type = "l", bty = "n", 
         ylim = c(0, 1), 
         lty = 1,
         xlab = "", ylab = "", xaxt = "n", yaxt = "n")
    graphics::par(new = T)
    
    
    valY <- seq(ymin, 
                ymax,
                length = 1000)
    valX <- stats::dnorm(seq(ymin, 
                             ymax, 
                             length = 1000),
                         mean = means[2],
                         sd = sds[2])
    valX <- 0.15 * (valX - min(valX))/(max(valX) - min(valX))
    plot(valX,
         valY,
         col = grDevices::grey(.7),
         type = "l", bty = "n",
         xlim = c(0, 1), 
         lty = 1,
         xlab = "", ylab = "", xaxt = "n", yaxt = "n")
    
    if(!no.plot.reset)
    {
      graphics::par(op)
    }
  }  else if (approach == "bca") {
    bca.object     <- details$bca
    means          <- details$means
    sds            <- details$sds
    lengths        <- details$stack.lengths
    if(!length(rescale)) {
      rescale        <- details$rescale
    }

    
    probabilities <- apply(bca.object$ls, 1, .prob.gaussian, means = means, 
                           sds = sds)
    if(rescale) {
      probabilities <- (probabilities - details$min_prob_rescale) /
        (details$max_prob_rescale - details$min_prob_rescale)
    }
    
    xmin <- min(bca.object$ls[, 1]) - 0.3 * diff(range(bca.object$ls[, 1]))
    xmax <- max(bca.object$ls[, 1])
    ymin <- min(bca.object$ls[, 2]) - 0.3 * diff(range(bca.object$ls[, 2]))
    ymax <- max(bca.object$ls[, 2])
    
    graphics::par(mar = c(4.1, 4.1, 4.1, 6.1))
    
    defaults <- list(x = bca.object$ls,
                     #                    col = c(grey(.8), rev(heat.colors(150))[51:200]) [match(round(probabilities * 100, 0), 0:100)] ,
                     
                     col = c(grDevices::grey(.8), rev(viridis::inferno(150)))[
                       match(round(probabilities * 100, 0), 0:100)],
                     cex = .35,
                     pch = c(rep(15, lengths[1]),
                             rep(17, lengths[2] + 1)),
                     
                     # col = c( rep(grey(0.8),    lengths[1] ), 
                     #          rep(grey(0.5) ,   lengths[2] ), 
                     #          "white"),
                     
                     xlim = c(xmin, xmax), 
                     ylim = c(ymin, ymax),
                     main = "BCA of environmental conditions",
                     bty = "n",
                     las = 1, cex.axis = .7)

    
    args <- utils::modifyList(defaults, list(...))
    do.call("plot", defaults)

    
    #points(means[2] ~ means[1], pch = 16)
    graphics::polygon(
      sqrt((sds[1] * cos(seq(0, 2 * pi, length = 100)))^2 + 
             (sds[2] * sin(seq(0, 2 * pi, length = 100)))^2) * 
        cos(atan2(sds[2] * sin(seq(0, 2 * pi, length = 100)), 
                  sds[1] * cos(seq(0, 2 * pi, length = 100)))) + means[1],
      sqrt((sds[1] * cos(seq(0, 2 * pi, length = 100)))^2 + 
             (sds[2] * sin(seq(0, 2 * pi, length = 100)))^2) * 
        sin(atan2(sds[2] * sin(seq(0, 2 * pi, length = 100)), 
                  sds[1] * cos(seq(0, 2 * pi, length = 100)))) + means[2],
      col = NA, lty = 1, lwd = 1, border = NULL)
    
    graphics::par(xpd = F)
    graphics::segments(x0 = means[1] - sds[1], x1 = means[1] - sds[1],
                       y0 = ymin - 2 * diff(c(ymin, ymax)), 
                       y1 = means[2], lty = 3)
    
    graphics::segments(x0 = means[1] + sds[1], x1 = means[1] + sds[1],
                       y0 = ymin - 2 * diff(c(ymin, ymax)),
                       y1 = means[2], lty = 3)
    
    graphics::segments(x0 = xmin - 2 * diff(c(xmin, xmax)), 
                       x1 = means[1],
                       y0 = means[2] - sds[2], y1 = means[2] - sds[2], lty = 3)
    
    graphics::segments(x0 = xmin - 2 * diff(c(xmin, xmax)), 
                       x1 = means[1],
                       y0 = means[2] + sds[2], y1 = means[2] + sds[2], lty = 3)
    cutX <- diff(c(xmin, xmax)) * 2/3 + xmin
    cutY <- diff(c(ymin, ymax)) * 2/3 + ymin
    
    if(means[1] <= cutX & means[2] <= cutY)
    {
      x0 <- xmax - 0.15 * diff(c(xmin, xmax))
      y0 <- ymax - 0.15 * diff(c(ymin, ymax))
      x1 <- bca.object$c1[, 1] + x0
      y1 <- bca.object$c1[, 2] + y0
    } else if(means[1] > cutX & means[2] <= cutY)
    {
      x0 <- xmin + 0.25 * diff(c(xmin, xmax))
      y0 <- ymax - 0.15 * diff(c(ymin, ymax))
      x1 <- bca.object$c1[, 1] + x0
      y1 <- bca.object$c1[, 2] + y0
    } else if(means[1] <= cutX & means[2] > cutY)
    {
      x0 <- xmax - 0.15 * diff(c(xmin, xmax))
      y0 <- ymin + 0.25 * diff(c(ymin, ymax))
      x1 <- bca.object$c1[, 1] + x0
      y1 <- bca.object$c1[, 2] + y0
    } else if(means[1] > cutX & means[2] > cutY)
    {
      x0 <- xmin + 0.25 * diff(c(xmin, xmax))
      y0 <- ymin + 0.25 * diff(c(ymin, ymax))
      x1 <- bca.object$c1[, 1] + x0
      y1 <- bca.object$c1[, 2] + y0
    }
    
    graphics::par(xpd = T)
    x1y1 <- cbind(x1, y1)
    apply(x1y1, 1, FUN = function(x, a = x0, b = y0){
      .arrows(x0 = a, y0 = b, x1 = x[1], y1 = x[2])
    })
    
    .arrowLabels(x = x1, y = y1,
                 label = rownames(bca.object$c1), clabel = 1,
                 origin = c(x0, y0))
    
    
    graphics::legend("topright", inset = c(-.4,
                                           0),
                     legend = c("Current\nconditions\n","Future\nconditions"),
                     pch = c(15, 17), col = grDevices::grey(.8), bty = "n",
                     cex = .7,
                     xpd = TRUE)
    
    
    graphics::legend("topright",
                     inset = c(-.4,
                               .5),
                     legend = c(1, 0.8, 0.6, 0.4, 0.2, 0),
                     pch = 16, col = c(viridis::inferno(150)[c(1, 38, 75, 
                                                               113, 150)],
                                       grDevices::grey(.8)), bty = "n",
                     cex = .7,
                     title = "Pixel\nsuitability",
                     xpd = TRUE)
    
    
    
    
    graphics::par(new = T)
    
    valY <- stats::dnorm(seq(xmin, xmax,length = 1000), 
                         mean = means[1], 
                         sd = sds[1])
    valY <- 0.15 * (valY - min(valY))/(max(valY) - min(valY))
    valX <- seq(xmin, xmax, length = 1000)
    
    plot(valY ~ valX,
         type = "l", bty = "n", 
         ylim = c(0, 1), 
         lty = 1,
         xlab = "", ylab = "", xaxt = "n", yaxt = "n")
    graphics::par(new = T)
    
    valY <- seq(ymin, ymax, length = 1000)
    valX <- stats::dnorm(seq(ymin, ymax,length = 1000),
                         mean = means[2],
                         sd = sds[2])
    valX <- 0.15 * (valX - min(valX))/(max(valX) - min(valX))
    plot(valX,
         valY,
         type = "l", bty = "n",
         xlim = c(0, 1), 
         lty = 1,
         xlab = "", ylab = "", xaxt = "n", yaxt = "n")
    
    
  } else 
  {
    stop("The argument approach was not valid, please provide either 'response' or 'pca'")
  }
}



.arrows <- function(x0, y0, x1, y1, len = 0.1, ang = 15, lty = 1, 
                   edge = TRUE) 
{
  d0 <- sqrt((x0 - x1)^2 + (y0 - y1)^2)
  if (d0 < 1e-07) 
    return(invisible())
  graphics::segments(x0, y0, x1, y1, lty = lty)
  h <- graphics::strheight("A", cex = graphics::par("cex"))
  if (d0 > 2 * h) {
    x0 <- x1 - h * (x1 - x0)/d0
    y0 <- y1 - h * (y1 - y0)/d0
    if (edge) 
      graphics::arrows(x0, y0, x1, y1, angle = ang, length = len, 
                       lty = 1)
  }
}


.arrowLabels <- function(x, y, label, clabel, origin = c(0, 0), boxes = FALSE) 
{
  xref <- x - origin[1]
  yref <- y - origin[2]
  for (i in 1:(length(x))) {
    cha <- as.character(label[i])
    cha <- paste(" ", cha, " ", sep = "")
    cex0 <- graphics::par("cex") * clabel
    xh <- graphics::strwidth(cha, cex = cex0)
    yh <- graphics::strheight(cha, cex = cex0) * 5/6
    if ((xref[i] > yref[i]) & (xref[i] > -yref[i])) {
      x1 <- x[i] + xh/2
      y1 <- y[i]
    }
    else if ((xref[i] > yref[i]) & (xref[i] <= (-yref[i]))) {
      x1 <- x[i]
      y1 <- y[i] - yh
    }
    else if ((xref[i] <= yref[i]) & (xref[i] <= (-yref[i]))) {
      x1 <- x[i] - xh/2
      y1 <- y[i]
    }
    else if ((xref[i] <= yref[i]) & (xref[i] > (-yref[i]))) {
      x1 <- x[i]
      y1 <- y[i] + yh
    }
    if (boxes) {
      graphics::rect(x1 - xh/2, y1 - yh, x1 + xh/2, y1 + yh, col = "white", 
                     border = 1)
    }
    text(x1, y1, cha, cex = cex0)
  }
}
