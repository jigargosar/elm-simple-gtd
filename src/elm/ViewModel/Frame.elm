module ViewModel.Frame exposing (..)

import AppDrawer.GroupViewModel
import AppDrawer.Model
import Firebase


frameVM config model ( mainHeaderTitle, headerBackgroundColor ) pageContent =
    { contexts = AppDrawer.GroupViewModel.contexts config model
    , projects = AppDrawer.GroupViewModel.projects config model
    , mainHeaderTitle = mainHeaderTitle
    , headerBackgroundColor = headerBackgroundColor
    , mdl = model.mdl
    , maybeUser = Firebase.getMaybeUser model
    , sidebarHeaderTitle =
        if model.developmentMode then
            "Dev v" ++ model.appVersion
        else
            "SimpleGTD.com"
    , appVersionString = "v" ++ model.appVersion
    , isSideBarOverlayOpen = AppDrawer.Model.getIsOverlayOpen model.appDrawerModel
    , config = config
    , model = model
    , pageContent = pageContent
    }
