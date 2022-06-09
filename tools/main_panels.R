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
                 h5('Upload your tracking data in a tab-separated text file'),
                 fileInput(inputId = 'single_entry',
                           label = 'Choose the file',
                           multiple = FALSE,
                           accept = c('.tsv', '.csv', '.txt')),
                 h5('Or, upload tab-separated text files with X, Y and Z coordinates'),
                 fileInput(inputId = 'x_entry',
                           label = 'X coordinate file',
                           multiple = FALSE,
                           accept = c('.tsv', '.csv', '.txt')),
                 fileInput(inputId = 'y_entry',
                           label = 'Y coordinate file',
                           multiple = FALSE,
                           accept = c('.tsv', '.csv', '.txt')),
                 fileInput(inputId = 'z_entry',
                           label = 'Z coordinate file (optional)',
                           multiple = FALSE,
                           accept = c('.tsv', '.csv', '.txt')),
                 h4('Step 2'),
                 h5('Start the pre-processing'),
                 actionButton(inputId = 'launcher',
                              label = 'Launch'),
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
