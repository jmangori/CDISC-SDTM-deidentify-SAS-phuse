/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_remove_var.sas                                                 */
/* Description:  Remove a variable from a dataset                                  */
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

%macro di_remove_var(lib=SDTM, mem=, var=);
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
           category = 5,
           message  = "Removing variable %upcase(&var.) from dataset %upcase(&mem.)";
  quit;

  proc sql;
    alter table &lib..&mem drop &var;
  quit;
%mend;

/*
data test;
  test = 1;
run;

%di_remove_var(lib=work, mem=test, var=test);
%di_remove_var(lib=Work, mem=test, var=test);
*/
