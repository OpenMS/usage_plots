######################################################
                     README.txt
######################################################

Create report files
-------------------

In order to (re-)create the report files simply execute
$ ./create_reports.h

Attention: There are two things you need to be aware of:

	1) The report is evaluated on the logfile
	   ../logfiles/seqan.logs (../logfiles/openms.logs)
	   Make sure the file exists and contains the data
	   you'd like to analyse. (or see Logfile section below)

	2) The output format is specififed in the corresponding
	   rmarkdown file (e.g. report_seqan.Rmd). See section
	   Ouput format below if you want to change the format.


Figures and Tables
------------------

All figures and tables created for the report file are also
stored in the subdirectory figures_and_tables/ and are
automatically update whenever ./create_report.h is executed.


Logfile
-------

The logfiles used to create the report on are
'../logfiles/seqan.logs' and '../logfiles/openms.logs'
respectively.

Either make sure the file exists and contains your desired 
data, or change the filename. To do this, you need to change the
variable seqan_log_file (openms_log_file) which you find right
at the beginning of the file global_seqan.R (global_openms.R).


Ouput Format
------------

To change the output format to html or pdf, you only need to
change line 6 in the markdown file report_seqan.Rmd (report_openms.Rmd).

The first few lines of an Rmarkdown document are:

1 ---
2 title: "SeqAn Usage Statistics"
3 author: "Svenja Mehringer"
4 date: "24 April 2017"
5 output:
6   html_document
7 ---

Simply change html_document to pdf_document or any other output format
and re-run ./create_reports.h on the console.

Rmarkdown offers several output formats:
 
Documents

    html_notebook - Interactive R Notebooks
    html_document - HTML document w/ Bootstrap CSS
    pdf_document - PDF document (via LaTeX template)
    word_document - Microsoft Word document (docx)
    odt_document - OpenDocument Text document
    rtf_document - Rich Text Format document
    md_document - Markdown document (various flavors)

Presentations (slides)

    ioslides_presentation - HTML presentation with ioslides
    revealjs::revealjs_presentation - HTML presentation with reveal.js
    slidy_presentation - HTML presentation with W3C Slidy
    beamer_presentation - PDF presentation with LaTeX Beamer

More

    flexdashboard::flex_dashboard - Interactive dashboards
    tufte::tufte_handout - PDF handouts in the style of Edward Tufte
    tufte::tufte_html - HTML handouts in the style of Edward Tufte
    tufte::tufte_book - PDF books in the style of Edward Tufte
    html_vignette - R package vignette (HTML)
    github_document - GitHub Flavored Markdown document



