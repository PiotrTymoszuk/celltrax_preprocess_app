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
                 h5('Start the pre-processing'),
                 actionButton(inputId = 'launcher',
                              label = 'Launch'),
                 br(),
                 br(),
                 h4('Step 3 (optional)'),
                 h5('Adjust the pre-processing parameters, step by step'),
                 br(),
                 h4('Step 4'),
                 h5('Download the processed data'),
                 br(),
                 h4('Step 5'),
                 h5('Start with a new sample'),
                 actionButton(inputId = 'refresh',
                              label = 'Reset form'),
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
                 width = 3)

  }

# END -----
