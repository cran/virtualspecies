#' Generate a virtual species distributions with responses to environmental
#'  variables
#' 
#' This function generates a virtual species distribution from a stack of
#'  environmental
#' variables and a defined set of responses to each environmental parameter.
#' 
#' @param raster.stack a SpatRaster object, in which each layer represent an 
#' environmental 
#' variable.
#' @param parameters a list containing the functions of response of the species
#'  to environmental variables with their parameters. See details.
#' @param rescale \code{TRUE} or \code{FALSE}. If \code{TRUE}, the final 
#' probability of presence is rescaled between 0 and 1.
#' @param formula a character string or \code{NULL}. The formula used to combine
#'  partial responses into the final
#' environmental suitability value (e.g., \code{"layername1 + 2 * layername2 +
#' layername3 * layername4 etc."}). If \code{NULL} then partial responses will 
#' be added or multiplied according to
#' \code{species.type}
#' @param species.type \code{"additive"} or \code{"multiplicative"}. Only used 
#' if \code{formula = NULL}. 
#' Defines how the final environmental suitability is calculated: if 
#' \code{"additive"}, responses to each
#' variable are summed; if \code{"multiplicative"}, responses are multiplied.
#' @param rescale.each.response \code{TRUE} or \code{FALSE}. If \code{TRUE}, 
#' the individual responses to
#' each environmental variable are rescaled between 0 and 1 (see details).
#' @param plot \code{TRUE} or \code{FALSE}. If \code{TRUE}, the generated 
#' virtual species will be plotted.
#' @return a \code{list} with 3 elements:
#' \itemize{
#' \item{\code{approach}: the approach used to generate the species, 
#' \emph{i.e.}, \code{"response"}}
#' \item{\code{details}: the details and parameters used to generate the 
#' species}
#' \item{\code{suitab.raster}: the raster containing the environmental 
#' suitability of the virtual species}
#' }
#' The structure of the virtualspecies object can be seen using \code{str()}
#' @seealso \code{\link{generateSpFromPCA}} to generate a virtual species with 
#' a PCA approach
#' @details
#' \href{http://borisleroy.com/virtualspecies_tutorial/02-response.html}{Online 
#' tutorial for this function}
#' 
#' This function proceeds in two steps:
#' \enumerate{
#' \item{The response to each environmental variable is calculated with the 
#' functions provided
#' in \code{parameters}. This results in a suitability  of each variable.
#' 
#' \bold{By default, each response is rescaled between 0 and 1.} Disable with 
#' \code{rescale.each.response = FALSE}}
#' \item{The final environmental suitability is calculated according to the 
#' chosen \code{species.type}.
#' 
#' \bold{By default, the final suitability is rescaled between 0 and 1.} 
#' Disable with 
#' \code{rescale = FALSE}}
#' }
#' The SpatRaster stack containing environmental variables must have consistent 
#' names, 
#' because they will be checked with the \code{parameters}. For example, they 
#' can be named
#' var1, var2, etc. Names can be checked and set with \code{names(my.stack)}.
#' 
#' The \code{parameters} have to be carefully created, otherwise the function 
#' will not work:
#' \itemize{
#' \item{Either see \code{\link{formatFunctions}} to easily create your list of 
#' parameters}
#' \item{Or create a \code{list} defined according to the following template:\cr
#' \code{list(
#'            var1 = list(fun = 'fun1', args = list(arg1 = ..., arg2 = ..., 
#'            etc.)),
#'            var2 = list(fun = 'fun2', args = list(arg1 = ..., arg2 = ..., 
#'            etc.)))}\cr
#' It is important to keep the same names in the parameters as in the stack of 
#' environmental
#' variables. Similarly, argument names must be identical to argument names in 
#' the associated 
#' function (e.g., if you use \code{fun = 'dnorm'}, then args should look like 
#' \code{list(mean = 0, sd = 1)}).
#' 
#' See the example section below for more examples.}}
#'            
#' 
#' Any response function that can be applied to the environmental variables can
#' be chosen here. Several functions are proposed in this package:
#' \code{\link{linearFun}}, \code{\link{logisticFun}} and 
#' \code{\link{quadraticFun}}.
#' Another classical example is the normal distribution: 
#' \code{\link[stats:Normal]{stats::dnorm()}}.
#' Users can also create and use their own functions very easily.
#' 
#'   
#' If \code{rescale.each.response = TRUE}, then the probability response to each
#' variable will be normalised between 0 and 1 according to the following 
#' formula:
#' P.rescaled = (P - min(P)) / (max(P) - min (P))
#' This rescaling has a strong impact on response functions, so users may 
#' prefer to
#' use \code{rescale.each.response = FALSE} and apply their own rescaling within
#' their response functions.
#' 
#' 
#' @import terra
#' @export
#' @author
#' Boris Leroy \email{leroy.boris@@gmail.com}
#' 
#' with help from C. N. Meynard, C. Bellard & F. Courchamp
#' @examples
#' # Create an example stack with two environmental variables
#' a <- matrix(rep(dnorm(1:100, 50, sd = 25)), 
#'             nrow = 100, ncol = 100, byrow = TRUE)
#' env <- c(rast(a * dnorm(1:100, 50, sd = 25)),
#'          rast(a * 1:100))
#' names(env) <- c("variable1", "variable2")
#' plot(env) # Illustration of the variables
#' 
#' # Easy creation of the parameter list:
#' # see in real time the shape of the response functions
#' parameters <- formatFunctions(variable1 = c(fun = 'dnorm', mean = 1e-04, 
#'                                              sd = 1e-04),
#'                               variable2 = c(fun = 'linearFun', a = 1, b = 0))
#'                               
#' # If you provide env, then you can see the shape of response functions:
#' parameters <- formatFunctions(x = env,
#'                               variable1 = c(fun = 'dnorm', mean = 1e-04, 
#'                                              sd = 1e-04),
#'                               variable2 = c(fun = 'linearFun', a = 1, b = 0))
#' 
#' # Generation of the virtual species
#' sp1 <- generateSpFromFun(env, parameters)
#' sp1
#' par(mfrow = c(1, 1))
#' plot(sp1)
#' 
#' 
#' # Manual creation of the parameter list
#' # Note that the variable names are the same as above
#' parameters <- list(variable1 = list(fun = 'dnorm',
#'                                     args = list(mean = 0.00012,
#'                                                 sd = 0.0001)),
#'                    variable2 = list(fun = 'linearFun',
#'                                     args = list(a = 1, b = 0)))
#' # Generation of the virtual species
#' sp1 <- generateSpFromFun(env, parameters, plot = TRUE)
#' sp1
#' plot(sp1)


generateSpFromFun <- function(raster.stack, parameters, 
                              rescale = TRUE, formula = NULL, 
                              species.type = "multiplicative",
                              rescale.each.response = TRUE,
                              plot = FALSE)
{
  if(inherits(raster.stack, "Raster")) {
    raster.stack <- rast(raster.stack)
  }
  message("Generating virtual species environmental suitability...\n")
  approach <- "response"
  if(!(inherits(raster.stack, "SpatRaster")))
  {
    stop("raster.stack must be a SpatRaster object")
  }
  # if(any(is.na(maxValue(raster.stack))))
  # {
  #   raster.stack <- setMinMax(raster.stack)
  # }
  n.l <- nlyr(raster.stack)
  if(n.l != length(parameters)) 
  {stop("Provide as many layers in raster.stack as functions on parameters")}
  if(any(!(names(parameters) %in% names(raster.stack)) |
           !(names(raster.stack) %in% names(parameters))))
     {stop("Layer names and names of parameters must be identical")}
  # Checking the structure and consistency of parameters
  for (i in 1:length(parameters))
  {
    if(any(!(c("fun", "args") %in% names(parameters[[i]]))))
    {stop("The structure of parameters does not seem correct.", 
          "Please provide function and arguments for variable '",
          names(parameters)[i], 
          "'. See help(generateSpFromFun) for more details.",
          sep = "")}
    test <- tryCatch(match.fun(parameters[[i]]$fun), 
                     error = function(c) "error")
    if(!inherits(test, "function"))
    {
      stop(paste("The function ", parameters[[i]]$fun, 
                 " does not exist, please verify spelling.", sep = ""))
    }
    if(any(!(names(parameters[[i]]$args) %in% names(formals(fun = test)))))
    {
      stop(paste("Arguments of variable '", names(parameters)[i], "' (", 
                 paste(names(parameters[[i]]$args), collapse = ", "), 
                 ") do not match arguments of the associated function\n
                 List of possible arguments for this function: ",
                 paste(names(formals(fun = test)), collapse = ", "), sep = ""))
    }
    rm(test)
  }
  # Adding a message to inform users about the default rescaling of variables
  if(rescale.each.response)
  {
    message(" - The response to each variable was rescaled between 0 and 1. To
            disable, set argument rescale.each.response = FALSE\n") 
  }
  if(rescale)
  {
    message(" - The final environmental suitability was rescaled between 0", 
    " and 1. To disable, set argument rescale = FALSE\n") 
  }
  
    
    
  suitab.raster <- rast(lapply(names(raster.stack), FUN = function(y) {
    app(raster.stack[[y]], fun = function(x)
    {
      do.call(match.fun(parameters[[y]]$fun), args = c(list(x), 
                                                       parameters[[y]]$args))
    }
    )
  }))
  names(suitab.raster) <- names(parameters)
  
  for (var in names(raster.stack))
  {
    parameters[[var]]$min <- global(raster.stack[[var]], "min", 
                                    na.rm = TRUE)[1, 1]
    parameters[[var]]$max <- global(raster.stack[[var]], "max",
                                    na.rm = TRUE)[1, 1]
  }
  
  if(rescale.each.response)
  {
    suitab.raster <- rast(lapply(names(suitab.raster), function(y)
      {
        (suitab.raster[[y]] - global(suitab.raster[[y]], 
                                     "min", na.rm = TRUE)[1, 1]) / 
        (global(suitab.raster[[y]], "max", na.rm = TRUE)[1, 1] - 
           global(suitab.raster[[y]], "min", na.rm = TRUE)[1, 1])
      }))
  }

  
  if(is.null(formula))
  {
    if(species.type == "multiplicative")
    {
      formula <- paste(names(suitab.raster), collapse = " * ")
      suitab.raster <- app(suitab.raster, fun = prod)
    } else if (species.type == "additive")
    {
      formula <- paste(names(suitab.raster), collapse = " + ")
      suitab.raster <- app(suitab.raster, fun = sum)
    } else stop("If you do not provide a formula, please choose either ", 
                "species.type = 'additive' or 'multiplicative'")
  } else
  {
    if(any(!(all.vars(stats::reformulate(formula)) %in% names(suitab.raster))))
    {
      stop("Please verify that the variable names in your formula are ", 
           "correctly spelled") 
    } else if(any(!(names(suitab.raster) %in% 
                    all.vars(stats::reformulate(formula)))))
    {
      stop("Please verify that your formula contains all the variables of ", 
           "your input raster stack")
    } else
    {
      custom.fun <- NULL # To remove the note in rcheck
      eval(parse(text = paste("custom.fun <- function(",
                              paste(names(suitab.raster), collapse = ", "),
                              ") {",
                              formula,
                              "}"
      )))
      suitab.raster <- lapp(suitab.raster, fun = custom.fun)
      print(formula)
    }
  }

  if(rescale)
  {
    suitab.raster <- (suitab.raster - global(suitab.raster, 
                                             "min", na.rm = TRUE)[1, 1]) / 
      (global(suitab.raster, "max", na.rm = TRUE)[1, 1] - 
         global(suitab.raster, "min", na.rm = TRUE)[1, 1])
  }
  names(suitab.raster) <- "VSP suitability"
    

  results <- list(approach = approach,
                  
                  details = list(variables = names(parameters),
                                 formula = formula,
                                 rescale.each.response = rescale.each.response,
                                 rescale = rescale,
                                 parameters = parameters),
                  suitab.raster = wrap(suitab.raster,
                                       proxy = FALSE)
  )
  class(results) <- append("virtualspecies", class(results))
  
  if(plot)
  {
    plot(results$suitab.raster, 
         main = "Environmental suitability of the virtual species",
         col = viridis::viridis(20))
  }
  

  return(results)
}
