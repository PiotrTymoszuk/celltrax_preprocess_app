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
               of user-provided cell tracking data in text form with most commonly
               used settings.
               The upper size limit of the raw data is 1000 tracks or 40000 steps.
               For processing multiple samples, rich or untypical track sets
               (i.e. motile macroscopic objects), please resort to the seminal R packages."),
             br(),
             p('When ready with the pre-processing, the output text file with
               pre-processed tracks may be directly uploaded to our ',
               a(href = 'https://im2-ibk.shinyapps.io/celltrax_analysis/', 'analysis Shiny app.')),
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
             p("The R code of the application is open and available ",
               a(href = 'https://github.com/PiotrTymoszuk/celltrax_preprocess_app', 'here.')),
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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok', lib = 'glyphicon')))),
             hr(),
             h4('Displacement cutoff'),
             numericInput('d_cutoff',
                          label = 'Displacement cutoff',
                          value = 20,
                          min = 0),
             bsTooltip(id = 'd_cutoff',
                       title = 'tracks are split at each step with displacement > cutoff'),
             hr(),
             h4('Compare tracks'),
             plotOutput('split_tracks',
                        width = '100%',
                        height = '600px'),
             bsTooltip(id = 'split_tracks',
                       title = 'the procedure should eliminate improbably long displacements in your sample'))


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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('cell recognition errors correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')))),
             hr(),
             h4('Minimal step length of tracks kept in the analysis'),
             numericInput('step_cutoff',
                          label = 'Minimal step number',
                          value = 4,
                          min = 2),
             bsTooltip(id = 'step_cutoff',
                       title = 'tracks < cutoff steps are eliminated'),
             hr(),
             h4('Compare tracks'),
             plotOutput('step_tracks',
                        width = '100%',
                        height = '600px'),
             bsTooltip(id = 'step_tracks',
                       title = 'comparison of tracks kept and eliminated'))

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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('cell recognition errors correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('short track elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')))),
             hr(),
             h4('Gap repair method'),
             selectInput(inputId = 'repair_method',
                         label = 'Repair method',
                         choices = list('drop' = 'drop',
                                        'split' = 'split',
                                        'interpolate' = 'interpolate'),
                         selected = 'split'),
             bsTooltip(id = 'repair_method',
                       title = 'way to handle time gaps in the track, used only, if gaps detected in the sample'),
             hr(),
             h4('Compare tracks'),
             plotOutput('gap_tracks',
                        width = '100%',
                        height = '600px'),
             bsTooltip(id = 'gap_tracks',
                       title = 'tracks before and after gap repair'))

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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('cell recognition errors correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('short track elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('gap repair',
                               icon(name = 'ok',
                                    lib = 'glyphicon')))),
             hr(),
             h4('Multiplet elimination cutoffs'),
             fluidRow(column(6,
                             numericInput(inputId = 'dist_cutoff',
                                          label = 'Minimal cell - cell distance',
                                          value = 10,
                                          min = 0),
                             bsTooltip(id = 'dist_cutoff',
                                       title = 'minimal distance to identify a cell pair as a multiplet, approximate cell diameter')),
                      column(6,
                             numericInput(inputId = 'angle_cutoff',
                                          label = 'Minimal angle',
                                          value = 10,
                                          min = 0,
                                          max = 90),
                             bsTooltip(id = 'angle_cutoff',
                                       title = 'minimal angle between cell displacement vectors'))),
             hr(),
             h4('Compare tracks'),
             plotOutput('multi_tracks',
                        width = '100%',
                        height = '600px'),
             bsTooltip(id = 'multi_tracks',
                       title = 'tracks of single cells and candidate multiplets'))

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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('cell recognition errors correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('short track elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('gap repair',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('multiplet elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')))),
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
                                          value = 0),
                             bsTooltip(id = 'x_velo',
                                       title = 'mean X drift velocity to be subtracted for all tracks')),
                      column(width = 3,
                             numericInput(inputId = 'y_velo',
                                          label = 'Y velocity',
                                          value = 0),
                             bsTooltip(id = 'y_velo',
                                       title = 'mean Y drift velocity to be subtracted for all tracks')),
                      column(width = 3,
                             numericInput(inputId = 'z_velo',
                                          label = 'Z velocity',
                                          value = 0),
                             bsTooltip(id = 'z_velo',
                                       title = 'mean Z drift velocity to be subtracted for all tracks'))),
             hr(),
             h4('Compare total displacement vectors'),
             plotOutput('velo_tracks',
                        width = '100%',
                        height = '600px'),
             bsTooltip(id = 'velo_tracks',
                       title = 'total displacement vectors before and after drift adjustment'))

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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('cell recognition errors correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('short track elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('gap repair',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('multiplet elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('drift correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')))),
             hr(),
             h4('Cutoffs for passively motile cell elimination'),
             fluidRow(column(width = 4,
                             radioButtons(inputId = 'do_motile',
                                          label = 'Perform elimination?',
                                          choices = list('no' = 'no',
                                                         'yes' = 'yes'),
                                          selected = 'no',
                                          inline = TRUE)),
                      bsTooltip(id = 'do_motile',
                                title = 'should passively motile cells be removed from the sample?'),
                      column(width = 4,
                             numericInput(inputId = 'delta_bic',
                                          label = 'delta BIC cutoff',
                                          value = 6)),
                      bsTooltip(id = 'delta_bic',
                                title = 'cells with delta BIC y cutoff are eliminated'),
                      column(width = 4,
                             numericInput(inputId = 'sigma',
                                          label = 'sigma',
                                          value = 10),
                             bsTooltip(id = 'sigma',
                                       title = 'estimate of passive movement radius, approximate cell diameter'))),
             hr(),
             h4('Compare tracks'),
             plotOutput('motile_tracks',
                        width = '100%',
                        height = '600px'),
             bsTooltip(id = 'motile_tracks',
                       title = 'tracks of acively and passively motile cells'))

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
             p(tags$ol(tags$li('raw track import',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('cell recognition errors correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('short track elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('gap repair',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('multiplet elimination',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('drift correction',
                               icon(name = 'ok',
                                    lib = 'glyphicon')),
                       tags$li('motile cell selection',
                               icon(name = 'ok',
                                    lib = 'glyphicon')))),
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
             fluidRow(column(width = 3,
                             align = 'left',
                             h4('Compare tracks or vectors')),
                      column(width = 9,
                             align = 'right',
                             dropdownButton( width = '100%',
                                             circle = FALSE,
                                             status = 'secondary',
                                             size = 'sm',
                                             tooltip = tooltipOptions(title = 'plot settings',
                                                                      placement = 'left'),
                                             icon = icon(name = 'menu-hamburger',
                                                         lib = 'glyphicon'),
                                             fluidRow(column(width = 4,
                                                             radioButtons(inputId = 'plot_type',
                                                                          label = 'plot type',
                                                                          choices = list('tracks' = 'tracks',
                                                                                         'vectors' = 'vectors'),
                                                                          inline = TRUE,
                                                                          selected = 'tracks'),
                                                             bsTooltip(id = 'plot_type',
                                                                       title = 'tracks of total displacement vectors?')),
                                                      column(width = 4,
                                                             radioButtons(inputId = 'norm',
                                                                          label = 'normalize tracks',
                                                                          choices = list('no' = 'no',
                                                                                         'yes' = 'yes'),
                                                                          inline = TRUE,
                                                                          selected = 'no'),
                                                             bsTooltip(id = 'norm',
                                                                       title = 'set the track or vector start to 0,0 ?')),
                                                      column(width = 4,
                                                             radioButtons(inputId = 'monochrome',
                                                                          label = 'monochrome',
                                                                          choices = list('no' = 'no',
                                                                                         'yes' = 'yes'),
                                                                          inline = TRUE,
                                                                          selected = 'no'),
                                                             bsTooltip(id = 'monochrome',
                                                                       title = 'should every track or vector be displayed with a separate color?')))))),
             br(),
             fluidRow(column(width = 5,
                             plotOutput('process_tracks',
                                        width = '100%',
                                        height = '500px'),
                             bsTooltip(id = 'process_tracks',
                                       title = 'tracks or vectors after pre-processing')),
                      column(width = 1,
                             align = 'left',
                             downloadBttn(outputId = 'download_plot_process',
                                          label = 'download plot',
                                          style = 'material-circle',
                                          size = 'xs',
                                          color = 'default',
                                          block = TRUE),
                             bsTooltip(id = 'download_plot_process',
                                       title = 'download the plot with pre-processed tracks')),
                      column(width = 5,
                             plotOutput('raw_tracks',
                                        width = '100%',
                                        height = '500px'),
                             bsTooltip(id = 'process_tracks',
                                       title = 'tracks or vectors after pre-processing')),
                      column(width = 1,
                             align = 'left',
                             downloadBttn(outputId = 'download_plot_raw',
                                          label = 'download plot',
                                          style = 'material-circle',
                                          size = 'xs',
                                          color = 'default',
                                          block = TRUE),
                             bsTooltip(id = 'download_plot_raw',
                                       title = 'download the plot with raw tracks'))))

  }

# END -----
