module ViewModel.Frame exposing (..)

import AppDrawer.GroupViewModel
import AppDrawer.Model


frameVM config model ( mainHeaderTitle, headerBackgroundColor ) pageContent =
    { contexts = AppDrawer.GroupViewModel.contexts config model
    , projects = AppDrawer.GroupViewModel.projects config model
    , mainHeaderTitle = mainHeaderTitle
    , headerBackgroundColor = headerBackgroundColor
    , mdl = model.mdl
    , maybeUser = config.maybeUser
    , sidebarHeaderTitle =
        if model.config.isDevelopmentMode then
            "Dev v" ++ model.config.npmPackageVersion
        else
            "SimpleGTD.com"
    , appVersionString = "v" ++ model.config.npmPackageVersion
    , isSideBarOverlayOpen = AppDrawer.Model.getIsOverlayOpen model.appDrawerModel
    , config = config
    , model = model
    , pageContent = pageContent
    }
