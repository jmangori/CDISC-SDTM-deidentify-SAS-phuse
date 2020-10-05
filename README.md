# About The Project
This is the source code and a copy of the paper and presentation from the presentation on SDTM data de-identification I did at the Phuse conference in Barcelona 2016.

Most of the documentation and explanations you will find in the PowerPoint and PDF documents in the [Documents](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/Documents) folder.

The project uses the Phuse document [PHUSE_STDM_redaction.xls](http://www.phuse.eu/Data_Transparency_download.aspx) to do de-identification of SDTM datasets according to the rules defined in the spreadsheet. These rules are considered to be identical to EMA policy 0070 on de-identification and redaction of clinical trial reports. The implementation is straight forward, as the rules are quite descriptive.

De-identification of SDTM can lead to de-identification and redaction of an entire clinical trial. If you like I build ADaM datasets entirely from SDTM, and furthermore build your Tables, Figures, and Listings (TFL) from SDTM and ADaM, you can de-identify ADaM and the TFL's as well, simply by re-executing your ADaM and TFL programs on de-identified SDTM datasets. On top of this, you may have automatically generated patient profiles and patient narratives from SDTM and AdaM as well. If you re-execute those programs on de-identified data, you have effectually redacted a large part of your clinical trial text. What remains is the prose parts of the clinical trial report referring to actual data points. They too may even be redacted if they are generated by some sort of program following the same principle as a simple mail-merge.

## Built with
This project is built using SAS v9.4 and SDTM versions 3.1.2, 3.2, and 3.3. As only a limited number of general SDTM variables are in scope, it is expected to work on newer version of SDTM without modification.

# Getting Started
1. Obtain the spreadsheet [PHUSE_STDM_redaction.xls](http://www.phuse.eu/Data_Transparency_download.aspx) from the [Phuse](http://www.phuse.eu/Data_Transparency_download.aspx) website. You need to register to get the document. You need this document to build a local database of datasets and variables to be de-identified.
2. Place the files in the [Programs](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/Programs) folder in your own **Programs** folder.
3. Place the files in the [Macro](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/Macro) folder in your own **Macro** folder. Make sure this folder is in the macro search path.
4. Open the program `di_DeIdentify.sas` and edit the paths for the `libname` statements near the top.
  * SDTM is the libref for your original SDTM datasets as ordinary SAS datasets `(.sas7bdat)`.
  * SDTMDEID is the libref to the new SDTM datasets after de-identification as ordinary SAS datasets `(.sas7bdat)`.
5. Open the program `di_ExternalData.sas` and edit the path and possibly the file name in the `PROC IMPORT` statement pointing at the [PHUSE_STDM_redaction.xls](http://www.phuse.eu/Data_Transparency_download.aspx) spread sheet.

# Usage

# License
Distributed under the MIT License. See [LICENSE](https://github.com/jmangori/CDISC-ODM-and-Define-XML-tools/blob/master/LICENSE) for more information.

# Contact
Jørgen Mangor Iversen [jmi@try2.info](mailto:jmi@try2.info)

[My web page in danish](http://www.try2.info) unrelated to this project.

[My LinkedIn profile](https://www.linkedin.com/in/jørgen-iversen-ab5908b/)
