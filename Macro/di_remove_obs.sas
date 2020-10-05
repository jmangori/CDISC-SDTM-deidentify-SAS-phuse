/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_remove_obs.sas                                                 */
/* Description:  Remove specific rows from a dataset                               */
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

%macro di_remove_obs(lib=SDTM, mem=, var=, cond=1=1);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;
  %if &mem= %then %return;
  %if %sysfunc(exist(&lib..&mem)) = 0 %then %return;

  proc sql;
    insert into _messages
       set data     = upcase("&mem"),
           variable = upcase("&var"),
           category = 6,
           message  = "Removing observations in dataset %upcase(&mem.) where %upcase(&cond)";
  quit;

  proc sql;
    delete from &lib..&mem
     where &cond;
  quit;
%mend;

/*
data test;
  testcd='A';
  result=1;
  output;
  testcd='B';
  result=2;
  output;
run;
%di_remove_obs(lib=work, mem=test, var=dummyvar, cond=testcd='B');
*/
