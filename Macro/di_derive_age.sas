/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_derive_age.sas                                                 */
/* Description:  Derive age masking elderly subjects                               */
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

%macro di_derive_age(lib=SDTM, mem=, var=);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;
  %if &mem= %then %return;
  %if &var= %then %return;
  %if %sysfunc(exist(&mem)) = 0 %then %return;

  %let dsid   = %sysfunc(open(&mem, i));
  %let varnum = %sysfunc(varnum(&dsid, &var));
  %let ageu   = %sysfunc(varnum(&dsid, AGEU)); /* For later processing */
  %let rc     = %sysfunc(close(&dsid));
  %if &varnum = 0 %then %return;

  proc sql;
    insert into _messages
       set data     = upcase("&mem"),
           variable = upcase("&var"),
           category = 3,
           message  = "<div align='center'>Deriving variable %upcase(&var.) in dataset %upcase(&mem.)</div>" ||
                      "<p><img src='age1.png'><img src='age2.png'>";
  quit;

  %let redacted = 0;
  %if &ageu = 0 %then %do;
    %put AGEU not found, assuming years;
    data &lib..&mem;
      set &lib..&mem;
      attrib AGECATDI length = $ 4 label='Age Category';
      retain agecatdi '<=89';
      if age > 89 then do;
        age      = .;
        agecatdi = '>89';
        call symput('redacted', '1');
        end;
    run;
  %end; %else %do;
    data &lib..&mem;
      set &lib..&mem;
      attrib AGECATDI length = $ 4 label='Age Category';
      retain agecatdi '<=89';
      select (upcase(ageu));
        when ('DAYS')   do; if age >  32485 then link redacted; end;
        when ('HOURS')  do; if age > 779640 then link redacted; end;
        when ('MONTHS') do; if age >   1068 then link redacted; end;
        when ('WEEKS')  do; if age >   4641 then link redacted; end;
        when ('YEARS')  do; if age >     89 then link redacted; end;
        otherwise;
      end;
      return;
    redacted:
      age      = .;
      agecatdi = '>89';
      call symput('redacted', '1');
      return;
    run;
  %end;

  %if &redacted = 0 %then %do;
    proc sql;
      alter table &lib..&mem drop agecatdi;
    quit;
  %end;

  /* Histograms of age distributions */
  goptions device=png hsize=320pt vsize=320pt gsfname=odsout;

  proc gchart data=&lib..&mem;
    title 'Distribution of age summarized';
    vbar age / name="age1";
    run;
  quit;

  proc sql noprint;
    select distinct min(age), max(age)
      into :min, :max
      from &lib..&mem;
  quit;

  proc gchart data=&lib..&mem;
    title 'Distribution of age in detail';
    vbar age / midpoints=(&min to &max by 1) name="age2";
  run;
  quit;
%mend;

/*
data test;
  ageu = 'Years';
  age = 18;
  output;
  age=90;
  output;
run;
%di_derive_age(lib=work, mem=test, var=age);
*/
