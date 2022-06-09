# This function provides the interface and server functions for an web app
# for import and pre-processing of microscopy cell tracking data.

# Tools ------

  library(plyr)
  library(tidyverse)
  library(shiny)
  library(shinyWidgets)
  library(celltrax)
  library(cowplot)
  library(waiter)
  library(writexl)

  source('./tools/styles.R')
  source('./tools/main_panels.R')
  source('./tools/tabsets.R')

  options(shiny.usecairo = FALSE)

# User interface -----

  ui <- fluidPage(

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

    ## refresh option

    observeEvent(input$refresh,{

      session$reload()

    })

    ## Table with input tracks

    raw_data <- eventReactive(input$launcher, {

      if(!is.null(input$single_entry)) {

        file <- input$single_entry

        output <- try(read_trax(file$datapath), silent = TRUE)

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

      if(length(output) > 1000) {

        output <- structure('Input error: data limit reached.
                            The app can process up to 1000 tracks.',
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

    ## correcting for the cell recognition errors
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

    ## filtering out short tracks
    ## visualizing the results

    step_objects <- reactive({

      filter_steps(x = splitted_objects()[[1]],
                   min_steps = input$step_cutoff,
                   max_steps = NULL,
                   return_both = TRUE)

    })

    output$step_tracks <- renderPlot({

      tr_plots <- list(x = step_objects(),
                       plot_title = c('Kept in the analysis',
                                      'Excluded')) %>%
        pmap(plot,
             type = 'tracks',
             coverage = input$coverage/100,
             plot_subtitle = paste('Step cutoff:',
                                   input$step_cutoff),
             cust_theme = theme_shiny())

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

    output$final_tracks <- renderPlot({

      plot_grid(plotlist = map(final_plots(),
                               ~.x + theme_shiny()),
                ncol = 2,
                align = 'hv')

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
