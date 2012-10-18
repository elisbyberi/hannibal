class @RickshawUtil

  class @LeftAlignedXAxis extends Rickshaw.Graph.Axis.X
    constructor: ->
      super

      oldRender = @render
      @render = ->
        oldRender.apply(@)
        @vis.selectAll('text').attr('text-anchor', 'start')

  class @InteractiveHoverDetail extends Rickshaw.Graph.HoverDetail
    initialize: (args) ->
      @onClick = args["onClick"];
      @onOver = args["onOver"];
      @onOut = args["onOut"];
      args["onRender"] = (renderArgs)=>
        hoveredSeries = _.find(renderArgs.detail, (d)-> d.active)
        if hoveredSeries?
          @hoveredSeries = hoveredSeries
          if typeof @onOver == "function"
            @onOver hoveredSeries
        else
          @hoveredSeries = null
      args["onHide"] = () =>
        @hoveredSeries = null
        if typeof @onOut == "function"
          @onOut()
      super args
    _addListeners: () ->
      this.graph.element.addEventListener 'click', (e) =>
        if @hoveredSeries
          if typeof @onClick == "function"
            @onClick @hoveredSeries
      super()

  class @ThresholdLine
    constructor: (args) ->
      if args.graph.renderer.name != "bar"
        throw "ThresholdLine only works with 'bar' renderer right now"

      graph = args.graph
      legend = args.legend
      threshold = args.threshold
      name = args.name
      color = args.color
      disabled = args.disabled

      graph.registerRenderer(new ThresholdBarRenderer({graph: graph}))
      graph.setRenderer('thresholdbar')

      splitsize = {
        name: name,
        threshold: threshold,
        color: color,
        disabled: disabled,
        disable: () ->
          @disabled = true
          graph.update()
        enable: () ->
          @disabled = false
          graph.update()
      }

      graph.series.splitsize = splitsize
      legend.addLine(splitsize)

    class ThresholdBarRenderer extends Rickshaw.Graph.Renderer.Bar
      name: 'thresholdbar'

      initialize: (args) ->
        super args

      domain: ($super) ->
        domain = super($super)
        if !@graph.series.splitsize.disabled
          domain.y[1] = Math.max(@graph.series.splitsize.threshold * 1.05, domain.y[1])
        domain

      render: () ->
        super()
        if !@graph.series.splitsize.disabled
          graph = @graph
          nodes = graph.vis.selectAll("path")
            .data([{x:0, y:@graph.series.splitsize.threshold}])
            .enter().append("svg:rect")
            .attr("x", (d) -> graph.x(d.x) )
            .attr("y", (d) -> graph.y(d.y) )
            .attr("width", graph.width)
            .attr("height", 1)
          nodes[0][0].setAttribute("fill", "#ff0000")

  @humanReadableBytes: (bytes) ->
    prefixes = ["bytes", "kB", "MB", "GB", "TB", "PB"]
    exponent = Math.floor(Math.log(bytes) / Math.log(1024))
    return (bytes / Math.pow(1024, Math.floor(exponent))).toFixed(2) + " " + prefixes[exponent]


