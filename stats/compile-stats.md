### update with imports (irrespective of case calls commented)

* 2.8s main
* 4.3s update
* 4.1s view

### update removed from main
* 1.2s main
* 1.8s view


#update imports (case calls commented)
* 3.4s Update.Todo
* 3.5s Update.Entity
* 4.1s Update.GroupDoc
* 4.1s all

# after mapping cmd
* 3.7s Update.Entity
* 3.8s when in-lining small update methods
* 3.8s after extracting Dispatch update method.
* 3.7s after removing model and return dep.
* 3.7s even after adding model and return dep.
* 3.9s after adding D_SetFocusInEntity
* 3.8s after adding D_SetFocusInEntityWithEntityId
* 3.7s-3.8s random even after adding (D_SetFocusInEntity, D_SetFocusInEntityWithEntityId)
* 3.6s after passing tagger to inner updates
* 3.5s Update.LaunchBar
* 3.1s Update.Todo

# after using config -> msg & returnMsgAsCmd internally 
* 2.7s Update.Subscription 


# after removing all andThenUpdate and using returnMsgAsCmd.
* 2.3s Update

# after some changes (update config extraction)
* 2.12 main
* 2.76 Update

# after adding viewConfig :(
* 3.00s Update
* 2.17 Main
