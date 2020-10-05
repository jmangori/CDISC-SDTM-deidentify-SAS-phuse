/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_recode_subject.sas                                             */
/* Description:  Recode subject identifiers and maybe re-sort                      */
/***********************************************************************************/
/*  Copyright (c) 2020 Jørgen Mangor Iversen                                       */
/*                                                                                 */
/*  Permission is hereby granted, free of charge, to any person obtaining a copy   */
/*  of this software and associated documentation files (the "Software"), to deal  */
/*  in the Software without restriction, including without limitation the rights   */
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      */
/*  copies of the Software, and to permit persons to whom the Software is          */
/*  furnished to do so, subject to the following conditions:                       */
/*                                                                                 */
/*  The above copyright notice and this permission notice shall be included in all */
/*  copies or substantial portions of the Software.                                */
/*                                                                                 */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     */
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       */
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    */
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         */
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  */
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  */
/*  SOFTWARE.                                                                      */
/***********************************************************************************/

%macro di_recode_subject(lib=SDTM, mem=, var=);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;
  %if &mem= %then %return;
  %if &var= %then %return;
  %if %sysfunc(exist(&lib..&mem)) = 0 %then %return;

  %let dsid   = %sysfunc(open(&lib..&mem, i));
  %let varnum = %sysfunc(varnum(&dsid, &var));
  %let rc     = %sysfunc(close(&dsid));
  %if &varnum = 0 %then %return;

  proc sql;
    insert into _messages
       set data     = upcase("&mem"),
           variable = upcase("&var"),
           category = 8,
           message  = "Recoding subject ID variable %upcase(&var.) in dataset %upcase(&mem.)";
  quit;

  %if %upcase(&var) = USUBJID %then %do;
    %let sortedby = USUBJID;
    proc sql noprint;
      select name
        into :sortedby separated by ' '
        from dictionary.columns
       where upcase(libname) = "&lib."
         and upcase(memname) = "&mem."
         and sortedby > 0
       order by sortedby;

      select distinct compress('$usubjid' || put(max(length(&var)), 5.) || '.')
        into :format
        from &lib..&mem;

      update &lib..&mem
         set &var = put(&var, &format);

      insert into _messages
         set data     = upcase("&mem"),
             variable = upcase("&var"),
             category = 9,
             message  = "Dataset %upcase(&mem.) re-sorted by %upcase(&sortedby.)";

    quit;

    proc sort data=&lib..&mem;
      by &sortedby;
    run;
  %end; %else %di_recode(lib=&lib, mem=&mem, var=&var);
%mend;

/*
data test;
  subjid  = 'abcde';
  usubjid = 'study1-subj1-site1';
run;

%di_recode_subject(lib=work, mem=test, var=subjid);
%di_recode_subject(lib=work, mem=test, var=usubjid);
*/
