module GroupCompliance.ViewNodesCompliance exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List
import List.Extra
import String
import Tuple3
import Dict

import GroupCompliance.ApiCalls exposing (..)
import GroupCompliance.DataTypes exposing (..)
import GroupCompliance.ViewUtils exposing (..)
import Compliance.Utils exposing (displayComplianceFilters, filterDetailsByCompliance)


displayNodesComplianceTable : Model -> Html Msg
displayNodesComplianceTable model =
  let
    filters = model.ui.nodeFilters
    complianceFilters = model.ui.complianceFilters
    fun     = byNodeCompliance model complianceFilters
    col     = "Node"
    childs  = case model.groupCompliance of
      Just dc -> dc.nodes
      Nothing -> []
    childrenSort = childs
      |> List.filter (\n -> (filterSearch filters.filter (searchFieldNodeCompliance n)))
      |> List.filter (filterDetailsByCompliance complianceFilters)
      |> List.sortWith sort

    (children, order, newOrder) = case sortOrder of
       Asc -> (childrenSort, "asc", Desc)
       Desc -> (List.reverse childrenSort, "desc", Asc)

    rowId = "by" ++ col ++ "s/"
    rows = List.map Tuple3.first fun.rows
    (sortId, sortOrder) = Dict.get rowId filters.openedRows |> Maybe.withDefault (col, Asc)
    sort =   case List.Extra.find (Tuple3.first >> (==) sortId) fun.rows of
      Just (_,_,sortFun) -> (\i1 i2 -> sortFun (fun.data model i1) (fun.data model i2))
      Nothing -> (\_ _ -> EQ)
    isGlobalMode = isGlobalCompliance model
  in
    ( if model.ui.loading then
      generateLoadingTable
      else
      div[]
      [ div [class "table-header extra-filters"]
        [ div [class "d-inline-flex align-items-baseline pb-3 w-25"]
          [
            div [class "btn-group yesno"]
            [ label [class ("btn btn-default" ++ if isGlobalMode then " active" else ""), style "box-shadow" (if isGlobalMode then "inset 0 3px 5px rgba(0,0,0,.125)" else "none"), onClick (LoadCompliance GlobalCompliance)]
              [text "Global"]
            , label [class ("btn btn-default" ++ if isGlobalMode then "" else " active"), style "box-shadow" (if isGlobalMode then "none" else "inset 0 3px 5px rgba(0,0,0,.125)"), onClick (LoadCompliance TargetedCompliance)]
              [text "Targeted"]
            ]
            , span [class "mx-3"]
              [text "Compliance"]
          ]
        ,  div[class "main-filters"]
          [ input [type_ "text", placeholder "Filter", class "input-sm form-control", value filters.filter, onInput (\s -> (UpdateFilters {filters | filter = s} ))][]
          , button [class "btn btn-default btn-sm btn-icon", onClick (UpdateComplianceFilters {complianceFilters | showComplianceFilters = not complianceFilters.showComplianceFilters}), style "min-width" "170px"]
            [ text ((if complianceFilters.showComplianceFilters then "Hide " else "Show ") ++ "compliance filters")
            , i [class ("fa " ++ (if complianceFilters.showComplianceFilters then "fa-minus" else "fa-plus"))][]
            ]
          ]
        , displayComplianceFilters complianceFilters UpdateComplianceFilters
        ]
      , div[class "table-container"]
        [ table [class "dataTable compliance-table"]
          [ thead []
            [ tr [ class "head" ]
              ( List.map (\row -> th [onClick (ToggleRowSort rowId row (if row == sortId then newOrder else Asc)), class ("sorting" ++ (if row == sortId then "_"++order else ""))] [ text row ]) rows )
            ]
          , tbody []
            ( if List.length childs <= 0 then
              [ tr[]
                [ td[class "empty", colspan 2][i [class"fa fa-exclamation-triangle"][], text "There is no compliance for this group."] ]
              ]
            else if List.length children == 0 then
              [ tr[]
                [ td[class "empty", colspan 2][i [class"fa fa-exclamation-triangle"][], text "No nodes match your filter."] ]
              ]
            else
              List.concatMap (\d ->  showComplianceDetails fun d "" filters.openedRows model) children
            )
          ]
        ]
      ])
