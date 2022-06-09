# Tabsets for the main panel

# Tab 1: general information ------

  general_info <- function() {

    tabPanel('General information',
             h3('Welcome to celltrax tracing pre-processing tools!'),
             hr(),
             p("The celltrax pre-processing application is an interactive implementation of ",
               a(href = 'https://github.com/ingewortel/celltrackR', 'celltrackR'),
               " and ",
               a(href = 'https://github.com/PiotrTymoszuk/celltrax', 'celltrax'),
               " R packages for pre-processing and analysis of microscopy cell tracing data.
                                This online Shiny tool provides a platform for pre-processing
                                of user-provided cell tracking data in text form with most
                                commonly used settings.
                                The upper size limit of the raw data is 1000 tracks or 40000
                                steps.
                                For processing multiple samples, rich or untypical track
                                sets (i.e. motile macroscopic objects),
                                please resort, please resort to the seminal R packages."),
             br(),
             p("For help, please refer to the ",
               a(href = 'Manual.pdf', 'manual.'),
               "You may be also interested in experimenting with demo data provided as ",
               a(href = 'demo_data.zip', 'separate coordinate files'),
               " or as a ",
               a(href = 'well_2_tracks.tsv', 'single track text file.'),
               " or data sets accompanying the celltraceR package: ",
               a(href = 'b_cells_raw.tsv', 'unprocessed B cells'),
               ", ",
               a(href = 't_cells_raw.tsv', 'T cells'),
               " and ",
               a(href = 'neutros_raw.tsv', 'neutrophils.')),
             br(),
             p("The app developers put all efforts to develop and maintain qualitative cell tracing
                solutions but carry no responsibility for correctness and error-free functioning of
                the application. This tool may not be used for diagnostic and treatment purposes.
                For scientific use only."),
             hr(),
             em('By using the application you accept',
                a('the terms of use and licensing', href = 'Readme.pdf')),
             br(),
             HTML("<div style =  'text-align: right'>
                                  <img src = '' width = 80%>
                                  <p>Powered by </p>
                                  <a href = 'http://www.daas.tirol'>
                                  <img src = 'logo_large.png' width = 60 alt = 'daas.tirol'>
                                  </a>
                                  <img src = '' width = 30>
                                   <img src = 'shiny_logo.png' width = 60></div>"))

  }

# Tab 2: handling recognition errors -----

  handle_ai_errors <- function() {

    tabPanel('Cell recognition errors',
             h3('Correct for cell recogntion errors'),
             br(),
             p("Cell recognition errors manifest often as 'improbably' long displacements
               between two subsequent steps in the track. They handy way to correct for them
               is to split such tracks with a pre-defined, biologically sound displacement
               cutoff"),
             hr(),
             h4('Input data'),
             p('Former processing steps:'),
             p(tags$ol(tags$li('raw track import'))),
             hr(),
             h4('Displacement cutoff'),
             numericInput('d_cutoff',
                          label = 'Displacement cutoff',
                          value = 20,
                          min = 0),
             hr(),
             h4('Compare tracks'),
             plotOutput('split_tracks',
                        width = '100%',
                        height = '600px'))


  }

# Tab 3: short tracks ------

  handle_short_tracks <- function() {

    tabPanel('Short tracks',
             h3('Exclude short tracks'),
             br(),
             p("Too short tracks may impact on results of movement directionality
               analysis or trackk straightness. Hence, you may consider removing
               them from the data set."),
             hr(),
             h4('Input data'),
             p('Former processing steps:'),
             p(tags$ol(tags$li('raw track import'),
                       tags$li('cell recognition errors correction'))),
             hr(),
             h4('Minimal step length of tracks kept in the analysis'),
             numericInput('step_cutoff',
                          label = 'Minimal step number',
                          value = 4,
                          min = 2),
             hr(),
             h4('Compare tracks'),
             plotOutput('step_tracks',
                        width = '100%',
                        height = '600px'))

  }

# Tab 4: gap handling -------

  handle_gaps <- function() {

    tabPanel('Gap handling',
             h3('Repair gaps'),
             br(),
             p("Gaps in the track data set, i.e. steps with differing time intervals,
               may result from errors of the microscopy hardware or software and
               interfere with analysis of cell speed or displacement. This tool
               automatically screens your data for such gaps and allows for their correction
               with one of the following methods: 'drop' (elimination of gap tracks),
               'split' (splitting at the gap) or 'interpolate'
               (filling the gap with an additional step)."),
             hr(),
             h4('Input data'),
             p('Former processing steps:'),
             p(tags$ol(tags$li('raw track import'),
                       tags$li('cell recognition errors correction'),
                       tags$li('short track elimination'))),
             hr(),
             h4('Gap repair method'),
             selectInput(inputId = 'repair_method',
                         label = 'Repair method',
                         choices = list('drop' = 'drop',
                                        'split' = 'split',
                                        'interpolate' = 'interpolate'),
                         selected = 'split'),
             hr(),
             h4('Compare tracks'),
             plotOutput('gap_tracks',
                        width = '100%',
                        height = '600px'))

  }

# Tab 5: duplicate elimination -------

  handle_multiplets <- function() {

    tabPanel('Multiplet elimination',
             h3('Multiplet elimination and detection'),
             br(),
             p("Multiplets, i.e. two or more cells sticking together,
               may be a result of culture setup and conditions or
               microscopy errors. It is highly recommended, that you eliminate
               them prior to motility analysis. Such multiplets are recognized
               as cells pairs with a low cell - cell distance, usually
               approximate cell diameter, and a low angle between
               their total displacement vectors."),
             hr(),
             h4('Input data'),
             p('Former processing steps:'),
             p(tags$ol(tags$li('raw track import'),
                       tags$li('cell recognition errors correction'),
                       tags$li('short track elimination'),
                       tags$li('gap repair'))),
             hr(),
             h4('Multiplet elimination cutoffs'),
             fluidRow(column(6,
                             numericInput(inputId = 'dist_cutoff',
                                          label = 'Minimal cell - cell distance',
                                          value = 10,
                                          min = 0)),
                      column(6,
                             numericInput(inputId = 'angle_cutoff',
                                          label = 'Minimal angle',
                                          value = 10,
                                          min = 0,
                                          max = 90))),
             hr(),
             h4('Compare tracks'),
             plotOutput('multi_tracks',
                        width = '100%',
                        height = '600px'))

  }

# Tab 6: correct for drift ----

  adjust_drift <- function() {

    tabPanel('Drift correction (optional)',
             h3('Drift detection and correction'),
             br(),
             p("Drift, i.e. non-specific directional movement of cells,
               can result from microscopy errors and interfere severly
               with any motility analysis. To detect it or correct for it,
               a non-motile control is highly recommended. This tool
               calculates the average speed vector in your sample and allows
               for manual correction."),
             p("Important: make sure, the cell movement
               is unspecific before applying any manual adjustments!"),
             hr(),
             h4('Input data'),
             p('Former processing steps:'),
             p(tags$ol(tags$li('raw track import'),
                       tags$li('cell recognition errors correction'),
                       tags$li('short track elimination'),
                       tags$li('gap repair'),
                       tags$li('multiplet elimination'))),
             hr(),
             fluidRow(column(width = 6,
                             h4('Average velocity vector before adjustment'),
                             textOutput('raw_vector')),
                      column(width = 6,
                             h4('Average velocity vector after adjustment'),
                             textOutput('adj_vector'))),
             hr(),
             h4('Manual velocity adjustment'),
             fluidRow(column(width = 3,
                             numericInput(inputId = 'x_velo',
                                          label = 'X velocity',
                                          value = 0)),
                      column(width = 3,
                             numericInput(inputId = 'y_velo',
                                          label = 'Y velocity',
                                          value = 0)),
                      column(width = 3,
                             numericInput(inputId = 'z_velo',
                                          label = 'Z velocity',
                                          value = 0))),
             hr(),
             h4('Compare total displacement vectors'),
             plotOutput('velo_tracks',
                        width = '100%',
                        height = '600px'))

  }

# Tab 7: eliminate non-motile cells ------

  non_motile <- function() {

    tabPanel('Motile cells (optional)',
             h3('Excluding passively motile cells based on Gaussian modeling'),
             br(),
             p("Non-motile objects in your sample may represent dead cells.
               In turn, non-adherent floating cells may underlie random,
               Brownian-like motion. You may consider eliminating such objects
               from your analysis. By principle, non-motile or passively moving
               cells may be well modeled by fitting a single Gaussian distribution
               to their position coordinates. Yet, this simple model fails for
               actively moving cells. See: ",
               a('celltraceR manual',
                 href = 'https://cran.rstudio.com/web/packages/celltrackR/vignettes/QC.html'),
               " for details. The difference in the active and passive motility model fits
               is described by 'delta BIC' parameter. Low delta BIC values indicate
               Brownian-like motility, high delta BIC values suggest active movement and
               can be used to identify passively moving cells in your sample and eliminate them.
               The 'sigma' parameter estimates the passive motility radius around a central point:
               approximate cell diameter is usually a good starting value."),
             p("Important: make sure, you need to eliminate passively cells from
               your analysis. By, default, this pre-processing step is omitted."),
             hr(),
             h4('Input data'),
             p('Former processing steps:'),
             p(tags$ol(tags$li('raw track import'),
                       tags$li('cell recognition errors correction'),
                       tags$li('short track elimination'),
                       tags$li('gap repair'),
                       tags$li('multiplet elimination'),
                       tags$li('drift correction'))),
             hr(),
             h4('Cutoffs for passively motile cell elimination'),
             fluidRow(column(width = 4,
                             radioButtons(inputId = 'do_motile',
                                          label = 'Perform elimination?',
                                          choices = list('no' = 'no',
                                                         'yes' = 'yes'),
                                          selected = 'no',
                                          inline = TRUE)),
                      column(width = 4,
                             numericInput(inputId = 'delta_bic',
                                          label = 'delta BIC cutoff',
                                          value = 6)),
                      column(width = 4,
                             numericInput(inputId = 'sigma',
                                          label = 'sigma',
                                          value = 10))),
             hr(),
             h4('Compare tracks'),
             plotOutput('motile_tracks',
                        width = '100%',
                        height = '600px'))

  }

# Tab 8: download the data -----

  downloads <- function() {

    tabPanel('Fetch data',
             h3('Download raw and processed data'),
             br(),
             p("This tool saves raw or processed cell track data sets as
               tab-delimited text files which may be seamlessly fed into
               analysis with celltrax in R or with the Shiny
               celltrax analysis tools application."),
             hr(),
             h4('Processed data'),
             p('Processing steps:'),
             p(tags$ol(tags$li('raw track import'),
                       tags$li('cell recognition errors correction'),
                       tags$li('short track elimination'),
                       tags$li('gap repair'),
                       tags$li('multiplet elimination'),
                       tags$li('drift correction'),
                       tags$li('motile cell selection'))),
             hr(),
             h4('Download track data and analysis report'),
             fluidRow(column(width = 4,
                             downloadButton('download_process',
                                            label = 'processed tracks')),
                      column(width = 4,
                             downloadButton('download_raw',
                                            label = 'raw tracks')),
                      column(width = 4,
                             downloadButton('download_report',
                                            label = 'report table'))),
             hr(),
             h4('Compare tracks or vectors'),
             fluidRow(column(width = 4,
                             radioButtons(inputId = 'plot_type',
                                          label = 'plot type',
                                          choices = list('tracks' = 'tracks',
                                                         'vectors' = 'vectors'),
                                          inline = TRUE,
                                          selected = 'tracks')),
                      column(width = 4,
                             radioButtons(inputId = 'norm',
                                          label = 'normalize tracks',
                                          choices = list('no' = 'no',
                                                         'yes' = 'yes'),
                                          inline = TRUE,
                                          selected = 'no')),
                      column(width = 4,
                             radioButtons(inputId = 'monochrome',
                                          label = 'monochrome',
                                          choices = list('no' = 'no',
                                                         'yes' = 'yes'),
                                          inline = TRUE,
                                          selected = 'no'))),
             plotOutput('final_tracks',
                        width = '100%',
                        height = '600px'),
             hr(),
             h4('Download plots'),
             fluidRow(column(width = 6,
                             downloadButton('download_plot_process',
                                            label = 'processed')),
                      column(width = 6,
                             downloadButton('download_plot_raw',
                                            label = 'raw'))))

  }
