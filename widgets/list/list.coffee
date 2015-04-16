class Dashing.List extends Dashing.Widget

  onData: (data) ->
    sortedItems = new Batman.Set
    sortedItems.add.apply(sortedItems, data.items)
    @set 'items', sortedItems

  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
    else
      $(@node).find('ul').remove()
