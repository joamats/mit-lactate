pkgInstall <- function(packages = "requirements") {
    
    if (length( packages ) == 1L && packages == "requirements") {
        packages <- scan(file = "setup/R_requirements.txt", what = "character", skip = 0L)
    }

    packagecheck <- match(packages, utils::installed.packages()[, 1])

    packagestoinstall <- packages [is.na(packagecheck)]

    if (length(packagestoinstall) > 0L ) {
        utils::install.packages(packagestoinstall, repos = "http://cran.csiro.au"
        )
    } else {
        print( "All requested packages already installed" )
    }

    for (package in packages) {
        suppressPackageStartupMessages(
            library( package, character.only = TRUE, quietly = TRUE )
        )
    }

}

pkgInstall()