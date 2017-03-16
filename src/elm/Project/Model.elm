module Project.Model exposing (Project)


type alias ProjectName =
    String


type ProjectType
    = InboxProject
    | CustomProject ProjectName


type alias Project =
    { id : String, type_ : ProjectType }
