# The title and side panels

# Title panel ------

  title_panel <- function() {

     titlePanel(title =  HTML("<div class = 'title'>
                                   <strong>Celltrax:</strong>
                                   pre-process tracking data
                                   <img src = '' width = 45%>
                                   <img src = 'mui_logo.png' width = 5%><br/>
                                   <div/>
                                   <hr style = 'height: 5px'>"),
                windowTitle = 'Celltrax tools')

   }

# Side panel ------

  side_panel <- function() {

    sidebarPanel(h4('Step 1'),
                 h5('Upload your tracking data as a tab-separated text'),
                 radioButtons(inputId = 'upload_type',
                              label = 'File type',
                              choices = list('single file' = 'single',
                                             'X, Y and Z coordinate files' = 'compound'),
                              selected = 'single',
                              inline = TRUE),
                 uiOutput(outputId = 'upload_ui'),
                 uiOutput(outputId = 'selectors'),
                 uiOutput(outputId = 'sample_ui'),
                 h4('Step 2'),
                 fluidRow(column(width = 6,
                                 h5('Start the pre-processing')),
                          column(width = 6,
                                 align = 'center',
                                 disabled(actionBttn(inputId = 'launcher',
                                                     icon = icon(name = 'play',
                                                                 lib = 'glyphicon'),
                                                     style = 'unite',
                                                     color = 'warning')))),
                 br(),
                 br(),
                 h4('Step 3 (optional)'),
                 h5('Adjust the pre-processing parameters, step by step'),
                 br(),
                 h4('Step 4'),
                 h5('Download the processed data'),
                 br(),
                 h4('Step 5'),
                 fluidRow(column(width = 6,
                                 h5('Start with a new sample')),
                          column(width = 6,
                                 align = 'center',
                                 actionBttn(inputId = 'refresh',
                                            icon = icon(name = 'refresh',
                                                        lib = 'glyphicon'),
                                            style = 'unite',
                                            color = 'warning'))),
                 br(),
                 h4('Analysis progress'),
                 progressBar(id = 'pb',
                             value = 0,
                             total = 7,
                             title = ''),
                 br(),
                 h4('Graphics setting'),
                 sliderInput(inputId = 'coverage',
                             label = '% of tracks plotted',
                             min = 10,
                             max = 100,
                             value = 100),
                 width = 3,
                 bsTooltip(id = 'launcher',
                           title = 'start the pre-processing once a file is provided'),
                 bsTooltip(id = 'refresh',
                           title = 'start over with a new sample'))

  }

# END -----
