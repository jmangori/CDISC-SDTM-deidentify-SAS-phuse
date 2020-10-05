/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_continent.sas                                                  */
/* Description:  Elevate country codes to continent level                          */
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

%macro di_continent(lib=SDTM, mem=, var=);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;
  %if &mem= %then %return;
  %if &var= %then %return;
  %if %sysfunc(exist(&mem)) = 0 %then %return;

  %let dsid   = %sysfunc(open(&mem, i));
  %let varnum = %sysfunc(varnum(&dsid, &var));
  %let rc     = %sysfunc(close(&dsid));
  %if &varnum = 0 %then %return;

  proc sql;
    insert into _messages
       set data     = upcase("&mem"),
           variable = upcase("&var"),
           category = 4,
           message  = "Elevating variable %upcase(&var.) in dataset %upcase(&mem.) to continent level";
  quit;

  data _fmt;
    set data.continent end = tail;
    retain continent_length 0 fmtname '$continent';
    length start $ 3;
    label   = continent;
    start   = isoalpha2;
    output;
    start   = isoalpha3;
    output;

    continent_length = max(continent_length, length(continent));
    if tail then call symput('continent_length', put(continent_length, 2.));
  run;

  proc format cntlin=_fmt;
  run;

  data &lib..&mem;
    set &lib..&mem;
    attrib REGIONDI length = $ &continent_length. label='Continent';
    regiondi = put(&var., $continent.);
  run;

proc datasets lib=work nolist;
  delete _fmt;
  run;
quit;
%mend;

/*
data test;
  country2 = 'DK';
  country3 = 'DNK';
  output;
run;

%di_continent(lib=work, mem=test, var=country2);
%di_continent(lib=work, mem=test, var=country3);
*/
