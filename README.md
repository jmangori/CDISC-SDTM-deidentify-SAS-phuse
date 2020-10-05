# About The Project
This is the source code and a copy of the paper and presentation from the presentation I did at the Phuse conference in Barcelona 2016.

Most of the documentation and explanations you will find in the PowerPoint and PDF documents in the [Documents](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/Documents) folder.

The project uses the Phuse document [PHUSE_STDM_redaction.xls](http://www.phuse.eu/Data_Transparency_download.aspx) to do deidentification of SDTM datasets according to the rules defined in the spreadsheet. These rules are consideret to be identical to EMA policy 0070 on deidentification and redaction of clinical trial reports. The impelmentation is straight forward, as the rules are quite descriptive. To quote from one of the presentations, the source codestatistics are these:

* 16 programs and macros including metadata build
* < 900 lines of code plus comments and licence
* 10 Days of work

## Built with
This project is built using SAS v9.4 and SDTM versions 3.1.2, 3.2, and 3.3. As only a limited number of general SDTM variables are in scope, it is expected to work on newer version of SDTM as well.

# Getting Started
1. Obtain the spreadsheet [PHUSE_STDM_redaction.xls](http://www.phuse.eu/Data_Transparency_download.aspx) from the [Phuse](http://www.phuse.eu/Data_Transparency_download.aspx) website. You don't need to be a member of Phuse, but you do need to register to get the document. You need this document to build a local database of datasets and variables to be de-identified.
2. Place the files in the [Programs](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/Programs) folder in your own **Program** folder.
3. Place the files in the [Macro](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/Macro) folder in your own **Macro** folder. Make sure this folder is in the macro search path.
4. Open the program `di_DeIdentify.sas` and edit the paths for the `libname` statements near the top.
  * SDTM is the libref for your original SDTM datasets as ordinary SAS datasets (`.sas7bdat`).
  * SDTMDEID is the libref to the new SDTM datasets after de-identification as ordinary SAS datasets (`.sas7bdat`).
5. Open the program `di_ExternalData.sas` and edit the path and possibly the file name in the `PROC IMPORT` statement pointing at the [PHUSE_STDM_redaction.xls](http://www.phuse.eu/Data_Transparency_download.aspx) spread sheet.

## Usage

# License
Distributed under the MIT License. See [LICENSE](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/LICENSE) for more information.

# Contact
Jørgen Mangor Iversen [jmi@try2.info](mailto:jmi@try2.info)

[My web page in danish](http://www.try2.info) unrelated to this project.

[My LinkedIn profile](https://www.linkedin.com/in/jørgen-iversen-ab5908b/)
