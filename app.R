# This function provides the interface and server functions for an web app
# for import and pre-processing of microscopy cell tracking data.

# Tools ------

  library(plyr)
  library(tidyverse)
  library(shiny)
  library(shinyWidgets)
  library(shinyjs)
  library(celltrax)
  library(cowplot)
  library(waiter)
  library(writexl)
  library(stringi)
  library(shinyBS)

  source('./tools/styles.R')
  source('./tools/main_panels.R')
  source('./tools/tabsets.R')
  source('./tools/utils.R')

  options(shiny.usecairo = FALSE)
  options(shiny.maxRequestSize = 10*1024^2)

# User interface -----

  ui <- fluidPage(

    useShinyjs(),

    ## progress bar

    autoWaiter(html = spin_rotating_plane()),

    ## some styling

    styles(),

    ## Title panel with the logos and names

    title_panel(),

    ## Side panel with user's entries.
    ## Contains uploads handlers and analysis launch button

    sidebarLayout(

      side_panel(),

      ## Main panel to hold the dynamic output

      mainPanel(
        tabsetPanel(id = 'tab_status',
                    general_info(),
                    handle_ai_errors(),
                    handle_short_tracks(),
                    handle_gaps(),
                    handle_multiplets(),
                    adjust_drift(),
                    non_motile(),
                    downloads()
        )
      )
    )
  )

# Define server logic ----

  server <- function(input, output, session) {

    ## refresh option -------

    observeEvent(input$refresh,{

      session$reload()

    })

    ## upload-specific UI ------

    spy_results <- eventReactive(input$single_entry, {

      file <- input$single_entry

      spy_file(file$datapath)


    })

    observeEvent(input$single_entry, {

      enable('launcher')

    })

    observeEvent(input$x_entry, {

      enable('launcher')

    })

    output$upload_ui <- renderUI({

      if(input$upload_type == 'single') {

        fileInput(inputId = 'single_entry',
                  label = 'Choose the file',
                  multiple = FALSE,
                  accept = c('.tsv', '.csv', '.txt'))

      } else {

        tagList(fileInput(inputId = 'x_entry',
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
                          accept = c('.tsv', '.csv', '.txt')))

      }

    })

    output$selectors <- renderUI({

      if(input$upload_type == 'compound') return(NULL)

      if(is.null(input$single_entry)) return(NULL)

      tagList(selectInput('id_name',
                          label = 'track ID column',
                          choices = spy_results()$col_names,
                          selected = spy_results()$id_col),
              selectInput('t_name',
                          label = 'time column',
                          choices = spy_results()$col_names,
                          selected = spy_results()$t_col),
              selectInput('x_name',
                          label = 'X coordinate column',
                          choices = spy_results()$col_names,
                          selected = spy_results()$x_col),
              selectInput('y_name',
                          label = 'Y coordinate column',
                          choices = spy_results()$col_names,
                          selected = spy_results()$y_col),
              selectInput('z_name',
                          label = 'Z coordinate column',
                          choices = c('', spy_results()$col_names),
                          selected = NULL),
              selectInput('sample_name',
                          label = 'sample ID column',
                          choices = c('', spy_results()$col_names),
                          selected = NULL))

    })

    output$sample_ui <- renderUI({

      if(is.null(input$sample_name)) return(NULL)

      if(input$sample_name == '') return(NULL)

      if(is.null(input$single_entry)) return(NULL)

      file <- input$single_entry

      txt_entry <- read_delim(file = file$datapath,
                              delim = '\t',
                              col_names = TRUE)

      sample_choices <- unique(txt_entry[[input$sample_name]])

      selectInput(inputId = 'sample_select',
                  label = 'sample',
                  choices = as.character(sample_choices),
                  selected = NULL)

    })

    ## Table with input tracks -------

    raw_data <- eventReactive(input$launcher, {

      if(!is.null(input$single_entry)) {

        file <- input$single_entry

        z_entry <- if(input$z_name == '') NULL else input$z_name

        sample_entry <- if(input$sample_name == '') NULL else input$sample_name

        output <- try(read_trax_text(file = file$datapath,
                                     id_name = input$id_name,
                                     t_name = input$t_name,
                                     x_name = input$x_name,
                                     y_name = input$y_name,
                                     z_name = z_entry,
                                     sample_name = sample_entry),
                      silent = TRUE)

        if(!any(class(output) == 'try-error') & !input$sample_name == '') {

          output <- output[[input$sample_select]]

        }

      } else if(!is.null(input$x_entry) & !is.null(input$y_entry)) {

        x_file <- input$x_entry
        y_file <- input$y_entry
        z_file <- input$z_entry

        output <- try(read_trax_parts(x_file = x_file$datapath,
                                      y_file = y_file$datapath,
                                      z_file = z_file$datapath),
                      silent = TRUE)

      }

      if(any(class(output) == 'try-error')) {

        return('Input error: incorrect path? wrong file format?')

      }

      if(length(output) > 1500) {

        output <- structure('Input error: data limit reached.
                            The app can process up to 1500 tracks.',
                            class = 'try-error')

      } else {

        total_size <- map_dbl(output, nrow) %>%
          sum

        if(total_size > 40000) {

          output <- structure('Input error: data limit reached.
                              The app can process up to 40000 steps.',
                              class = 'try-error')

        }

      }

      hide('upload_ui')
      hide('selectors')
      hide('sample_ui')

      output

    })

    inp_qc <- observe({

      if(!is_trax(raw_data())) {

        showNotification(raw_data(),
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

      updateProgressBar(id = 'pb',
                        value = 1,
                        total = 7,
                        title = 'Raw data imported')

    })

    ## correcting for the cell recognition errors -------
    ## visualizing the results

    splitted_objects <- reactive({

      split_tracks(x = raw_data(),
                   disp_cutoff = input$d_cutoff,
                   return_both = TRUE)

    })

    output$split_tracks <- renderPlot({

      tr_plots <- list(x = splitted_objects(),
                       plot_title = c('After recognition error correction',
                                      'Before recognition error correction')) %>%
        pmap(plot,
             type = 'tracks',
             coverage = input$coverage/100,
             plot_subtitle = paste('Displacement cutoff:',
                                   input$d_cutoff),
             cust_theme = theme_shiny())

      plot_grid(plotlist = tr_plots,
                ncol = 2,
                align = 'hv')

    })

    split_qc <- observe({

      if(is_trax(splitted_objects()[[1]])){

        updateProgressBar(id = 'pb',
                          value = 2,
                          total = 7,
                          title = 'Correction of cell recognition errors')

      } else {

        showNotification('Track splitting error',
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

    })

    ## filtering out short tracks -------
    ## visualizing the results

    step_objects <- reactive({

      filter_steps(x = splitted_objects()[[1]],
                   min_steps = input$step_cutoff,
                   max_steps = NULL,
                   return_both = TRUE)

    })

    output$step_tracks <- renderPlot({

      if(!is.null(step_objects()[[2]])) {

        tr_plots <- list(x = step_objects(),
                         plot_title = c('Kept in the analysis',
                                        'Excluded')) %>%
          pmap(plot,
               type = 'tracks',
               coverage = input$coverage/100,
               plot_subtitle = paste('Step cutoff:',
                                     input$step_cutoff),
               cust_theme = theme_shiny())


      } else {

        tr_plots <- list(x = list(step_objects()[[1]],
                                  step_objects()[[1]]),
                         plot_title = c('Kept in the analysis',
                                        'Kept in the analysis')) %>%
          pmap(plot,
               type = 'tracks',
               coverage = input$coverage/100,
               plot_subtitle = 'No tracks filtered out with the specified cutoff',
               cust_theme = theme_shiny())


      }

      plot_grid(plotlist = tr_plots,
                ncol = 2,
                align = 'hv')

    })

    step_qc <- observe({

      if(is_trax(step_objects()[[1]])){

        updateProgressBar(id = 'pb',
                          value = 3,
                          total = 7,
                          title = 'Short track elimination')

      } else {

        showNotification('Step filtering error',
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

    })

    ## detection of gaps
    ## and, optionally, repair

    gap_objects <- reactive({

      dt <- time_intervals(step_objects()[[1]])

      if(nrow(dt) > 1) {

        repair_gaps(step_objects()[[1]],
                    how = input$repair_method,
                    return_both = TRUE)

      } else {

        list(step_objects()[[1]],
             step_objects()[[1]],
             'no_repair')

      }

    })

    output$gap_tracks <- renderPlot({

      if(length(gap_objects()) == 2) {

        plot_subtitle <- paste('Repair method:',
                               input$repair_method)

      } else {

        plot_subtitle <- 'No gaps detected'

      }

      tr_plots <- list(x = gap_objects()[1:2],
                       plot_title = c('After gap repair',
                                      'Before gap repair')) %>%
        pmap(plot,
             type = 'tracks',
             coverage = input$coverage/100,
             plot_subtitle = plot_subtitle,
             cust_theme = theme_shiny())

      plot_grid(plotlist = tr_plots,
                ncol = 2,
                align = 'hv')

    })

    gap_qc <- observe({

      if(is_trax(gap_objects()[[1]])){

        updateProgressBar(id = 'pb',
                          value = 4,
                          total = 7,
                          title = 'Gap repair')

      } else {

        showNotification('Gap repair error',
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

    })

    ## duplicate handling

    multi_objects <- reactive({

      filter_multiplets(x = gap_objects()[[1]],
                        method = 'cells',
                        angle_cutoff = input$angle_cutoff,
                        dist_cutoff = input$dist_cutoff,
                        return_both = TRUE)

    })

    output$multi_tracks <- renderPlot({

      if(is_trax(multi_objects()[[2]])) {

        tr_plots <- list(x = multi_objects(),
                         plot_title = c('Kept in the analysis',
                                        'Excluded')) %>%
          pmap(plot,
               type = 'tracks',
               coverage = input$coverage/100,
               plot_subtitle = paste0('Distance cutoff: ',
                                      input$dist_cutoff,
                                      ', angle cutoff: ',
                                      input$angle_cutoff),
               cust_theme = theme_shiny())


      } else {

        tr_plots <- list(x = list(multi_objects()[[1]],
                                  multi_objects()[[1]]),
                         plot_title = c('After multiplet elimination',
                                        'Before multiplet elimination')) %>%
          pmap(plot,
               type = 'tracks',
               coverage = input$coverage/100,
               plot_subtitle = 'no multiplets detected with the provided cutoffs',
               cust_theme = theme_shiny())

      }

      plot_grid(plotlist = tr_plots,
                ncol = 2,
                align = 'hv')

    })

    multi_qc <- observe({

      if(is_trax(multi_objects()[[1]])){

        updateProgressBar(id = 'pb',
                          value = 5,
                          total = 7,
                          title = 'Multiplet elimination')

      } else {

        showNotification('Multiplet filtering error',
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

    })

    ## drift correction

    output$raw_vector <- renderText({

      mean_vec <- get_mean_speed(multi_objects()[[1]])

      vec_txt <- paste0('X = ', signif(mean_vec[1], 3),
                        ', Y = ', signif(mean_vec[2], 3))

      if(length(mean_vec) > 2) {

        vec_txt <- paste(vec_txt,
                         ', Z = ', signif(mean_vec[3], 3))

      }

      vec_txt

    })

    drift_objects <- reactive({

      if(any(c(input$x_velo,
               input$y_velo,
               input$z_velo) > 0)) {

        correct_drift(x = multi_objects()[[1]],
                      drift_vector = c(input$x_velo,
                                       input$y_velo,
                                       input$z_velo),
                      return_both = TRUE)

      } else {

        list(multi_objects()[[1]],
             multi_objects()[[1]])

      }

    })

    output$adj_vector <- renderText({

      mean_vec <- get_mean_speed(drift_objects()[[1]])

      vec_txt <- paste0('X = ', signif(mean_vec[1], 3),
                        ', Y = ', signif(mean_vec[2], 3))

      if(length(mean_vec) > 2) {

        vec_txt <- paste(vec_txt,
                         ', Z = ', signif(mean_vec[3], 3))

      }

      vec_txt

    })

    output$velo_tracks <- renderPlot({

      tr_plots <- list(x = drift_objects(),
                       plot_title = c('After drift adjustment',
                                      'Before drift adjustment')) %>%
        pmap(plot,
             type = 'vectors',
             show_zero = FALSE,
             coverage = input$coverage/100,
             plot_subtitle = paste0('Adjustment velocity: X = ',
                                    signif(input$x_velo, 3),
                                    ', Y = ',
                                    signif(input$y_velo, 3),
                                    ', Z = ',
                                    signif(input$z_velo, 3)),
             cust_theme = theme_shiny())

      plot_grid(plotlist = tr_plots,
                ncol = 2,
                align = 'hv')

    })

    drift_qc <- observe({

      if(is_trax(drift_objects()[[1]])){

        updateProgressBar(id = 'pb',
                          value = 6,
                          total = 7,
                          title = 'Drift correction')

      } else {

        showNotification('Drift adjustment error',
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

    })

    ## selection of motile cells

    motile_objects <- reactive({

      if(input$do_motile == 'no') {

        list(drift_objects()[[1]],
             drift_objects()[[1]])

      } else {

        filter_motility(x = drift_objects()[[1]],
                        bic_cutoff = input$delta_bic,
                        sigma = input$sigma,
                        return_both = TRUE)

      }

    })

    output$motile_tracks <- renderPlot({

      if(input$do_motile == 'no') {

        plot_subtitle <- 'No motile cell selection performed'

      } else {

        plot_subtitle <- paste0('Delta BIC: ',
                                signif(input$delta_bic, 3),
                                ', sigma: ',
                                signif(input$sigma))

      }

      tr_plots <- list(x = motile_objects(),
                       plot_title = c('Kept in the analysis',
                                      'Excluded')) %>%
        pmap(plot,
             type = 'tracks',
             coverage = input$coverage/100,
             plot_subtitle = plot_subtitle,
             cust_theme = theme_shiny())

      plot_grid(plotlist = tr_plots,
                ncol = 2,
                align = 'hv')

    })

    motile_qc <- observe({

      if(is_trax(motile_objects()[[1]])){

        updateProgressBar(id = 'pb',
                          value = 7,
                          total = 7,
                          title = 'Motile cell selection')

      } else {

        showNotification('Motility filter error',
                         duration = NULL,
                         closeButton = TRUE,
                         type = 'error')

      }

    })

    ## final track comparison

    final_plots <- reactive({

      if(input$monochrome == 'yes') {

        colors <- list('steelblue',
                       'darkolivegreen3')

      } else {

        colors <- list(NULL, NULL)

      }

      tr_plots <- list(x = list(motile_objects()[[1]],
                                raw_data()),
                       plot_title = c('Processed',
                                      'Raw'),
                       color = colors) %>%
        pmap(plot,
             type = input$plot_type,
             normalize = input$norm == 'yes',
             coverage = input$coverage/100,
             show_zero = input$norm == 'yes',
             plot_subtitle = 'celltrax pre-processing tools',
             cust_theme = theme_trax())

    })

    output$process_tracks <- renderPlot({

      final_plots()[[1]] +
        theme_shiny()

    })

    output$raw_tracks <- renderPlot({

      final_plots()[[2]] +
        theme_shiny()

    })

    ## data download as a text table

    output$download_raw <- downloadHandler(

      ## defining the filename

      filename = function() {

        return(paste0('raw_trax_', Sys.Date(), '.tsv'))

      },

      ## calling the saving function

      content = function(con) {

        write_trax(x = raw_data(),
                   file = con)

      }

    )


    output$download_process <- downloadHandler(

      ## defining the filename

      filename = function() {

        return(paste0('processed_trax_', Sys.Date(), '.tsv'))

      },

      ## calling the saving function

      content = function(con) {

        write_trax(x = motile_objects()[[1]],
                   file = con)

      }

    )

    ## table with cutoffs

    report_tbl <- reactive({


      if(length(gap_objects()) == 2) {

        gap_method <- input$repair_method

      } else {

        gap_method <- 'no gaps detected'

      }

      if(any(c(input$x_velo,
               input$y_velo,
               input$z_velo) > 0)) {

        velo_method <- paste0('Velocity adjustment vector: X = ',
                              signif(input$x_velo, 3),
                              ', Y = ',
                              signif(input$y_velo, 3),
                              ', Z = ',
                              signif(input$z_velo, 3))

      } else {

        velo_method <- 'none'

      }

      if(input$do_motile == 'no') {

        motile_method <- 'none'

      } else {

        motile_method <- paste0('BIC cutoff = ',
                                signif(input$delta_bic, 3),
                                ', sigma = ',
                                signif(input$sigma, 3))

      }

      tibble(Activity = c('Tracks processed',
                          'Tracks raw',
                          'Cell recognition error repair',
                          'Short track elimination',
                          'Gap repair',
                          'Multiplet elimination',
                          'Drift adjustment',
                          'Motile cell selection'),
             Details = c(length(motile_objects()[[1]]),
                         length(raw_data()),
                         paste('displacement cutoff:',
                               signif(input$d_cutoff, 3)),
                         paste('step number cutoff:',
                               input$step_cutoff),
                         gap_method,
                         paste0('distance cutoff: ',
                                signif(input$dist_cutoff, 3),
                                ', angle cutoff: ',
                                signif(input$angle_cutoff, 3)),
                         velo_method,
                         motile_method))

    })

    output$download_report <- downloadHandler(

      ## defining the filename

      filename = function() {

        return(paste0('process_report_', Sys.Date(), '.xlsx'))

      },

      ## calling the saving function

      content = function(con) {

        write_xlsx(report_tbl(), path = con)

      }

    )



    ## final plot download

    output$download_plot_raw <- downloadHandler(

      ## defining the filename

      filename = function() {

        return(paste0('plot_raw_trax_', Sys.Date(), '.pdf'))

      },

      ## calling the saving function

      content = function(con) {

        ggsave(filename = con,
               plot = final_plots()[[2]],
               device = cairo_pdf,
               width = 160,
               height = 160,
               units = 'mm')

      }

    )

    output$download_plot_process <- downloadHandler(

      ## defining the filename

      filename = function() {

        return(paste0('plot_processed_trax_', Sys.Date(), '.pdf'))

      },

      ## calling the saving function

      content = function(con) {

        ggsave(filename = con,
               plot = final_plots()[[1]],
               device = cairo_pdf,
               width = 160,
               height = 160,
               units = 'mm')

      }

    )

  }

# Run the app ----

  shinyApp(ui = ui, server = server)
